import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/listing_sync.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/listings_api.dart';
import 'package:agrilumina/services/local_state_store.dart';
import 'package:agrilumina/services/location_service.dart';

import 'fake_listings_api.dart';
import 'fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeListingsApi api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeListingsApi();
  });

  Future<AppState> makeState() async {
    final store = LocalStateStore(await SharedPreferences.getInstance());
    return AppState.fromStore(
      store,
      locationService: FakeLocationService(),
      listingsApi: api,
    );
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  bool publish(AppState state, {String phone = '+243970000009'}) =>
      state.publishMyListing(
        crop: 'Maize',
        quantityHint: '5 bags',
        phone: phone,
      );

  group('publish/clear sync (#25)', () {
    test('publish online pushes one upsert with phone and ends synced',
        () async {
      final state = await makeState();

      expect(publish(state), isTrue);
      await settle();

      expect(api.upserts, hasLength(1));
      expect(api.upserts.single.deviceId, state.deviceId);
      expect(api.upserts.single.listing.phone, '+243970000009');
      expect(api.upserts.single.listing.role, UserRole.seller);
      expect(
        state.listingSyncStatusFor(UserRole.seller),
        ListingSyncStatus.synced,
      );
    });

    test('publish offline stays pending, then flushes when online', () async {
      api.offline = true;
      final state = await makeState();

      expect(publish(state), isTrue);
      await settle();

      expect(state.mySellerListing, isNotNull);
      expect(api.upserts, isEmpty);
      expect(
        state.listingSyncStatusFor(UserRole.seller),
        ListingSyncStatus.pending,
      );

      api.offline = false;
      await state.syncPendingListings();

      expect(api.upserts, hasLength(1));
      expect(
        state.listingSyncStatusFor(UserRole.seller),
        ListingSyncStatus.synced,
      );
    });

    test('publish then clear offline collapses to a delete', () async {
      api.offline = true;
      final state = await makeState();
      publish(state);
      await settle();
      state.clearMyListing();
      await settle();

      api.offline = false;
      await state.syncPendingListings();

      expect(api.upserts, isEmpty);
      expect(api.deletes, hasLength(1));
      expect(api.deletes.single.role, UserRole.seller);
      expect(
        state.listingSyncStatusFor(UserRole.seller),
        ListingSyncStatus.synced,
      );
    });

    test('API error marks failed; retry succeeds', () async {
      api.failWith = const ListingsApiException(500);
      final state = await makeState();
      publish(state);
      await settle();

      expect(
        state.listingSyncStatusFor(UserRole.seller),
        ListingSyncStatus.failed,
      );

      api.failWith = null;
      await state.syncPendingListings();

      expect(api.upserts, hasLength(1));
      expect(
        state.listingSyncStatusFor(UserRole.seller),
        ListingSyncStatus.synced,
      );
    });

    test('pending op persists across restart and flushes on demand',
        () async {
      api.offline = true;
      final first = await makeState();
      publish(first);
      await settle();
      await first.waitForPersistence();

      api.offline = false;
      final second = await makeState();
      expect(
        second.listingSyncStatusFor(UserRole.seller),
        ListingSyncStatus.pending,
      );
      await second.syncPendingListings();

      expect(api.upserts, hasLength(1));
      expect(api.upserts.single.listing.crop, 'Maize');
      expect(
        second.listingSyncStatusFor(UserRole.seller),
        ListingSyncStatus.synced,
      );
    });
  });

  group('remote Discover (#26)', () {
    test('successful refresh replaces seeds and caches per role', () async {
      api.rows[UserRole.buyer] = [remoteListing('r1', name: 'Remote Rita')];
      final state = await makeState(); // activeRole seller -> counterpart buyer

      await state.refreshDiscover();

      expect(state.discoverOffline, isFalse);
      expect(state.discoverFeedSource, DiscoverFeedSource.remote);
      final names = state.nearbyCounterparts.map((l) => l.name).toList();
      expect(names, contains('Remote Rita'));
      expect(names, isNot(contains('Jean-Pierre M.'))); // seed gone

      // Cached for offline use by a fresh state.
      final offlineApi = FakeListingsApi()..offline = true;
      api = offlineApi;
      final reloaded = await makeState();
      await reloaded.refreshDiscover();
      expect(reloaded.discoverOffline, isTrue);
      expect(reloaded.discoverFeedSource, DiscoverFeedSource.cache);
      expect(
        reloaded.nearbyCounterparts.map((l) => l.name),
        contains('Remote Rita'),
      );
    });

    test('offline with no cache falls back to seeds', () async {
      api.offline = true;
      final state = await makeState();

      await state.refreshDiscover();

      expect(state.discoverOffline, isTrue);
      expect(state.discoverFeedSource, DiscoverFeedSource.seed);
      expect(
        state.nearbyCounterparts.map((l) => l.name),
        contains('Jean-Pierre M.'),
      );
    });

    test('GPS present sends position and radius; lens flip refetches',
        () async {
      final store = LocalStateStore(await SharedPreferences.getInstance());
      final state = AppState.fromStore(
        store,
        locationService: FakeLocationService(
          result: const LocationFetchResult.success(
            UserLocation(latitude: -2.2, longitude: 28.9),
          ),
        ),
        listingsApi: api,
      );
      await state.refreshDiscover();

      expect(api.lastFetch?.role, UserRole.buyer);
      expect(api.lastFetch?.lat, isNotNull);
      expect(api.lastFetch?.radiusKm, ListingsConfig.radiusKm);

      state.setActiveRole(UserRole.buyer); // counterpart -> seller
      await settle();
      expect(api.lastFetch?.role, UserRole.seller);
    });
  });

  group('contact unlock (#26)', () {
    test('seed unlock spends a credit without network', () async {
      final state = await makeState();

      final result = await state.unlockListingContact('b1');

      expect(result.ok, isTrue);
      expect(state.credits, 4);
      expect(api.contactCount, 0);
    });

    test('remote unlock fetches phone, charges once, persists', () async {
      api.rows[UserRole.buyer] = [remoteListing('r1')];
      api.phones['r1'] = '+243970000002';
      final state = await makeState();
      await state.refreshDiscover();

      final result = await state.unlockListingContact('r1');

      expect(result.ok, isTrue);
      expect(result.phone, '+243970000002');
      expect(state.credits, 4);
      final listing =
          state.listings.firstWhere((l) => l.id == 'r1');
      expect(state.phoneFor(listing), '+243970000002');
      await state.waitForPersistence();

      // Phone survives a reload; re-unlock costs nothing more.
      final store = LocalStateStore(await SharedPreferences.getInstance());
      expect(store.loadUnlockedPhones()['r1'], '+243970000002');
      final again = await state.unlockListingContact('r1');
      expect(again.ok, isTrue);
      expect(state.credits, 4);
    });

    test('failures never spend a credit', () async {
      api.rows[UserRole.buyer] = [remoteListing('r1')];
      final state = await makeState();
      await state.refreshDiscover();

      api.contactError = ListingsOfflineException();
      var result = await state.unlockListingContact('r1');
      expect(result.status, ContactUnlockStatus.offline);
      expect(state.credits, 5);

      api.contactError = ContactRateLimitedException();
      result = await state.unlockListingContact('r1');
      expect(result.status, ContactUnlockStatus.rateLimited);
      expect(state.credits, 5);

      api.contactError = ListingNotFoundException();
      result = await state.unlockListingContact('r1');
      expect(result.status, ContactUnlockStatus.notFound);
      expect(state.credits, 5);
      expect(state.isUnlocked('r1'), isFalse);
    });

    test('no credits blocks remote unlock before any network call', () async {
      api.rows[UserRole.buyer] = [remoteListing('r1')];
      api.phones['r1'] = '+243970000002';
      final state = await makeState();
      await state.refreshDiscover();
      for (var i = 0; i < 5; i++) {
        state.credits = 0;
      }

      final result = await state.unlockListingContact('r1');

      expect(result.status, ContactUnlockStatus.noCredits);
      expect(api.contactCount, 0);
    });
  });
}

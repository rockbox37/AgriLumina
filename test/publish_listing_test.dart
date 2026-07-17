import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/local_state_store.dart';

import 'fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('publishMyListing', () {
    test('creates one listing for the active role', () {
      final state = AppState(locationService: FakeLocationService());
      expect(state.myListing, isNull);

      expect(
        state.publishMyListing(
          crop: 'Beans',
          quantityHint: '10 bags',
          phone: '+243 970 000 001',
        ),
        isTrue,
      );

      final mine = state.myListing;
      expect(mine, isNotNull);
      expect(mine!.id, Listing.mySellerId);
      expect(mine.role, UserRole.seller);
      expect(mine.crop, 'Beans');
      expect(mine.quantityHint, '10 bags');
      expect(mine.phone, '+243 970 000 001');
      expect(state.listings.any((l) => l.id == Listing.mySellerId), isTrue);
    });

    test('update replaces the same role listing', () {
      final state = AppState(locationService: FakeLocationService());
      state.publishMyListing(
        crop: 'Maize',
        quantityHint: 'old',
        phone: '+243 1',
      );
      state.publishMyListing(
        crop: 'Rice',
        quantityHint: 'new qty',
        phone: '+243 2',
      );

      expect(state.mySellerListing?.crop, 'Rice');
      expect(state.mySellerListing?.quantityHint, 'new qty');
      expect(
        state.listings.where((l) => l.id == Listing.mySellerId).length,
        1,
      );
    });

    test('clear removes active-role listing', () {
      final state = AppState(locationService: FakeLocationService());
      state.publishMyListing(
        crop: 'Maize',
        quantityHint: 'qty',
        phone: '+243 1',
      );
      state.clearMyListing();
      expect(state.myListing, isNull);
      expect(state.listings.any((l) => l.id == Listing.mySellerId), isFalse);
    });

    test('rejects unknown crop or blank fields', () {
      final state = AppState(locationService: FakeLocationService());
      expect(
        state.publishMyListing(
          crop: 'Coffee',
          quantityHint: '1 bag',
          phone: '+243 1',
        ),
        isFalse,
      );
      expect(
        state.publishMyListing(
          crop: 'Maize',
          quantityHint: '  ',
          phone: '+243 1',
        ),
        isFalse,
      );
      expect(
        state.publishMyListing(
          crop: 'Maize',
          quantityHint: '1 bag',
          phone: '',
        ),
        isFalse,
      );
      expect(state.myListing, isNull);
    });

    test('keeps separate listings per role', () {
      final state = AppState(locationService: FakeLocationService());
      state.publishMyListing(
        crop: 'Maize',
        quantityHint: 'selling',
        phone: '+243 1',
      );
      state.setRole(UserRole.buyer);
      state.publishMyListing(
        crop: 'Cassava',
        quantityHint: 'buying',
        phone: '+243 2',
      );

      expect(state.mySellerListing?.crop, 'Maize');
      expect(state.myBuyerListing?.crop, 'Cassava');
      expect(state.myListing?.id, Listing.myBuyerId);
    });
  });

  group('Discover visibility', () {
    test('seller listing appears for buyer counterparts', () {
      final state = AppState(locationService: FakeLocationService());
      state.publishMyListing(
        crop: 'Groundnuts',
        quantityHint: 'Small surplus',
        phone: '+243 970 111 222',
        name: 'Ada',
      );

      // Still seller — own listing is not a counterpart.
      expect(
        state.nearbyCounterparts.any((l) => l.id == Listing.mySellerId),
        isFalse,
      );

      state.setRole(UserRole.buyer);
      expect(
        state.nearbyCounterparts.any((l) => l.id == Listing.mySellerId),
        isTrue,
      );
      final shown = state.nearbyCounterparts
          .firstWhere((l) => l.id == Listing.mySellerId);
      expect(shown.crop, 'Groundnuts');
      expect(shown.name, 'Ada');
    });
  });

  group('persistence', () {
    test('my listings survive cold start', () async {
      final store = await LocalStateStore.open();
      final state = AppState.fromStore(
        store,
        locationService: FakeLocationService(),
      );
      state.publishMyListing(
        crop: 'Beans',
        quantityHint: 'Weekly buyer · bags',
        phone: '+243 900',
        name: 'Marie',
        location: 'Goma',
      );
      state.setRole(UserRole.buyer);
      state.publishMyListing(
        crop: 'Rice',
        quantityHint: 'Needs 500 kg this week',
        phone: '+243 901',
      );
      await state.waitForPersistence();

      final reloaded = AppState.fromStore(
        await LocalStateStore.open(),
        locationService: FakeLocationService(),
      );
      expect(reloaded.mySellerListing?.crop, 'Beans');
      expect(reloaded.mySellerListing?.phone, '+243 900');
      expect(reloaded.myBuyerListing?.crop, 'Rice');
      expect(reloaded.role, UserRole.buyer);
      expect(reloaded.myListing?.id, Listing.myBuyerId);
    });

    test('clear persists as unpublished', () async {
      final store = await LocalStateStore.open();
      final state = AppState.fromStore(
        store,
        locationService: FakeLocationService(),
      );
      state.publishMyListing(
        crop: 'Maize',
        quantityHint: 'qty',
        phone: '+243 1',
      );
      await state.waitForPersistence();
      state.clearMyListing();
      await state.waitForPersistence();

      final reloaded = AppState.fromStore(
        await LocalStateStore.open(),
        locationService: FakeLocationService(),
      );
      expect(reloaded.mySellerListing, isNull);
    });
  });
}

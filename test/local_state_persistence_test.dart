import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/local_state_store.dart';

import 'fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStateStore', () {
    test('defaults when prefs are empty', () async {
      final store = await LocalStateStore.open();
      final snap = store.load();
      expect(snap.credits, 5);
      expect(snap.enabledRoles, {UserRole.seller, UserRole.buyer});
      expect(snap.activeRole, UserRole.seller);
      expect(snap.displayName, isEmpty);
      expect(snap.location, isEmpty);
      expect(snap.tagline, isEmpty);
      expect(snap.buyingInterests, isEmpty);
      expect(snap.sellingInterests, ['Maize']);
      expect(snap.unlockedListingIds, isEmpty);
    });

    test('round-trips a full snapshot', () async {
      final store = await LocalStateStore.open();
      await store.save(
        LocalStateSnapshot(
          credits: 12,
          enabledRoles: const {UserRole.buyer},
          activeRole: UserRole.buyer,
          displayName: 'Ada',
          location: 'Goma',
          tagline: '100% organic farm',
          buyingInterests: const ['Beans', 'Rice', 'Heirloom Tomato'],
          sellingInterests: const ['Cassava'],
          unlockedListingIds: <String>{'b1', 's2'},
        ),
      );

      final reloaded = (await LocalStateStore.open()).load();
      expect(reloaded.credits, 12);
      expect(reloaded.enabledRoles, {UserRole.buyer});
      expect(reloaded.activeRole, UserRole.buyer);
      expect(reloaded.displayName, 'Ada');
      expect(reloaded.location, 'Goma');
      expect(reloaded.tagline, '100% organic farm');
      expect(reloaded.buyingInterests, ['Beans', 'Rice', 'Heirloom Tomato']);
      expect(reloaded.sellingInterests, ['Cassava']);
      expect(reloaded.unlockedListingIds, {'b1', 's2'});
    });

    test('empty selling interests do not re-seed Maize', () async {
      final store = await LocalStateStore.open();
      await store.save(
        LocalStateSnapshot(
          credits: 5,
          enabledRoles: const {UserRole.seller},
          activeRole: UserRole.seller,
          displayName: '',
          location: '',
          tagline: '',
          buyingInterests: const [],
          sellingInterests: const [],
          unlockedListingIds: <String>{},
        ),
      );

      expect((await LocalStateStore.open()).load().sellingInterests, isEmpty);
    });

    test('migrates legacy mvp.role to enabledRoles + activeRole', () async {
      SharedPreferences.setMockInitialValues({
        'mvp.role': 'buyer',
        'mvp.credits': 7,
      });
      final snap = (await LocalStateStore.open()).load();
      expect(snap.enabledRoles, {UserRole.buyer});
      expect(snap.activeRole, UserRole.buyer);
      expect(snap.credits, 7);
    });

    test('empty prefs use dual-role defaults (not legacy single-role)', () async {
      SharedPreferences.setMockInitialValues({});
      final snap = (await LocalStateStore.open()).load();
      expect(snap.enabledRoles, {UserRole.seller, UserRole.buyer});
      expect(snap.activeRole, UserRole.seller);
    });
  });

  group('AppState persistence', () {
    test('mutations survive a simulated cold start', () async {
      final store = await LocalStateStore.open();
      final state = AppState.fromStore(
        store,
        locationService: FakeLocationService(),
      );

      state.setActiveRole(UserRole.buyer);
      state.updateProfile(
        displayName: 'Marie',
        location: 'Bukavu',
        tagline: 'Heirloom tomatoes',
      );
      state.toggleBuyingInterest('Beans');
      state.toggleSellingInterest('Cassava');
      state.toggleSellingInterest('Maize'); // remove seed
      state.addCredits(2);
      expect(state.unlockContact('b1'), isTrue);
      await state.waitForPersistence();

      final reloaded = AppState.fromStore(
        await LocalStateStore.open(),
        locationService: FakeLocationService(),
      );

      expect(reloaded.enabledRoles, {UserRole.seller, UserRole.buyer});
      expect(reloaded.activeRole, UserRole.buyer);
      expect(reloaded.displayName, 'Marie');
      expect(reloaded.location, 'Bukavu');
      expect(reloaded.tagline, 'Heirloom tomatoes');
      expect(reloaded.buyingInterests, ['Beans']);
      expect(reloaded.sellingInterests, ['Cassava']);
      expect(reloaded.credits, 6); // 5 + 2 - 1 unlock
      expect(reloaded.unlockedListingIds, {'b1'});
      expect(reloaded.isUnlocked('b1'), isTrue);
    });

    test('without store, in-memory defaults stay unchanged', () {
      final state = AppState(locationService: FakeLocationService());
      expect(state.credits, 5);
      expect(state.enabledRoles, {UserRole.seller, UserRole.buyer});
      expect(state.activeRole, UserRole.seller);
      expect(state.role, UserRole.seller);
      expect(state.sellingInterests, ['Maize']);
      state.setRole(UserRole.buyer);
      expect(state.activeRole, UserRole.buyer);
    });

    test('dual roles: browse-as does not wipe interests or listings', () async {
      final store = await LocalStateStore.open();
      final state = AppState.fromStore(
        store,
        locationService: FakeLocationService(),
      );

      expect(state.setEnabledRoles({UserRole.seller, UserRole.buyer}), isTrue);
      state.setActiveRole(UserRole.seller);
      expect(
        state.publishMyListing(
          crop: 'Maize',
          quantityHint: '1 tonne',
          phone: '+243 970 000 001',
        ),
        isTrue,
      );
      state.toggleSellingInterest('Beans');

      state.setActiveRole(UserRole.buyer);
      expect(
        state.publishMyListing(
          crop: 'Cassava',
          quantityHint: 'bags weekly',
          phone: '+243 970 000 002',
        ),
        isTrue,
      );
      state.toggleBuyingInterest('Rice');

      // Switch browse-as back to seller — other role data intact.
      state.setActiveRole(UserRole.seller);
      expect(state.mySellerListing?.crop, 'Maize');
      expect(state.myBuyerListing?.crop, 'Cassava');
      expect(state.sellingInterests, containsAll(['Maize', 'Beans']));
      expect(state.buyingInterests, contains('Rice'));
      expect(state.relevantInterests, state.sellingInterests);

      await state.waitForPersistence();
      final reloaded = AppState.fromStore(
        await LocalStateStore.open(),
        locationService: FakeLocationService(),
      );
      expect(reloaded.mySellerListing?.crop, 'Maize');
      expect(reloaded.myBuyerListing?.crop, 'Cassava');
      expect(reloaded.activeRole, UserRole.seller);
    });

    test('cannot disable the last enabled role', () {
      final state = AppState(
        enabledRoles: {UserRole.seller},
        activeRole: UserRole.seller,
        locationService: FakeLocationService(),
      );
      expect(state.setRoleEnabled(UserRole.seller, enabled: false), isFalse);
      expect(state.enabledRoles, {UserRole.seller});
      expect(state.activeRole, UserRole.seller);
    });

    test('disabling active role moves activeRole to remaining role', () {
      final state = AppState(
        enabledRoles: {UserRole.seller, UserRole.buyer},
        activeRole: UserRole.buyer,
        locationService: FakeLocationService(),
      );
      expect(state.setRoleEnabled(UserRole.buyer, enabled: false), isTrue);
      expect(state.enabledRoles, {UserRole.seller});
      expect(state.activeRole, UserRole.seller);
    });

    test('tagline syncs onto published listings', () {
      final state = AppState(locationService: FakeLocationService());
      expect(
        state.publishMyListing(
          crop: 'Maize',
          quantityHint: 'ready',
          phone: '+243 1',
        ),
        isTrue,
      );
      state.updateProfile(tagline: 'Village surplus');
      expect(state.mySellerListing?.tagline, 'Village surplus');
      expect(state.tagline, 'Village surplus');
    });
  });
}

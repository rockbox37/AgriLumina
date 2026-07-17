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
      expect(snap.role, UserRole.seller);
      expect(snap.displayName, isEmpty);
      expect(snap.location, isEmpty);
      expect(snap.buyingInterests, isEmpty);
      expect(snap.sellingInterests, ['Maize']);
      expect(snap.unlockedListingIds, isEmpty);
    });

    test('round-trips a full snapshot', () async {
      final store = await LocalStateStore.open();
      await store.save(
        LocalStateSnapshot(
          credits: 12,
          role: UserRole.buyer,
          displayName: 'Ada',
          location: 'Goma',
          buyingInterests: const ['Beans', 'Rice'],
          sellingInterests: const ['Cassava'],
          unlockedListingIds: <String>{'b1', 's2'},
        ),
      );

      final reloaded = (await LocalStateStore.open()).load();
      expect(reloaded.credits, 12);
      expect(reloaded.role, UserRole.buyer);
      expect(reloaded.displayName, 'Ada');
      expect(reloaded.location, 'Goma');
      expect(reloaded.buyingInterests, ['Beans', 'Rice']);
      expect(reloaded.sellingInterests, ['Cassava']);
      expect(reloaded.unlockedListingIds, {'b1', 's2'});
    });

    test('empty selling interests do not re-seed Maize', () async {
      final store = await LocalStateStore.open();
      await store.save(
        LocalStateSnapshot(
          credits: 5,
          role: UserRole.seller,
          displayName: '',
          location: '',
          buyingInterests: const [],
          sellingInterests: const [],
          unlockedListingIds: <String>{},
        ),
      );

      expect((await LocalStateStore.open()).load().sellingInterests, isEmpty);
    });
  });

  group('AppState persistence', () {
    test('mutations survive a simulated cold start', () async {
      final store = await LocalStateStore.open();
      final state = AppState.fromStore(
        store,
        locationService: FakeLocationService(),
      );

      state.setRole(UserRole.buyer);
      state.updateProfile(displayName: 'Marie', location: 'Bukavu');
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

      expect(reloaded.role, UserRole.buyer);
      expect(reloaded.displayName, 'Marie');
      expect(reloaded.location, 'Bukavu');
      expect(reloaded.buyingInterests, ['Beans']);
      expect(reloaded.sellingInterests, ['Cassava']);
      expect(reloaded.credits, 6); // 5 + 2 - 1 unlock
      expect(reloaded.unlockedListingIds, {'b1'});
      expect(reloaded.isUnlocked('b1'), isTrue);
    });

    test('without store, in-memory defaults stay unchanged', () {
      final state = AppState(locationService: FakeLocationService());
      expect(state.credits, 5);
      expect(state.role, UserRole.seller);
      expect(state.sellingInterests, ['Maize']);
      state.setRole(UserRole.buyer);
      expect(state.role, UserRole.buyer);
    });
  });
}

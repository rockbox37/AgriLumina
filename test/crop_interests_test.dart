import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/user_role.dart';

import 'fake_location_service.dart';

void main() {
  group('AppState crop interests', () {
    test('seeds selling Maize and empty buying', () {
      final state = AppState(locationService: FakeLocationService());
      expect(state.sellingInterests, ['Maize']);
      expect(state.buyingInterests, isEmpty);
      expect(state.role, UserRole.seller);
      expect(state.relevantInterests, ['Maize']);
    });

    test('add is idempotent and prefers canonical aliases', () {
      final state = AppState(locationService: FakeLocationService());
      state.addBuyingInterest('Beans');
      state.addBuyingInterest('Beans');
      state.addBuyingInterest('bean');
      expect(state.buyingInterests, ['Beans']);
    });

    test('add accepts custom crops with normalized display id', () {
      final state = AppState(locationService: FakeLocationService());
      state.addBuyingInterest('heirloom tomato');
      state.addBuyingInterest('Heirloom Tomato');
      expect(state.buyingInterests, ['Heirloom Tomato']);
    });

    test('add maps near-alias free text to canonical id', () {
      final state = AppState(locationService: FakeLocationService());
      state.addSellingInterest('corn');
      expect(state.sellingInterests, ['Maize']);
    });

    test('remove is safe when absent', () {
      final state = AppState(locationService: FakeLocationService());
      state.removeBuyingInterest('Maize');
      expect(state.buyingInterests, isEmpty);
      state.removeSellingInterest('Cassava');
      expect(state.sellingInterests, ['Maize']);
    });

    test('remove drops custom crops', () {
      final state = AppState(locationService: FakeLocationService());
      state.addBuyingInterest('Sorghum');
      state.removeBuyingInterest('sorghum');
      expect(state.buyingInterests, isEmpty);
    });

    test('toggle add/remove on selling list', () {
      final state = AppState(locationService: FakeLocationService());
      state.toggleSellingInterest('Cassava');
      expect(state.sellingInterests, ['Maize', 'Cassava']);
      state.toggleSellingInterest('Maize');
      expect(state.sellingInterests, ['Cassava']);
    });

    test('relevantInterests follows active role', () {
      final state = AppState(locationService: FakeLocationService());
      state.addBuyingInterest('Beans');
      expect(state.relevantInterests, ['Maize']);
      state.setRole(UserRole.buyer);
      expect(state.relevantInterests, ['Beans']);
    });

    test('empty lists do not crash nearbyCounterparts', () {
      final state = AppState(
        locationService: FakeLocationService(),
        sellingInterests: const [],
        buyingInterests: const [],
      );
      expect(state.nearbyCounterparts, isNotEmpty);
    });
  });
}

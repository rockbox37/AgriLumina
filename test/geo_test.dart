import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/data/mock_listings.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:agrilumina/utils/geo.dart';

import 'fake_location_service.dart';

void main() {
  group('haversineKm', () {
    test('same point is ~0 km', () {
      expect(
        haversineKm(bugobeLatitude, bugobeLongitude, bugobeLatitude, bugobeLongitude),
        closeTo(0, 0.001),
      );
    });

    test('known short distance is in a sensible range', () {
      // ~3.2 km north of seed center (mock buyer b1)
      final km = haversineKm(bugobeLatitude, bugobeLongitude, -2.121, 28.850);
      expect(km, greaterThan(2.5));
      expect(km, lessThan(4.0));
    });
  });

  group('roundKm / formatDistanceKm', () {
    test('rounds to one decimal', () {
      expect(roundKm(3.24), 3.2);
      expect(formatDistanceKm(3.26), '3.3 km');
    });
  });

  group('approximateLocationKind', () {
    test('near seed center uses sample-area kind', () {
      expect(
        approximateLocationKind(bugobeLatitude, bugobeLongitude),
        ApproximateLocationKind.nearSampleArea,
      );
    });

    test('far away uses current-location kind', () {
      expect(
        approximateLocationKind(0, 0),
        ApproximateLocationKind.currentLocation,
      );
    });
  });

  group('AppState distance sorting', () {
    test('uses seed distances when GPS unavailable', () {
      final state = AppState(
        locationService: FakeLocationService(),
      );
      expect(state.role, UserRole.seller);
      final nearby = state.nearbyCounterparts;
      expect(nearby.first.name, 'Jean-Pierre M.');
      expect(nearby.first.distanceKm, 3.2);
    });

    test('recomputes and sorts by haversine when GPS available', () async {
      final fake = FakeLocationService(
        result: LocationFetchResult.success(
          UserLocation(
            latitude: bugobeLatitude,
            longitude: bugobeLongitude,
          ),
        ),
      );
      final state = AppState(locationService: fake);
      await state.refreshLocation();

      expect(state.usingGps, isTrue);
      expect(state.deviceLocationKind, ApproximateLocationKind.nearSampleArea);

      final nearby = state.nearbyCounterparts;
      expect(nearby, isNotEmpty);
      for (var i = 1; i < nearby.length; i++) {
        expect(nearby[i].distanceKm, greaterThanOrEqualTo(nearby[i - 1].distanceKm));
      }

      // Closest buyer seed should still be Jean-Pierre near the village market.
      expect(nearby.first.id, 'b1');
      expect(
        nearby.first.distanceKm,
        closeTo(
          roundKm(
            haversineKm(
              bugobeLatitude,
              bugobeLongitude,
              mockListings.firstWhere((l) => l.id == 'b1').latitude,
              mockListings.firstWhere((l) => l.id == 'b1').longitude,
            ),
          ),
          0.01,
        ),
      );
    });
  });
}

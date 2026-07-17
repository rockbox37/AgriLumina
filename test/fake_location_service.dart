import 'package:agrilumina/services/location_service.dart';

/// Deterministic location for widget/unit tests (no platform GPS).
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.result = const LocationFetchResult.denied(),
  });

  LocationFetchResult result;

  @override
  Future<LocationFetchResult> fetchCurrentLocation() async => result;
}

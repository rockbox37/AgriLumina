import 'dart:math' as math;

/// Approximate center of the seed listing cluster used when GPS is unavailable.
/// Coords stay geographically coherent so offline distance ranking works.
const double bugobeLatitude = -2.150;
const double bugobeLongitude = 28.850;

/// Great-circle distance between two WGS84 points in kilometers.
double haversineKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusKm = 6371.0;
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Rounds to one decimal place for display (e.g. `3.2`).
double roundKm(double km) => (km * 10).roundToDouble() / 10;

/// Legacy English formatter; prefer [formatDistanceKmLocalized] in UI.
String formatDistanceKm(double km) => '${roundKm(km)} km';

/// Kind of approximate place label without reverse geocoding.
enum ApproximateLocationKind {
  nearSampleArea,
  currentLocation,
}

/// Short label kind for the user's position without reverse geocoding.
ApproximateLocationKind approximateLocationKind(
  double latitude,
  double longitude,
) {
  final distanceFromSeedCenter = haversineKm(
    latitude,
    longitude,
    bugobeLatitude,
    bugobeLongitude,
  );
  if (distanceFromSeedCenter < 50) {
    return ApproximateLocationKind.nearSampleArea;
  }
  return ApproximateLocationKind.currentLocation;
}

double _radians(double degrees) => degrees * math.pi / 180;

import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

/// User coordinates from a successful GPS read.
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

enum LocationFetchStatus {
  success,
  denied,
  serviceDisabled,
  unsupported,
  error,
}

/// Outcome of a one-shot location request.
class LocationFetchResult {
  const LocationFetchResult._({
    required this.status,
    this.position,
  });

  const LocationFetchResult.success(UserLocation position)
      : this._(
          status: LocationFetchStatus.success,
          position: position,
        );

  const LocationFetchResult.denied()
      : this._(status: LocationFetchStatus.denied);

  const LocationFetchResult.serviceDisabled()
      : this._(status: LocationFetchStatus.serviceDisabled);

  const LocationFetchResult.unsupported()
      : this._(status: LocationFetchStatus.unsupported);

  const LocationFetchResult.error()
      : this._(status: LocationFetchStatus.error);

  final LocationFetchStatus status;
  final UserLocation? position;

  bool get isSuccess => status == LocationFetchStatus.success;
}

/// Abstraction so tests can avoid real GPS / platform channels.
abstract class LocationService {
  Future<LocationFetchResult> fetchCurrentLocation();
}

/// Production implementation using the `location` package (when-in-use only).
class PluginLocationService implements LocationService {
  PluginLocationService([Location? location]) : _location = location ?? Location();

  final Location _location;

  static bool get isLikelyUnsupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Future<LocationFetchResult> fetchCurrentLocation() async {
    if (isLikelyUnsupported) {
      return const LocationFetchResult.unsupported();
    }

    try {
      var serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return const LocationFetchResult.serviceDisabled();
        }
      }

      var permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        return const LocationFetchResult.denied();
      }

      final data = await _location.getLocation();
      final lat = data.latitude;
      final lng = data.longitude;
      if (lat == null || lng == null) {
        return const LocationFetchResult.error();
      }

      return LocationFetchResult.success(
        UserLocation(latitude: lat, longitude: lng),
      );
    } on Object {
      return const LocationFetchResult.unsupported();
    }
  }
}

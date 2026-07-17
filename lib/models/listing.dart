import 'package:agrilumina/models/user_role.dart';

class Listing {
  const Listing({
    required this.id,
    required this.name,
    required this.role,
    required this.crop,
    required this.quantityHint,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.lastActiveLabel,
    required this.phone,
  });

  final String id;
  final String name;
  final UserRole role;
  final String crop;
  final String quantityHint;

  /// Seed / fallback distance from the sample cluster when GPS is unavailable.
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String location;
  final String lastActiveLabel;
  final String phone;

  Listing copyWith({double? distanceKm}) {
    return Listing(
      id: id,
      name: name,
      role: role,
      crop: crop,
      quantityHint: quantityHint,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude,
      longitude: longitude,
      location: location,
      lastActiveLabel: lastActiveLabel,
      phone: phone,
    );
  }
}

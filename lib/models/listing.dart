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

  /// Stable local id for the user's seller listing (one per device MVP).
  static const mySellerId = 'me-seller';

  /// Stable local id for the user's buyer listing (one per device MVP).
  static const myBuyerId = 'me-buyer';

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

  bool get isMine => id == mySellerId || id == myBuyerId;

  static String myIdFor(UserRole role) =>
      role == UserRole.seller ? mySellerId : myBuyerId;

  Listing copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? crop,
    String? quantityHint,
    double? distanceKm,
    double? latitude,
    double? longitude,
    String? location,
    String? lastActiveLabel,
    String? phone,
  }) {
    return Listing(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      crop: crop ?? this.crop,
      quantityHint: quantityHint ?? this.quantityHint,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      lastActiveLabel: lastActiveLabel ?? this.lastActiveLabel,
      phone: phone ?? this.phone,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'crop': crop,
        'quantityHint': quantityHint,
        'distanceKm': distanceKm,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'lastActiveLabel': lastActiveLabel,
        'phone': phone,
      };

  static Listing? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final roleName = json['role'] as String?;
    final role = roleName == UserRole.buyer.name
        ? UserRole.buyer
        : roleName == UserRole.seller.name
            ? UserRole.seller
            : null;
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final crop = json['crop'] as String?;
    final quantityHint = json['quantityHint'] as String?;
    final distanceKm = (json['distanceKm'] as num?)?.toDouble();
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final location = json['location'] as String?;
    final lastActiveLabel = json['lastActiveLabel'] as String?;
    final phone = json['phone'] as String?;
    if (role == null ||
        id == null ||
        name == null ||
        crop == null ||
        quantityHint == null ||
        distanceKm == null ||
        latitude == null ||
        longitude == null ||
        location == null ||
        lastActiveLabel == null ||
        phone == null) {
      return null;
    }
    return Listing(
      id: id,
      name: name,
      role: role,
      crop: crop,
      quantityHint: quantityHint,
      distanceKm: distanceKm,
      latitude: latitude,
      longitude: longitude,
      location: location,
      lastActiveLabel: lastActiveLabel,
      phone: phone,
    );
  }
}

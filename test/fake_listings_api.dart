import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/listings_api.dart';

/// Configurable in-memory ListingsApi for tests.
class FakeListingsApi implements ListingsApi {
  bool offline = false;

  /// When set, mutating calls throw this instead of succeeding.
  Exception? failWith;

  /// Rows returned by [fetchListings], keyed by requested role.
  final Map<UserRole, List<Listing>> rows = {
    UserRole.seller: [],
    UserRole.buyer: [],
  };

  /// Phones served by [fetchContactPhone].
  final Map<String, String> phones = {};
  Exception? contactError;

  final List<({String deviceId, Listing listing})> upserts = [];
  final List<({String deviceId, UserRole role})> deletes = [];
  int fetchCount = 0;
  int contactCount = 0;
  ({UserRole role, double? lat, double? lon, double? radiusKm})? lastFetch;

  void _gate() {
    if (offline) throw ListingsOfflineException();
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Future<List<Listing>> fetchListings({
    required UserRole role,
    required String excludeDeviceId,
    double? lat,
    double? lon,
    double? radiusKm,
  }) async {
    _gate();
    fetchCount++;
    lastFetch = (role: role, lat: lat, lon: lon, radiusKm: radiusKm);
    return List.of(rows[role] ?? const []);
  }

  @override
  Future<void> upsertListing({
    required String deviceId,
    required Listing listing,
  }) async {
    _gate();
    upserts.add((deviceId: deviceId, listing: listing));
  }

  @override
  Future<void> deleteListing({
    required String deviceId,
    required UserRole role,
  }) async {
    _gate();
    deletes.add((deviceId: deviceId, role: role));
  }

  @override
  Future<String> fetchContactPhone({
    required String deviceId,
    required String listingId,
  }) async {
    _gate();
    final error = contactError;
    if (error != null) throw error;
    contactCount++;
    final phone = phones[listingId];
    if (phone == null) throw ListingNotFoundException();
    return phone;
  }
}

Listing remoteListing(
  String id, {
  UserRole role = UserRole.buyer,
  String name = 'Remote Buyer',
  String crop = 'Maize',
  double distanceKm = 3.0,
}) =>
    Listing(
      id: id,
      name: name,
      role: role,
      crop: crop,
      quantityHint: '10 bags',
      distanceKm: distanceKm,
      latitude: -2.45,
      longitude: 28.86,
      location: 'Bugobe',
      lastActiveLabel: 'Active today',
      phone: '',
      tagline: '',
      updatedAt: DateTime.now(),
    );

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:agrilumina/data/listing_copy_keys.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/forum_api.dart' show ForumConfig;
import 'package:agrilumina/utils/geo.dart';

class ListingsConfig {
  /// Radius sent with a GPS fix; without one the server filters by role only.
  static const radiusKm = 50.0;
}

/// The device is offline or the backend is unreachable.
class ListingsOfflineException implements Exception {}

/// Daily contact-fetch limit reached (429 from /contact).
class ContactRateLimitedException implements Exception {}

/// The listing no longer exists remotely (404 from /contact).
class ListingNotFoundException implements Exception {}

/// Any other non-success backend response.
class ListingsApiException implements Exception {
  const ListingsApiException(this.statusCode, [this.error]);

  final int statusCode;
  final String? error;

  @override
  String toString() => 'ListingsApiException($statusCode, $error)';
}

/// Listings backend client: reads via the list_listings RPC (no phone in
/// payloads), writes and contact fetches via the `listings` edge function.
abstract class ListingsApi {
  Future<List<Listing>> fetchListings({
    required UserRole role,
    required String excludeDeviceId,
    double? lat,
    double? lon,
    double? radiusKm,
  });

  Future<void> upsertListing({
    required String deviceId,
    required Listing listing,
  });

  Future<void> deleteListing({
    required String deviceId,
    required UserRole role,
  });

  Future<String> fetchContactPhone({
    required String deviceId,
    required String listingId,
  });
}

/// Maps a public RPC row to the app model. Phone is always empty until the
/// contact endpoint releases it; distance falls back to the Bugobe sample
/// point when the server had no requester position.
Listing? listingFromRemoteRow(Map<String, Object?> row, DateTime now) {
  final id = row['id'];
  final name = row['name'];
  final crop = row['crop'];
  final roleName = row['role'];
  final lat = (row['lat'] as num?)?.toDouble();
  final lon = (row['lon'] as num?)?.toDouble();
  if (id is! String || name is! String || crop is! String) return null;
  if (lat == null || lon == null) return null;
  final role = roleName == UserRole.buyer.name
      ? UserRole.buyer
      : roleName == UserRole.seller.name
          ? UserRole.seller
          : null;
  if (role == null) return null;
  final updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
  final distanceKm = (row['distance_km'] as num?)?.toDouble() ??
      roundKm(haversineKm(bugobeLatitude, bugobeLongitude, lat, lon));
  return Listing(
    id: id,
    name: name,
    role: role,
    crop: crop,
    quantityHint: row['quantity_hint'] as String? ?? '',
    distanceKm: distanceKm,
    latitude: lat,
    longitude: lon,
    location: row['location_text'] as String? ?? '',
    lastActiveLabel: updatedAt == null
        ? ListingCopyKeys.activeThisWeek
        : lastActiveKeyFor(updatedAt.toLocal(), now),
    phone: '',
    tagline: row['tagline'] as String? ?? '',
    updatedAt: updatedAt,
  );
}

class HttpListingsApi implements ListingsApi {
  HttpListingsApi({http.Client? client, String? baseUrl, String? anonKey})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ForumConfig.supabaseUrl,
        _anonKey = anonKey ?? ForumConfig.anonKey;

  final http.Client _client;
  final String _baseUrl;
  final String _anonKey;

  Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      };

  @override
  Future<List<Listing>> fetchListings({
    required UserRole role,
    required String excludeDeviceId,
    double? lat,
    double? lon,
    double? radiusKm,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/rest/v1/rpc/list_listings'),
        headers: _headers,
        body: jsonEncode({
          'p_role': role.name,
          'p_exclude_device': excludeDeviceId,
          'p_lat': lat,
          'p_lon': lon,
          'p_radius_km': radiusKm,
          'p_crop': null,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw ListingsApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const ListingsApiException(200, 'bad_payload');
    final now = DateTime.now();
    return decoded
        .whereType<Map>()
        .map((m) => listingFromRemoteRow(Map<String, Object?>.from(m), now))
        .whereType<Listing>()
        .toList();
  }

  @override
  Future<void> upsertListing({
    required String deviceId,
    required Listing listing,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/functions/v1/listings/upsert'),
        headers: _headers,
        body: jsonEncode({
          'device_id': deviceId,
          'role': listing.role.name,
          'name': listing.name,
          'crop': listing.crop,
          'quantity_hint': listing.quantityHint,
          'lat': listing.latitude,
          'lon': listing.longitude,
          'location_text': listing.location,
          'tagline': listing.tagline,
          'phone': listing.phone,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw ListingsApiException(response.statusCode, response.body);
    }
  }

  @override
  Future<void> deleteListing({
    required String deviceId,
    required UserRole role,
  }) async {
    final response = await _send(
      () => _client.delete(
        Uri.parse('$_baseUrl/functions/v1/listings/${role.name}'),
        headers: _headers,
        body: jsonEncode({'device_id': deviceId}),
      ),
    );
    if (response.statusCode != 200) {
      throw ListingsApiException(response.statusCode, response.body);
    }
  }

  @override
  Future<String> fetchContactPhone({
    required String deviceId,
    required String listingId,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/functions/v1/listings/contact'),
        headers: _headers,
        body: jsonEncode({'device_id': deviceId, 'listing_id': listingId}),
      ),
    );
    switch (response.statusCode) {
      case 200:
        final decoded = jsonDecode(response.body);
        final phone = decoded is Map ? decoded['phone'] : null;
        if (phone is! String || phone.isEmpty) {
          throw const ListingsApiException(200, 'bad_payload');
        }
        return phone;
      case 404:
        throw ListingNotFoundException();
      case 429:
        throw ContactRateLimitedException();
      default:
        throw ListingsApiException(response.statusCode, response.body);
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on http.ClientException {
      throw ListingsOfflineException();
    } catch (e) {
      // dart:io's SocketException without importing dart:io (web-safe).
      if (e.toString().contains('SocketException')) {
        throw ListingsOfflineException();
      }
      rethrow;
    }
  }
}

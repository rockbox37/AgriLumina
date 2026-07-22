import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agrilumina/data/listing_copy_keys.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/listings_api.dart';

const _device = 'a3bb189e-8bf9-3888-9912-ace4e6543002';

Map<String, Object?> _row({
  String id = '11111111-1111-4111-8111-111111111111',
  double? distanceKm = 2.5,
  String? updatedAt,
}) =>
    {
      'id': id,
      'role': 'buyer',
      'name': 'Chantal M.',
      'crop': 'Beans',
      'quantity_hint': '10 bags',
      'lat': -2.46,
      'lon': 28.87,
      'location_text': 'Bugobe',
      'tagline': 'fair prices',
      'updated_at': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      'distance_km': distanceKm,
    };

void main() {
  test('fetchListings posts RPC args and parses rows', () async {
    late Map<String, Object?> sent;
    final api = HttpListingsApi(
      client: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/list_listings');
        sent = Map<String, Object?>.from(jsonDecode(request.body) as Map);
        return http.Response(jsonEncode([_row(), {'bad': 'row'}]), 200);
      }),
    );

    final listings = await api.fetchListings(
      role: UserRole.buyer,
      excludeDeviceId: _device,
      lat: -2.45,
      lon: 28.86,
      radiusKm: 50,
    );

    expect(sent['p_role'], 'buyer');
    expect(sent['p_exclude_device'], _device);
    expect(sent['p_lat'], -2.45);
    expect(sent['p_radius_km'], 50);
    expect(listings, hasLength(1));
    final listing = listings.single;
    expect(listing.name, 'Chantal M.');
    expect(listing.phone, isEmpty);
    expect(listing.distanceKm, 2.5);
    expect(listing.lastActiveLabel, ListingCopyKeys.activeToday);
  });

  test('no GPS sends nulls; null distance falls back to Bugobe haversine',
      () async {
    late Map<String, Object?> sent;
    final api = HttpListingsApi(
      client: MockClient((request) async {
        sent = Map<String, Object?>.from(jsonDecode(request.body) as Map);
        return http.Response(jsonEncode([_row(distanceKm: null)]), 200);
      }),
    );

    final listings = await api.fetchListings(
      role: UserRole.buyer,
      excludeDeviceId: _device,
    );

    expect(sent['p_lat'], isNull);
    expect(sent['p_radius_km'], isNull);
    // Row at (-2.46, 28.87) is ~35km from the Bugobe sample point
    // (-2.150, 28.850); the haversine fallback must land near that.
    expect(listings.single.distanceKm, greaterThan(30));
    expect(listings.single.distanceKm, lessThan(40));
  });

  test('stale updated_at buckets into older labels', () async {
    final twoDaysAgo =
        DateTime.now().subtract(const Duration(days: 2)).toUtc();
    final api = HttpListingsApi(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode([_row(updatedAt: twoDaysAgo.toIso8601String())]),
          200,
        ),
      ),
    );

    final listings = await api.fetchListings(
      role: UserRole.buyer,
      excludeDeviceId: _device,
    );

    expect(listings.single.lastActiveLabel, ListingCopyKeys.active2DaysAgo);
  });

  test('upsert sends the full payload including phone', () async {
    late Map<String, Object?> sent;
    final api = HttpListingsApi(
      client: MockClient((request) async {
        expect(request.url.path, '/functions/v1/listings/upsert');
        sent = Map<String, Object?>.from(jsonDecode(request.body) as Map);
        return http.Response(jsonEncode({'id': 'x', 'updated_at': 'now'}), 200);
      }),
    );

    final listing = remoteListingForUpsert();
    await api.upsertListing(deviceId: _device, listing: listing);

    expect(sent['device_id'], _device);
    expect(sent['role'], 'seller');
    expect(sent['phone'], '+243970000009');
    expect(sent['quantity_hint'], '5 bags');
  });

  test('delete targets the role path', () async {
    late http.Request captured;
    final api = HttpListingsApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );

    await api.deleteListing(deviceId: _device, role: UserRole.seller);

    expect(captured.method, 'DELETE');
    expect(captured.url.path, '/functions/v1/listings/seller');
    expect(jsonDecode(captured.body), {'device_id': _device});
  });

  test('contact maps 200/404/429/offline', () async {
    Future<void> expectStatus(
      http.Response response,
      Matcher matcher,
    ) async {
      final api = HttpListingsApi(
        client: MockClient((request) async => response),
      );
      await expectLater(
        api.fetchContactPhone(deviceId: _device, listingId: 'x'),
        matcher,
      );
    }

    final okApi = HttpListingsApi(
      client: MockClient(
        (request) async =>
            http.Response(jsonEncode({'phone': '+243970000002'}), 200),
      ),
    );
    expect(
      await okApi.fetchContactPhone(deviceId: _device, listingId: 'x'),
      '+243970000002',
    );

    await expectStatus(
      http.Response('{"error":"not_found"}', 404),
      throwsA(isA<ListingNotFoundException>()),
    );
    await expectStatus(
      http.Response('{"error":"rate_limited"}', 429),
      throwsA(isA<ContactRateLimitedException>()),
    );

    final offlineApi = HttpListingsApi(
      client: MockClient((request) async => throw http.ClientException('x')),
    );
    await expectLater(
      offlineApi.fetchContactPhone(deviceId: _device, listingId: 'x'),
      throwsA(isA<ListingsOfflineException>()),
    );
  });

  test('lastActiveKeyFor buckets by calendar day', () {
    final now = DateTime(2026, 7, 22, 8); // 08:00
    String key(DateTime t) => lastActiveKeyFor(t, now);

    expect(key(DateTime(2026, 7, 22, 1)), ListingCopyKeys.activeToday);
    // Late yesterday evening is still "yesterday" even though <24h ago.
    expect(key(DateTime(2026, 7, 21, 23)), ListingCopyKeys.activeYesterday);
    expect(key(DateTime(2026, 7, 20, 12)), ListingCopyKeys.active2DaysAgo);
    expect(key(DateTime(2026, 7, 19, 12)), ListingCopyKeys.active3DaysAgo);
    expect(key(DateTime(2026, 7, 15, 12)), ListingCopyKeys.activeThisWeek);
  });
}

Listing remoteListingForUpsert() => Listing(
      id: Listing.mySellerId,
      name: 'Amani K.',
      role: UserRole.seller,
      crop: 'Maize',
      quantityHint: '5 bags',
      distanceKm: 0,
      latitude: -2.45,
      longitude: 28.86,
      location: 'Bugobe',
      lastActiveLabel: ListingCopyKeys.activeToday,
      phone: '+243970000009',
      tagline: 'fresh',
    );

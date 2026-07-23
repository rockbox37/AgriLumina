import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agrilumina/admin/admin_api.dart';

http.Response _tokenResponse(String access, String refresh) => http.Response(
      jsonEncode({
        'access_token': access,
        'refresh_token': refresh,
        'expires_in': 3600,
        'user': {'email': 'admin@test.local'},
      }),
      200,
    );

void main() {
  test('login stores session and reports it', () async {
    AdminSession? reported;
    final api = AdminApi(
      client: MockClient((request) async {
        expect(request.url.path, '/auth/v1/token');
        expect(request.url.queryParameters['grant_type'], 'password');
        return _tokenResponse('jwt-1', 'refresh-1');
      }),
      onSessionChanged: (s) => reported = s,
    );

    final session = await api.login('admin@test.local', 'pw');

    expect(session.accessToken, 'jwt-1');
    expect(reported?.refreshToken, 'refresh-1');
    expect(api.session?.email, 'admin@test.local');
  });

  test('login failure throws AdminAuthException with message', () async {
    final api = AdminApi(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({'error_description': 'Invalid login credentials'}),
          400,
        ),
      ),
    );

    await expectLater(
      api.login('admin@test.local', 'wrong'),
      throwsA(
        isA<AdminAuthException>()
            .having((e) => e.message, 'message', 'Invalid login credentials'),
      ),
    );
  });

  test('401 triggers one refresh (rotating tokens) and a retry', () async {
    final calls = <String>[];
    AdminSession? reported;
    final api = AdminApi(
      client: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}'
            '?${request.url.query}');
        if (request.url.path == '/auth/v1/token') {
          return _tokenResponse('jwt-2', 'refresh-2');
        }
        final auth = request.headers['Authorization'];
        if (auth == 'Bearer jwt-expired') {
          return http.Response('{"message":"JWT expired"}', 401);
        }
        return http.Response('[]', 200);
      }),
      onSessionChanged: (s) => reported = s,
    );
    api.session = const AdminSession(
      accessToken: 'jwt-expired',
      refreshToken: 'refresh-1',
      email: 'admin@test.local',
    );

    final posts = await api.fetchPosts();

    expect(posts, isEmpty);
    expect(
      calls.where((c) => c.contains('grant_type=refresh_token')).length,
      1,
    );
    // Rotated refresh token was adopted and reported for persistence.
    expect(api.session?.refreshToken, 'refresh-2');
    expect(reported?.refreshToken, 'refresh-2');
  });

  test('fetchStats parses the rpc payload', () async {
    final api = AdminApi(
      client: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/admin_stats');
        return http.Response(
          jsonEncode({
            'posts_by_status': {'visible': 4, 'hidden': 2},
            'posts_24h': 6,
            'unread_alerts': 3,
            'top_reported': [
              {
                'id': 'p1',
                'author_name': 'A',
                'snippet': 's',
                'status': 'hidden',
                'report_count': 5,
              },
            ],
          }),
          200,
        );
      }),
    )..session = const AdminSession(
        accessToken: 'jwt',
        refreshToken: 'r',
        email: 'a@b.c',
      );

    final stats = await api.fetchStats();

    expect(stats.statusCount('visible'), 4);
    expect(stats.statusCount('hidden'), 2);
    expect(stats.unreadAlerts, 3);
    expect(stats.topReported.single.reportCount, 5);
  });

  test('setPostStatus posts rpc args and parses the returned row', () async {
    late Map<String, Object?> sent;
    final api = AdminApi(
      client: MockClient((request) async {
        sent = Map<String, Object?>.from(jsonDecode(request.body) as Map);
        return http.Response(
          jsonEncode({
            'id': '11111111-1111-4111-8111-111111111111',
            'device_id': 'd',
            'author_name': 'A',
            'body': 'b',
            'status': 'visible',
            'hidden_reason': null,
            'created_at': '2026-07-22T10:00:00Z',
          }),
          200,
        );
      }),
    )..session = const AdminSession(
        accessToken: 'jwt',
        refreshToken: 'r',
        email: 'a@b.c',
      );

    final post = await api.setPostStatus(
      '11111111-1111-4111-8111-111111111111',
      'visible',
    );

    expect(sent['p_status'], 'visible');
    expect(post.status, 'visible');
    expect(post.hiddenReason, isNull);
  });

  test('data calls without a session throw AdminAuthException', () async {
    final api = AdminApi(client: MockClient((request) async {
      fail('no request expected');
    }));

    await expectLater(api.fetchStats(), throwsA(isA<AdminAuthException>()));
  });

  test('non-2xx mutation surfaces AdminApiException', () async {
    final api = AdminApi(
      client: MockClient(
        (request) async => http.Response('{"message":"denied"}', 403),
      ),
    )..session = const AdminSession(
        accessToken: 'jwt',
        refreshToken: 'r',
        email: 'a@b.c',
      );

    await expectLater(
      api.addBlocklistTerm('term', 3),
      throwsA(
        isA<AdminApiException>().having((e) => e.statusCode, 'status', 403),
      ),
    );
  });

  test('requests that hang past the timeout map to AdminOfflineException',
      () async {
    final api = AdminApi(
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return _tokenResponse('jwt', 'refresh');
      }),
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      api.login('admin@test.local', 'pw'),
      throwsA(isA<AdminOfflineException>()),
    );

    api.session = const AdminSession(
      accessToken: 'jwt',
      refreshToken: 'r',
      email: 'a@b.c',
    );
    await expectLater(api.fetchPosts(), throwsA(isA<AdminOfflineException>()));
  });

  test('fetchListings parses rows and deleteListing targets the id', () async {
    final calls = <String>[];
    final api = AdminApi(
      client: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}'
            '?${request.url.query}');
        if (request.method == 'DELETE') return http.Response('', 204);
        return http.Response(
          jsonEncode([
            {
              'id': '11111111-1111-4111-8111-111111111111',
              'owner_device_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
              'role': 'seller',
              'name': 'Amani K.',
              'crop': 'Maize',
              'quantity_hint': '5 bags',
              'location_text': 'Bugobe',
              'phone': '+243970000001',
              'updated_at':
                  DateTime.now().toUtc().toIso8601String(),
            },
            {
              'id': '22222222-2222-4222-8222-222222222222',
              'owner_device_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
              'role': 'buyer',
              'name': 'Old Row',
              'crop': 'Beans',
              'quantity_hint': '',
              'location_text': '',
              'phone': '+243970000002',
              'updated_at': DateTime.now()
                  .subtract(const Duration(days: 45))
                  .toUtc()
                  .toIso8601String(),
            },
          ]),
          200,
        );
      }),
    )..session = const AdminSession(
        accessToken: 'jwt',
        refreshToken: 'r',
        email: 'a@b.c',
      );

    final listings = await api.fetchListings();

    expect(listings, hasLength(2));
    expect(listings.first.phone, '+243970000001');
    expect(listings.first.expired, isFalse);
    expect(listings.last.expired, isTrue);
    expect(calls.single, contains('order=updated_at.desc'));

    await api.deleteListing(listings.first.id);
    expect(
      calls.last,
      'DELETE /rest/v1/listings?id=eq.11111111-1111-4111-8111-111111111111',
    );
  });

  test('logout clears and reports null session', () async {
    AdminSession? reported = const AdminSession(
      accessToken: 'x',
      refreshToken: 'y',
      email: 'z',
    );
    final api = AdminApi(
      client: MockClient((request) async => http.Response('', 204)),
      onSessionChanged: (s) => reported = s,
    )..session = const AdminSession(
        accessToken: 'jwt',
        refreshToken: 'r',
        email: 'a@b.c',
      );

    await api.logout();

    expect(api.session, isNull);
    expect(reported, isNull);
  });
}

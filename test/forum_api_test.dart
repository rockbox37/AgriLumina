import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agrilumina/services/forum_api.dart';

void main() {
  const deviceId = 'a3bb189e-8bf9-3888-9912-ace4e6543002';

  HttpForumApi apiWith(MockClient client) => HttpForumApi(client: client);

  test('fetchThreads parses public view rows and passes filters', () async {
    late Uri captured;
    final api = apiWith(
      MockClient((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode([
            {
              'id': '11111111-1111-4111-8111-111111111111',
              'parent_id': null,
              'author_name': 'Amani',
              'body': 'Maize prices are up',
              'created_at': '2026-07-22T10:00:00Z',
              'reply_count': 2,
              'last_activity_at': '2026-07-22T11:00:00Z',
            },
            {'bad': 'row'},
          ]),
          200,
        );
      }),
    );

    final threads = await api.fetchThreads();

    expect(threads, hasLength(1));
    expect(threads.first.authorName, 'Amani');
    expect(threads.first.replyCount, 2);
    expect(threads.first.isRoot, isTrue);
    expect(captured.queryParameters['parent_id'], 'is.null');
    expect(captured.queryParameters['order'], 'last_activity_at.desc,id.desc');
  });

  test('fetchThreads with before adds keyset cursor', () async {
    late Uri captured;
    final api = apiWith(
      MockClient((request) async {
        captured = request.url;
        return http.Response('[]', 200);
      }),
    );

    await api.fetchThreads(before: DateTime.utc(2026, 7, 22, 11));

    expect(
      captured.queryParameters['last_activity_at'],
      'lt.2026-07-22T11:00:00.000Z',
    );
  });

  test('createPost maps 201 pending_review', () async {
    final api = apiWith(
      MockClient(
        (request) async => http.Response(
          jsonEncode({
            'id': '22222222-2222-4222-8222-222222222222',
            'created_at': '2026-07-22T10:00:00Z',
            'status': 'pending_review',
          }),
          201,
        ),
      ),
    );

    final post = await api.createPost(
      deviceId: deviceId,
      authorName: 'Amani',
      body: 'Visit https://spam.example now',
    );

    expect(post.isPendingReview, isTrue);
    expect(post.body, 'Visit https://spam.example now');
  });

  test('createPost maps 429 to ForumRateLimitedException', () async {
    final api = apiWith(
      MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'rate_limited', 'retry_after_seconds': 30}),
          429,
        ),
      ),
    );

    await expectLater(
      api.createPost(deviceId: deviceId, authorName: 'A', body: 'hello'),
      throwsA(
        isA<ForumRateLimitedException>()
            .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', 30),
      ),
    );
  });

  test('createPost maps 409 to ForumDuplicateException', () async {
    final api = apiWith(
      MockClient(
        (request) async =>
            http.Response(jsonEncode({'error': 'duplicate'}), 409),
      ),
    );

    await expectLater(
      api.createPost(deviceId: deviceId, authorName: 'A', body: 'hello'),
      throwsA(isA<ForumDuplicateException>()),
    );
  });

  test('network failure maps to ForumOfflineException', () async {
    final api = apiWith(
      MockClient((request) async => throw http.ClientException('down')),
    );

    await expectLater(
      api.fetchThreads(),
      throwsA(isA<ForumOfflineException>()),
    );
  });

  test('deletePost surfaces 403 as ForumApiException', () async {
    final api = apiWith(
      MockClient(
        (request) async =>
            http.Response(jsonEncode({'error': 'forbidden'}), 403),
      ),
    );

    await expectLater(
      api.deletePost(
        deviceId: deviceId,
        postId: '33333333-3333-4333-8333-333333333333',
      ),
      throwsA(
        isA<ForumApiException>()
            .having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });

  test('reportPost posts device and post ids', () async {
    late http.Request captured;
    final api = apiWith(
      MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );

    await api.reportPost(
      deviceId: deviceId,
      postId: '33333333-3333-4333-8333-333333333333',
    );

    expect(captured.url.path, endsWith('/forum/reports'));
    final body = jsonDecode(captured.body) as Map<String, Object?>;
    expect(body['device_id'], deviceId);
    expect(body['post_id'], '33333333-3333-4333-8333-333333333333');
  });
}

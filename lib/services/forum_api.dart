import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:agrilumina/models/forum_post.dart';

/// Hosted Supabase project (rockbox37's org). The anon key is a public
/// client credential by design; all sensitive paths are enforced server-side.
class ForumConfig {
  static const supabaseUrl = 'https://lpjkqqgiicswproumynn.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxwamtxcWdpaWNzd3Byb3VteW5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ3Mjg1MzcsImV4cCI6MjEwMDMwNDUzN30.D62iA-kyF9bXApNtIIA4f4e8GHTQ4UBllEN66yl0wLI';
  static const threadsPageSize = 20;
  static const repliesPageSize = 50;
}

/// The device is offline or the backend is unreachable.
class ForumOfflineException implements Exception {}

/// Posting throttled server-side; retry after [retryAfterSeconds].
class ForumRateLimitedException implements Exception {
  const ForumRateLimitedException(this.retryAfterSeconds);

  final int retryAfterSeconds;
}

/// Same content already posted from this device recently.
class ForumDuplicateException implements Exception {}

/// Any other non-success backend response.
class ForumApiException implements Exception {
  const ForumApiException(this.statusCode, [this.error]);

  final int statusCode;
  final String? error;

  @override
  String toString() => 'ForumApiException($statusCode, $error)';
}

/// Forum backend client: reads via PostgREST view, writes via the `forum`
/// edge function (see supabase/functions/forum).
abstract class ForumApi {
  Future<List<ForumPost>> fetchThreads({DateTime? before});

  Future<List<ForumPost>> fetchReplies(String threadId);

  Future<ForumPost> createPost({
    required String deviceId,
    required String authorName,
    required String body,
    String? parentId,
  });

  Future<void> reportPost({
    required String deviceId,
    required String postId,
  });

  Future<void> deletePost({
    required String deviceId,
    required String postId,
  });
}

class HttpForumApi implements ForumApi {
  HttpForumApi({http.Client? client, String? baseUrl, String? anonKey})
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
  Future<List<ForumPost>> fetchThreads({DateTime? before}) {
    final params = <String, String>{
      'select':
          'id,parent_id,author_name,body,created_at,reply_count,last_activity_at',
      'parent_id': 'is.null',
      'order': 'last_activity_at.desc,id.desc',
      'limit': '${ForumConfig.threadsPageSize}',
      if (before != null)
        'last_activity_at': 'lt.${before.toUtc().toIso8601String()}',
    };
    return _fetchPosts(params);
  }

  @override
  Future<List<ForumPost>> fetchReplies(String threadId) {
    final params = <String, String>{
      'select': 'id,parent_id,author_name,body,created_at',
      'parent_id': 'eq.$threadId',
      'order': 'created_at.asc',
      'limit': '${ForumConfig.repliesPageSize}',
    };
    return _fetchPosts(params);
  }

  Future<List<ForumPost>> _fetchPosts(Map<String, String> params) async {
    final uri = Uri.parse('$_baseUrl/rest/v1/forum_public_posts')
        .replace(queryParameters: params);
    final response = await _send(() => _client.get(uri, headers: _headers));
    if (response.statusCode != 200) {
      throw ForumApiException(response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const ForumApiException(200, 'bad_payload');
    return decoded
        .whereType<Map>()
        .map((m) => ForumPost.fromJson(Map<String, Object?>.from(m)))
        .whereType<ForumPost>()
        .toList();
  }

  @override
  Future<ForumPost> createPost({
    required String deviceId,
    required String authorName,
    required String body,
    String? parentId,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/functions/v1/forum/posts'),
        headers: _headers,
        body: jsonEncode({
          'device_id': deviceId,
          'author_name': authorName,
          'body': body,
          'parent_id': ?parentId,
        }),
      ),
    );
    final payload = _decodeObject(response.body);
    switch (response.statusCode) {
      case 201:
        final now = DateTime.now();
        return ForumPost(
          id: payload['id'] as String? ?? '',
          parentId: parentId,
          authorName: authorName,
          body: body,
          createdAt:
              DateTime.tryParse(payload['created_at'] as String? ?? '') ?? now,
          status: payload['status'] == 'pending_review'
              ? ForumPostStatus.pendingReview
              : ForumPostStatus.visible,
        );
      case 429:
        throw ForumRateLimitedException(
          (payload['retry_after_seconds'] as num?)?.toInt() ?? 60,
        );
      case 409:
        throw ForumDuplicateException();
      default:
        throw ForumApiException(
          response.statusCode,
          payload['error'] as String?,
        );
    }
  }

  @override
  Future<void> reportPost({
    required String deviceId,
    required String postId,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/functions/v1/forum/reports'),
        headers: _headers,
        body: jsonEncode({'device_id': deviceId, 'post_id': postId}),
      ),
    );
    if (response.statusCode != 200) {
      final payload = _decodeObject(response.body);
      throw ForumApiException(
        response.statusCode,
        payload['error'] as String?,
      );
    }
  }

  @override
  Future<void> deletePost({
    required String deviceId,
    required String postId,
  }) async {
    final response = await _send(
      () => _client.delete(
        Uri.parse('$_baseUrl/functions/v1/forum/posts/$postId'),
        headers: _headers,
        body: jsonEncode({'device_id': deviceId}),
      ),
    );
    if (response.statusCode != 200) {
      final payload = _decodeObject(response.body);
      throw ForumApiException(
        response.statusCode,
        payload['error'] as String?,
      );
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on http.ClientException {
      throw ForumOfflineException();
    } catch (e) {
      // dart:io's SocketException without importing dart:io (web-safe).
      if (e.toString().contains('SocketException')) {
        throw ForumOfflineException();
      }
      rethrow;
    }
  }

  Map<String, Object?> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } on FormatException {
      // fall through
    }
    return const {};
  }
}

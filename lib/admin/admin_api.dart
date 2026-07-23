import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:agrilumina/admin/admin_models.dart';
import 'package:agrilumina/services/forum_api.dart' show ForumConfig;

/// The backend did not respond in time or is unreachable.
class AdminOfflineException implements Exception {}

/// Invalid email/password (or the account lost admin rights).
class AdminAuthException implements Exception {
  const AdminAuthException([this.message = 'authentication failed']);

  final String message;
}

/// Any other non-success backend response.
class AdminApiException implements Exception {
  const AdminApiException(this.statusCode, [this.error]);

  final int statusCode;
  final String? error;

  @override
  String toString() => 'AdminApiException($statusCode, $error)';
}

class AdminSession {
  const AdminSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
  });

  final String accessToken;
  final String refreshToken;
  final String email;
}

/// Admin backend client: Supabase Auth (password grant) + PostgREST with the
/// admin JWT. Refresh tokens rotate — after every refresh the newest token is
/// reported through [onSessionChanged] so callers can persist it.
class AdminApi {
  AdminApi({
    http.Client? client,
    String? baseUrl,
    String? anonKey,
    Duration? timeout,
    this.onSessionChanged,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ForumConfig.supabaseUrl,
        _anonKey = anonKey ?? ForumConfig.anonKey,
        _timeout = timeout ?? _defaultTimeout;

  /// Requests with no response by this deadline surface as
  /// [AdminOfflineException] instead of hanging on a black-holing network.
  static const _defaultTimeout = Duration(seconds: 15);

  final http.Client _client;
  final String _baseUrl;
  final String _anonKey;
  final Duration _timeout;

  /// Called with the new session after login/refresh, null after logout.
  final void Function(AdminSession?)? onSessionChanged;

  AdminSession? session;

  // --- auth ---

  Future<AdminSession> login(String email, String password) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/auth/v1/token?grant_type=password'),
        headers: _baseHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    return _adoptSession(response, email: email);
  }

  /// Restores a session from a persisted refresh token.
  Future<AdminSession> refresh(String refreshToken) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/auth/v1/token?grant_type=refresh_token'),
        headers: _baseHeaders,
        body: jsonEncode({'refresh_token': refreshToken}),
      ),
    );
    return _adoptSession(response);
  }

  Future<void> logout() async {
    final current = session;
    session = null;
    onSessionChanged?.call(null);
    if (current == null) return;
    await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/auth/v1/logout'),
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer ${current.accessToken}',
        },
      ),
    );
  }

  AdminSession _adoptSession(http.Response response, {String? email}) {
    final payload = _decodeObject(response.body);
    if (response.statusCode != 200) {
      throw AdminAuthException(
        payload['error_description'] as String? ??
            payload['msg'] as String? ??
            'authentication failed',
      );
    }
    final user = payload['user'];
    final adopted = AdminSession(
      accessToken: payload['access_token'] as String? ?? '',
      refreshToken: payload['refresh_token'] as String? ?? '',
      email: email ??
          (user is Map ? user['email'] as String? ?? '' : session?.email ?? ''),
    );
    if (adopted.accessToken.isEmpty) throw const AdminAuthException();
    session = adopted;
    onSessionChanged?.call(adopted);
    return adopted;
  }

  // --- data ---

  Future<AdminStats> fetchStats() async {
    final body = await _rpc('admin_stats', {});
    final decoded = jsonDecode(body);
    if (decoded is! Map) throw const AdminApiException(200, 'bad_payload');
    return AdminStats.fromJson(Map<String, Object?>.from(decoded));
  }

  Future<List<AdminPost>> fetchPosts({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'select': '*',
      'order': 'created_at.desc',
      'limit': '$limit',
      'offset': '$offset',
      if (status != null) 'status': 'eq.$status',
    };
    final rows = await _getRows('forum_posts', params);
    return rows.map(AdminPost.fromJson).whereType<AdminPost>().toList();
  }

  Future<List<PostReport>> fetchPostReports(String postId) async {
    final rows = await _getRows('forum_reports', {
      'post_id': 'eq.$postId',
      'order': 'created_at.desc',
    });
    return rows.map(PostReport.fromJson).toList();
  }

  Future<AdminPost> setPostStatus(String postId, String status) async {
    final body = await _rpc(
      'admin_set_post_status',
      {'p_post_id': postId, 'p_status': status},
    );
    final decoded = jsonDecode(body);
    final post = decoded is Map
        ? AdminPost.fromJson(Map<String, Object?>.from(decoded))
        : null;
    if (post == null) throw const AdminApiException(200, 'bad_payload');
    return post;
  }

  Future<List<AdminListing>> fetchListings({
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _getRows('listings', {
      'select': '*',
      'order': 'updated_at.desc',
      'limit': '$limit',
      'offset': '$offset',
    });
    return rows.map(AdminListing.fromJson).whereType<AdminListing>().toList();
  }

  Future<void> deleteListing(String id) =>
      _mutate('DELETE', 'listings', filter: 'id=eq.$id');

  Future<List<BlocklistEntry>> fetchBlocklist() async {
    final rows = await _getRows('forum_blocklist', {'order': 'term'});
    return rows.map(BlocklistEntry.fromJson).toList();
  }

  Future<void> addBlocklistTerm(String term, int weight) => _mutate(
        'POST',
        'forum_blocklist',
        body: {'term': term, 'weight': weight},
      );

  Future<void> updateBlocklistEntry(
    int id, {
    bool? active,
    int? weight,
  }) =>
      _mutate('PATCH', 'forum_blocklist', filter: 'id=eq.$id', body: {
        'active': ?active,
        'weight': ?weight,
      });

  Future<void> deleteBlocklistEntry(int id) =>
      _mutate('DELETE', 'forum_blocklist', filter: 'id=eq.$id');

  Future<List<BannedDevice>> fetchBans() async {
    final rows =
        await _getRows('forum_banned_devices', {'order': 'created_at.desc'});
    return rows.map(BannedDevice.fromJson).toList();
  }

  Future<void> banDevice(String deviceId, String reason) => _mutate(
        'POST',
        'forum_banned_devices',
        body: {'device_id': deviceId, 'reason': reason},
      );

  Future<void> unbanDevice(String deviceId) => _mutate(
        'DELETE',
        'forum_banned_devices',
        filter: 'device_id=eq.$deviceId',
      );

  Future<List<AdminAlert>> fetchAlerts({int limit = 50}) async {
    final rows = await _getRows('admin_alerts', {
      'order': 'created_at.desc',
      'limit': '$limit',
    });
    return rows.map(AdminAlert.fromJson).toList();
  }

  Future<void> markAlertRead(int id) =>
      _mutate('PATCH', 'admin_alerts', filter: 'id=eq.$id', body: {
        'read': true,
      });

  Future<List<AlertRule>> fetchRules() async {
    final rows = await _getRows('admin_alert_rules', {'order': 'id'});
    return rows.map(AlertRule.fromJson).toList();
  }

  Future<void> updateRule(String id, {bool? enabled, int? threshold}) =>
      _mutate('PATCH', 'admin_alert_rules', filter: 'id=eq.$id', body: {
        'enabled': ?enabled,
        'threshold': ?threshold,
      });

  // --- plumbing ---

  Map<String, String> get _baseHeaders => {
        'apikey': _anonKey,
        'Content-Type': 'application/json',
      };

  Future<List<Map<String, Object?>>> _getRows(
    String table,
    Map<String, String> params,
  ) async {
    final uri =
        Uri.parse('$_baseUrl/rest/v1/$table').replace(queryParameters: params);
    final response = await _authed((headers) => _client.get(uri, headers: headers));
    if (response.statusCode != 200) {
      throw AdminApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const AdminApiException(200, 'bad_payload');
    return decoded
        .whereType<Map>()
        .map((m) => Map<String, Object?>.from(m))
        .toList();
  }

  Future<String> _rpc(String name, Map<String, Object?> args) async {
    final response = await _authed(
      (headers) => _client.post(
        Uri.parse('$_baseUrl/rest/v1/rpc/$name'),
        headers: headers,
        body: jsonEncode(args),
      ),
    );
    if (response.statusCode != 200) {
      throw AdminApiException(response.statusCode, response.body);
    }
    return response.body;
  }

  Future<void> _mutate(
    String method,
    String table, {
    String? filter,
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/rest/v1/$table${filter != null ? '?$filter' : ''}',
    );
    final response = await _authed((headers) {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      return _client.send(request).then(http.Response.fromStream);
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminApiException(response.statusCode, response.body);
    }
  }

  /// Sends a request with the session JWT; on 401, refreshes once and retries.
  Future<http.Response> _authed(
    Future<http.Response> Function(Map<String, String>) send,
  ) async {
    final current = session;
    if (current == null) throw const AdminAuthException('not signed in');
    var response = await _send(() => send({
          ..._baseHeaders,
          'Authorization': 'Bearer ${current.accessToken}',
        }));
    if (response.statusCode == 401) {
      final renewed = await refresh(current.refreshToken);
      response = await _send(() => send({
            ..._baseHeaders,
            'Authorization': 'Bearer ${renewed.accessToken}',
          }));
    }
    return response;
  }

  /// Applies the request deadline; a hung request surfaces as a
  /// connectivity error instead of blocking forever.
  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw AdminOfflineException();
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

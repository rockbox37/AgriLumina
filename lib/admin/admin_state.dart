import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/admin/admin_api.dart';
import 'package:agrilumina/admin/admin_models.dart';

/// Session + shared dashboard state for the admin app.
class AdminState extends ChangeNotifier {
  AdminState({AdminApi? api, SharedPreferences? prefs}) : _prefs = prefs {
    _api = api ?? AdminApi(onSessionChanged: _persistSession);
    // An injected api (tests) may not report through the callback; adopt its
    // session directly.
    if (api != null && api.session != null) {
      _signedIn = true;
    }
  }

  static const _kRefreshToken = 'admin.refreshToken';
  static const _kEmail = 'admin.email';

  late final AdminApi _api;
  final SharedPreferences? _prefs;

  AdminApi get api => _api;

  bool _signedIn = false;
  bool restoring = false;
  AdminStats? stats;

  bool get signedIn => _signedIn;
  String get email => _api.session?.email ?? '';
  int get unreadAlerts => stats?.unreadAlerts ?? 0;

  void _persistSession(AdminSession? session) {
    final prefs = _prefs;
    if (prefs == null) return;
    if (session == null) {
      prefs.remove(_kRefreshToken);
      prefs.remove(_kEmail);
    } else {
      prefs.setString(_kRefreshToken, session.refreshToken);
      prefs.setString(_kEmail, session.email);
    }
  }

  /// Attempts silent sign-in from a persisted refresh token.
  Future<void> restoreSession() async {
    final token = _prefs?.getString(_kRefreshToken);
    if (token == null || token.isEmpty) return;
    restoring = true;
    notifyListeners();
    try {
      await _api.refresh(token);
      _signedIn = true;
      await refreshStats();
    } on Exception {
      _persistSession(null);
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await _api.login(email, password);
    _signedIn = true;
    notifyListeners();
    await refreshStats();
  }

  Future<void> logout() async {
    await _api.logout();
    _signedIn = false;
    stats = null;
    notifyListeners();
  }

  Future<void> refreshStats() async {
    try {
      stats = await _api.fetchStats();
    } on AdminAuthException {
      _signedIn = false;
      stats = null;
    }
    notifyListeners();
  }
}

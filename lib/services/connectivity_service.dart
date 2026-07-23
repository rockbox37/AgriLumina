import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Emits when the device transitions from offline to online, so queued work
/// (listing sync, forum outbox) can flush without waiting for a user action.
abstract class ConnectivityService {
  Stream<void> get onReconnected;

  void dispose() {}
}

/// connectivity_plus-backed implementation. Emits only offline→online edges
/// (seeded as "online" so app start doesn't double-fire next to the explicit
/// start-time flush) and swallows platform errors.
class PluginConnectivityService implements ConnectivityService {
  PluginConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        final online = results.any((r) => r != ConnectivityResult.none);
        if (online && !_wasOnline) {
          _controller.add(null);
        }
        _wasOnline = online;
      },
      onError: (_) {},
    );
  }

  final _controller = StreamController<void>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOnline = true;

  @override
  Stream<void> get onReconnected => _controller.stream;

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

import 'dart:async';

import 'package:agrilumina/services/connectivity_service.dart';

/// Test double: emit reconnection events on demand.
class FakeConnectivityService implements ConnectivityService {
  final _controller = StreamController<void>.broadcast();

  bool disposed = false;

  void emitReconnected() => _controller.add(null);

  @override
  Stream<void> get onReconnected => _controller.stream;

  @override
  void dispose() {
    // Keep the controller open so tests can emit after dispose and assert
    // the (cancelled) subscription no longer reacts.
    disposed = true;
  }
}

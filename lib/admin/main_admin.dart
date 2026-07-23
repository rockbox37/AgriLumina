import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/admin/admin_state.dart';
import 'package:agrilumina/admin/url_strategy_stub.dart'
    if (dart.library.js_interop) 'package:agrilumina/admin/url_strategy_web.dart';
import 'package:agrilumina/admin/screens/admin_login_screen.dart';
import 'package:agrilumina/admin/screens/admin_shell.dart';

/// AgriLumina platform-admin dashboard (Flutter Web).
///
/// Run with:
///   flutter run -d web-server --web-port 8088 --target lib/admin/main_admin.dart
Future<void> main() async {
  disableUrlHistory();
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final state = AdminState(prefs: prefs);
  await state.restoreSession();
  runApp(AdminApp(state: state));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return AdminStateScope(
      state: state,
      child: MaterialApp(
        title: 'AgriLumina Admin',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            if (state.restoring) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return state.signedIn
                ? const AdminShell()
                : const AdminLoginScreen();
          },
        ),
      ),
    );
  }
}

/// Provides [AdminState] to the widget tree.
class AdminStateScope extends InheritedNotifier<AdminState> {
  const AdminStateScope({
    super.key,
    required AdminState state,
    required super.child,
  }) : super(notifier: state);

  static AdminState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AdminStateScope>();
    assert(scope != null, 'AdminStateScope not found in context');
    return scope!.notifier!;
  }
}

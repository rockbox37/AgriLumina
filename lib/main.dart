import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/screens/app_shell.dart';
import 'package:agrilumina/services/location_service.dart';

void main() {
  runApp(const AgriluminaApp());
}

class AgriluminaApp extends StatefulWidget {
  const AgriluminaApp({super.key, this.locationService});

  /// Optional override for tests (avoids real GPS / platform channels).
  final LocationService? locationService;

  @override
  State<AgriluminaApp> createState() => _AgriluminaAppState();
}

class _AgriluminaAppState extends State<AgriluminaApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState(locationService: widget.locationService);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: MaterialApp(
        title: 'AgriLumina',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}

/// Kept for existing tests / hot-reload entry naming.
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.locationService});

  final LocationService? locationService;

  @override
  Widget build(BuildContext context) =>
      AgriluminaApp(locationService: locationService);
}

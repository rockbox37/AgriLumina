import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/app_localizations.dart';
import 'package:agrilumina/screens/app_shell.dart';
import 'package:agrilumina/services/location_service.dart';

void main() {
  runApp(const AgriluminaApp());
}

class AgriluminaApp extends StatefulWidget {
  const AgriluminaApp({super.key, this.locationService, this.locale});

  /// Optional override for tests (avoids real GPS / platform channels).
  final LocationService? locationService;

  /// Optional locale override for tests.
  final Locale? locale;

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
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        locale: widget.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supported) {
          if (locale == null) return const Locale('en');
          for (final candidate in supported) {
            if (candidate.languageCode == locale.languageCode) {
              return candidate;
            }
          }
          return const Locale('en');
        },
        home: const AppShell(),
      ),
    );
  }
}

/// Kept for existing tests / hot-reload entry naming.
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.locationService, this.locale});

  final LocationService? locationService;
  final Locale? locale;

  @override
  Widget build(BuildContext context) => AgriluminaApp(
        locationService: locationService,
        locale: locale,
      );
}

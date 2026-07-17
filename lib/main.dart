import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/app_localizations.dart';
import 'package:agrilumina/screens/app_shell.dart';
import 'package:agrilumina/screens/splash_screen.dart';
import 'package:agrilumina/services/local_state_store.dart';
import 'package:agrilumina/services/location_service.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  final store = await LocalStateStore.open();
  runApp(AgriluminaApp(stateStore: store));
}

class AgriluminaApp extends StatefulWidget {
  const AgriluminaApp({
    super.key,
    this.locationService,
    this.stateStore,
    this.locale,
    this.showSplash = true,
    this.removeNativeSplash = true,
  });

  /// Optional override for tests (avoids real GPS / platform channels).
  final LocationService? locationService;

  /// When set, MVP fields load from / save to this store.
  final LocalStateStore? stateStore;

  /// Optional locale override for tests.
  final Locale? locale;

  /// When false, skips the branded splash and opens the shell immediately.
  final bool showSplash;

  /// When false (widget tests), skips [FlutterNativeSplash.remove].
  final bool removeNativeSplash;

  @override
  State<AgriluminaApp> createState() => _AgriluminaAppState();
}

class _AgriluminaAppState extends State<AgriluminaApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    final store = widget.stateStore;
    _state = store != null
        ? AppState.fromStore(store, locationService: widget.locationService)
        : AppState(locationService: widget.locationService);
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
        home: widget.showSplash
            ? SplashScreen(removeNativeSplash: widget.removeNativeSplash)
            : const AppShell(),
      ),
    );
  }
}

/// Kept for existing tests / hot-reload entry naming.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.locationService,
    this.stateStore,
    this.locale,
    this.showSplash = false,
    this.removeNativeSplash = false,
  });

  final LocationService? locationService;
  final LocalStateStore? stateStore;
  final Locale? locale;

  /// Tests default to skipping the timed splash for speed / stability.
  final bool showSplash;

  final bool removeNativeSplash;

  @override
  Widget build(BuildContext context) => AgriluminaApp(
        locationService: locationService,
        stateStore: stateStore,
        locale: locale,
        showSplash: showSplash,
        removeNativeSplash: removeNativeSplash,
      );
}

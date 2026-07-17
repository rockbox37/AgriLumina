import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:agrilumina/screens/app_shell.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

/// Branded Flutter splash shown after the native splash, then [AppShell].
///
/// Matches the native splash (white field + logo) so the handoff does not flash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1200),
    this.removeNativeSplash = true,
  });

  /// How long to keep the Flutter splash visible after the first frame.
  final Duration duration;

  /// When false (e.g. widget tests), skips [FlutterNativeSplash.remove].
  final bool removeNativeSplash;

  static const Key logoKey = Key('splash_brand_logo');

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.removeNativeSplash) {
        FlutterNativeSplash.remove();
      }
      _timer = Timer(widget.duration, () {
        if (!mounted) return;
        setState(() => _ready = true);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const AppShell();

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: BrandLogo(
          key: SplashScreen.logoKey,
          height: 140,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';

/// Shared AgriLumina brand assets for app chrome.
class BrandAssets {
  BrandAssets._();

  static const logo = 'assets/branding/agrilumina_logo.png';
  static const icon = 'assets/branding/agrilumina_icon.png';
}

/// Wordmark + emblem for app bars and home brand placement.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 36,
    this.semanticLabel = 'AgriLumina',
  });

  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        BrandAssets.logo,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// Emblem-only mark (transparent PNG; works on light surfaces).
class BrandIcon extends StatelessWidget {
  const BrandIcon({
    super.key,
    this.size = 40,
    this.semanticLabel = 'AgriLumina',
  });

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        BrandAssets.icon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// App-bar leading emblem that navigates to the Home tab (shell index 0).
///
/// On pushed routes (e.g. listing detail), pops to the shell root first, then
/// selects Home. When already on Home with nothing to pop, the tap is a no-op.
class BrandHomeLeading extends StatelessWidget {
  const BrandHomeLeading({super.key, this.iconSize = 28});

  static const Key buttonKey = Key('app_bar_home_brand');

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      tooltip: 'Home',
      onPressed: () => navigateToAppHome(context),
      icon: BrandIcon(size: iconSize, semanticLabel: 'AgriLumina home'),
    );
  }
}

/// Pops nested routes to the shell, then selects the Home tab.
void navigateToAppHome(BuildContext context) {
  final state = AppStateScope.of(context);
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
  }
  state.goToTab(AppState.homeTabIndex);
}

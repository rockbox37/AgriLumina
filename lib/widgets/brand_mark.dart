import 'package:flutter/material.dart';

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
    this.semanticLabel = 'Agrilumina',
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
    this.semanticLabel = 'Agrilumina',
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

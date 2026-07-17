import 'package:agrilumina/l10n/app_localizations.dart';
import 'package:agrilumina/utils/geo.dart';
import 'package:intl/intl.dart';

/// Locale-aware display helpers.
///
/// **Units strategy (MVP):** distances are always shown in kilometers (`km`)
/// for every locale. Mile conversion can be added later per-region preference.
/// Quantity strings on listings remain free-text content (not unit-converted).
String formatDistanceKmLocalized(
  AppLocalizations l10n,
  double km, {
  String? localeName,
}) {
  final locale = localeName ?? l10n.localeName;
  final formatted = NumberFormat('#0.0', locale).format(roundKm(km));
  return l10n.distanceKm(formatted);
}

/// Formats an integer with locale-aware grouping separators.
String formatIntLocalized(int value, String localeName) {
  return NumberFormat.decimalPattern(localeName).format(value);
}

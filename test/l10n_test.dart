import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/main.dart';
import 'package:agrilumina/utils/locale_format.dart';

import 'fake_location_service.dart';

void main() {
  test('English is the fallback locale for unsupported languages', () {
    final resolved = _resolve(const Locale('sw'));
    expect(resolved.languageCode, 'en');
  });

  test('French locale loads translated Discover title', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.findBuyers, 'Trouver des acheteurs');
    expect(fr.navHome, 'Accueil');
    expect(fr.appTitle, 'AgriLumina');
  });

  test('resolvedDisplayName localizes unset and legacy You seed', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(en.resolvedDisplayName(''), 'You');
    expect(en.resolvedDisplayName('You'), 'You');
    expect(fr.resolvedDisplayName(''), 'Vous');
    expect(fr.resolvedDisplayName('You'), 'Vous');
    expect(fr.resolvedDisplayName('Marie'), 'Marie');
  });

  test('resolvedLocation localizes unset and legacy Not set seed', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(en.resolvedLocation(''), 'Not set');
    expect(en.resolvedLocation('Not set'), 'Not set');
    expect(fr.resolvedLocation(''), 'Non défini');
    expect(fr.resolvedLocation('Not set'), 'Non défini');
    expect(fr.resolvedLocation('Kabare'), 'Kabare');
  });

  test('formatDistanceKmLocalized uses locale decimal separators', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(formatDistanceKmLocalized(en, 3.2), '3.2 km');
    expect(formatDistanceKmLocalized(fr, 3.2), '3,2 km');
  });

  testWidgets('French smoke path: Home + Discover unlock chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        locationService: FakeLocationService(),
        locale: const Locale('fr'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Bienvenue, Vous'), findsOneWidget);
    expect(find.text('Je suis…'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Non défini'), findsOneWidget);

    await tester.tap(find.text('Découvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Trouver des acheteurs'), findsOneWidget);

    await tester.tap(find.text('Jean-Pierre M.'));
    await tester.pumpAndSettle();

    expect(find.textContaining('crédit'), findsWidgets);
  });
}

Locale _resolve(Locale? locale) {
  const supported = AppLocalizations.supportedLocales;
  if (locale == null) return const Locale('en');
  for (final candidate in supported) {
    if (candidate.languageCode == locale.languageCode) {
      return candidate;
    }
  }
  return const Locale('en');
}

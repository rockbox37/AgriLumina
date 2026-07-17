import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS InfoPlist.strings localize location usage description', () {
    final en = File('ios/Runner/en.lproj/InfoPlist.strings').readAsStringSync();
    final fr = File('ios/Runner/fr.lproj/InfoPlist.strings').readAsStringSync();

    expect(en, contains('NSLocationWhenInUseUsageDescription'));
    expect(
      en,
      contains(
        'AgriLumina uses your location to show nearby buyers and sellers around you.',
      ),
    );

    expect(fr, contains('NSLocationWhenInUseUsageDescription'));
    expect(
      fr,
      contains(
        'AgriLumina utilise votre position pour afficher les acheteurs et vendeurs à proximité.',
      ),
    );
  });

  test('Info.plist declares en and fr localizations', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>CFBundleLocalizations</key>'));
    expect(plist, contains('<string>en</string>'));
    expect(plist, contains('<string>fr</string>'));
  });
}

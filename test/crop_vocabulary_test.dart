import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';

void main() {
  group('normalizeCropDisplayName', () {
    test('trims, collapses spaces, and title-cases', () {
      expect(normalizeCropDisplayName('  heirloom   tomato '), 'Heirloom Tomato');
      expect(normalizeCropDisplayName('MAIZE'), 'Maize');
    });

    test('empty and whitespace-only become empty', () {
      expect(normalizeCropDisplayName(''), '');
      expect(normalizeCropDisplayName('   '), '');
    });
  });

  group('matchCanonicalCrop', () {
    test('matches vocabulary case-insensitively', () {
      expect(matchCanonicalCrop('maize'), 'Maize');
      expect(matchCanonicalCrop('Beans'), 'Beans');
    });

    test('resolves aliases including French labels', () {
      expect(matchCanonicalCrop('corn'), 'Maize');
      expect(matchCanonicalCrop('manioc'), 'Cassava');
      expect(matchCanonicalCrop('haricots'), 'Beans');
      expect(matchCanonicalCrop('arachides'), 'Groundnuts');
      expect(matchCanonicalCrop('riz'), 'Rice');
    });

    test('returns null for unknown produce', () {
      expect(matchCanonicalCrop('Tomato'), isNull);
      expect(matchCanonicalCrop(''), isNull);
    });
  });

  group('suggestCanonicalCrop', () {
    test('suggests near duplicates / typos', () {
      expect(suggestCanonicalCrop('Maiz'), 'Maize');
      expect(suggestCanonicalCrop('Beens'), 'Beans');
    });

    test('null when already canonical or unrelated', () {
      expect(suggestCanonicalCrop('Maize'), isNull);
      expect(suggestCanonicalCrop('corn'), isNull);
      expect(suggestCanonicalCrop('Tomato'), isNull);
    });
  });

  group('resolveCropInterestId', () {
    test('prefers canonical over typed variant', () {
      expect(resolveCropInterestId('corn'), 'Maize');
      expect(resolveCropInterestId('MAIZE'), 'Maize');
    });

    test('keeps normalized custom when no match', () {
      expect(resolveCropInterestId('heirloom tomato'), 'Heirloom Tomato');
      expect(resolveCropInterestId('  '), isNull);
    });
  });

  group('cropFilterChipsFor', () {
    test('appends custom interests after vocabulary', () {
      expect(
        cropFilterChipsFor(const ['Maize', 'Tomato', 'Beans']),
        ['Maize', 'Cassava', 'Beans', 'Groundnuts', 'Rice', 'Tomato'],
      );
    });
  });
}

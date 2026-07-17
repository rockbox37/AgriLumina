import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/utils/crop_filter.dart';

Listing _listing(String name, String crop) {
  return Listing(
    id: name,
    name: name,
    role: UserRole.buyer,
    crop: crop,
    quantityHint: 'hint',
    distanceKm: 1,
    latitude: 0,
    longitude: 0,
    location: 'here',
    lastActiveLabel: 'today',
    phone: '+243 000',
  );
}

void main() {
  final listings = [
    _listing('Jean', 'Maize'),
    _listing('Amina', 'Cassava'),
    _listing('Patrick', 'Beans'),
  ];

  group('filterListingsByCrop', () {
    test('manual crop overrides interests', () {
      final filtered = filterListingsByCrop(
        listings: listings,
        mode: DiscoverCropMode.manualCrop,
        manualCrop: 'Cassava',
        relevantInterests: const ['Maize'],
      );
      expect(filtered.map((l) => l.name), ['Amina']);
    });

    test('soft interest OR-filters when list non-empty', () {
      final filtered = filterListingsByCrop(
        listings: listings,
        mode: DiscoverCropMode.softInterest,
        manualCrop: null,
        relevantInterests: const ['Maize', 'Beans'],
      );
      expect(filtered.map((l) => l.name), ['Jean', 'Patrick']);
    });

    test('soft interest with empty list shows all', () {
      final filtered = filterListingsByCrop(
        listings: listings,
        mode: DiscoverCropMode.softInterest,
        manualCrop: null,
        relevantInterests: const [],
      );
      expect(filtered, same(listings));
    });

    test('showAll ignores interests', () {
      final filtered = filterListingsByCrop(
        listings: listings,
        mode: DiscoverCropMode.showAll,
        manualCrop: null,
        relevantInterests: const ['Maize'],
      );
      expect(filtered, same(listings));
    });
  });

  group('isInterestSoftFilterActive', () {
    test('true only for soft mode with non-empty interests', () {
      expect(
        isInterestSoftFilterActive(
          mode: DiscoverCropMode.softInterest,
          relevantInterests: const ['Maize'],
        ),
        isTrue,
      );
      expect(
        isInterestSoftFilterActive(
          mode: DiscoverCropMode.softInterest,
          relevantInterests: const [],
        ),
        isFalse,
      );
      expect(
        isInterestSoftFilterActive(
          mode: DiscoverCropMode.showAll,
          relevantInterests: const ['Maize'],
        ),
        isFalse,
      );
    });
  });

  group('interestFilterHelperText', () {
    test('matches role', () {
      expect(
        interestFilterHelperText(UserRole.seller),
        'Showing crops you sell',
      );
      expect(
        interestFilterHelperText(UserRole.buyer),
        'Showing crops you buy',
      );
    });
  });
}

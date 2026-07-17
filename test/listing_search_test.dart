import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/utils/listing_search.dart';

Listing _listing({
  String name = 'Jean-Pierre M.',
  String crop = 'Maize',
  String location = 'Village market',
  String quantityHint = 'Buying up to 2 tonnes',
  String phone = '+243 970 111 201',
}) {
  return Listing(
    id: 't1',
    name: name,
    role: UserRole.buyer,
    crop: crop,
    quantityHint: quantityHint,
    distanceKm: 1,
    latitude: 0,
    longitude: 0,
    location: location,
    lastActiveLabel: 'Active today',
    phone: phone,
  );
}

void main() {
  group('listingMatchesQuery', () {
    test('empty or whitespace query matches everything', () {
      final listing = _listing();
      expect(listingMatchesQuery(listing, ''), isTrue);
      expect(listingMatchesQuery(listing, '   '), isTrue);
    });

    test('matches name case-insensitively', () {
      final listing = _listing(name: 'Jean-Pierre M.');
      expect(listingMatchesQuery(listing, 'jean'), isTrue);
      expect(listingMatchesQuery(listing, 'PIERRE'), isTrue);
      expect(listingMatchesQuery(listing, 'amina'), isFalse);
    });

    test('matches crop, location, and quantityHint', () {
      final listing = _listing(
        crop: 'Cassava',
        location: 'Kabare',
        quantityHint: 'Needs 500 kg this week',
      );
      expect(listingMatchesQuery(listing, 'cassava'), isTrue);
      expect(listingMatchesQuery(listing, 'kabare'), isTrue);
      expect(listingMatchesQuery(listing, '500 kg'), isTrue);
      expect(listingMatchesQuery(listing, 'tonnes'), isFalse);
    });

    test('does not match phone', () {
      final listing = _listing(phone: '+243 970 111 201');
      expect(listingMatchesQuery(listing, '970'), isFalse);
      expect(listingMatchesQuery(listing, '+243'), isFalse);
    });
  });

  group('filterListingsByQuery', () {
    final listings = [
      _listing(name: 'Jean-Pierre M.', crop: 'Maize', location: 'Village market'),
      _listing(name: 'Amina K.', crop: 'Cassava', location: 'Near village'),
      _listing(name: 'Grace Trading', crop: 'Maize', location: 'Kabare'),
    ];

    test('empty query returns same list', () {
      expect(filterListingsByQuery(listings, ''), same(listings));
      expect(filterListingsByQuery(listings, '  '), same(listings));
    });

    test('narrows by substring across fields', () {
      final byLocation = filterListingsByQuery(listings, 'Kabare');
      expect(byLocation.map((l) => l.name), ['Grace Trading']);

      final byCrop = filterListingsByQuery(listings, 'maize');
      expect(byCrop.map((l) => l.name), ['Jean-Pierre M.', 'Grace Trading']);
    });
  });
}

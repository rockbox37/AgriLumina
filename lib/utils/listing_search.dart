import 'package:agrilumina/models/listing.dart';

/// Case-insensitive substring match over listing fields used by Discover search.
///
/// Matches [Listing.name], [Listing.crop], [Listing.location], and
/// [Listing.quantityHint]. Does not match [Listing.phone] (privacy/noise).
bool listingMatchesQuery(Listing listing, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  return listing.name.toLowerCase().contains(q) ||
      listing.crop.toLowerCase().contains(q) ||
      listing.location.toLowerCase().contains(q) ||
      listing.quantityHint.toLowerCase().contains(q);
}

/// Narrows [listings] by [query]. Empty/whitespace query returns [listings] unchanged.
List<Listing> filterListingsByQuery(List<Listing> listings, String query) {
  final q = query.trim();
  if (q.isEmpty) return listings;
  return listings.where((l) => listingMatchesQuery(l, q)).toList();
}

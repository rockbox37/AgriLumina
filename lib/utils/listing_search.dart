import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/models/listing.dart';

/// Case-insensitive substring match over listing fields used by Discover search.
///
/// Matches name plus crop/place/quantity in both canonical English keys and
/// localized labels (when [l10n] is provided). Does not match phone.
bool listingMatchesQuery(
  Listing listing,
  String query, {
  AppLocalizations? l10n,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  bool hit(String value) => value.toLowerCase().contains(q);

  if (hit(listing.name) ||
      hit(listing.crop) ||
      hit(listing.location) ||
      hit(listing.quantityHint)) {
    return true;
  }

  if (l10n == null) return false;

  return hit(l10n.localizedCrop(listing.crop)) ||
      hit(l10n.localizedPlace(listing.location)) ||
      hit(l10n.localizedQuantity(listing.quantityHint)) ||
      hit(l10n.localizedLastActive(listing.lastActiveLabel));
}

/// Narrows [listings] by [query]. Empty/whitespace query returns [listings] unchanged.
List<Listing> filterListingsByQuery(
  List<Listing> listings,
  String query, {
  AppLocalizations? l10n,
}) {
  final q = query.trim();
  if (q.isEmpty) return listings;
  return listings.where((l) => listingMatchesQuery(l, q, l10n: l10n)).toList();
}

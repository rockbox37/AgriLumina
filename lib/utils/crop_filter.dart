import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';

/// How Discover applies crop filtering relative to interests and chips.
enum DiscoverCropMode {
  /// Soft-filter by the role-relevant interest list (or all if empty).
  softInterest,

  /// Explicit "All" — show every counterpart; interest soft-filter off.
  showAll,

  /// Manual single-crop chip override.
  manualCrop,
}

/// Narrows counterpart [listings] using the locked Discover crop algorithm.
///
/// Order: manual chip → relevant-interest OR-filter → all counterparts.
List<Listing> filterListingsByCrop({
  required List<Listing> listings,
  required DiscoverCropMode mode,
  String? manualCrop,
  required List<String> relevantInterests,
}) {
  switch (mode) {
    case DiscoverCropMode.manualCrop:
      final crop = manualCrop;
      if (crop == null) return listings;
      return listings.where((l) => l.crop == crop).toList();
    case DiscoverCropMode.showAll:
      return listings;
    case DiscoverCropMode.softInterest:
      if (relevantInterests.isEmpty) return listings;
      return listings
          .where((l) => relevantInterests.contains(l.crop))
          .toList();
  }
}

/// True when the interest OR-filter is actively narrowing results.
bool isInterestSoftFilterActive({
  required DiscoverCropMode mode,
  required List<String> relevantInterests,
}) {
  return mode == DiscoverCropMode.softInterest && relevantInterests.isNotEmpty;
}

/// Helper copy when the interest soft-filter is active.
String interestFilterHelperText(UserRole role) {
  return role == UserRole.seller
      ? 'Showing crops you sell'
      : 'Showing crops you buy';
}

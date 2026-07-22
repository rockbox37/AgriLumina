/// Canonical English seed keys stored on [Listing] fields.
///
/// Display via [AppLocalizations] extensions; keys stay stable for filtering
/// and matching. Proper nouns (Kabare, Katana, person names) are not keyed.
abstract final class ListingCopyKeys {
  static const qtyBuyingUpTo2Tonnes = 'Buying up to 2 tonnes';
  static const qtyWeeklyBuyerBags = 'Weekly buyer · bags';
  static const qtyAggregatorFairPrice = 'Aggregator · fair price';
  static const qtyNeeds500KgThisWeek = 'Needs 500 kg this week';
  static const qtySmallLotsWelcome = 'Small lots welcome';
  static const qty800KgReady = '~800 kg ready';
  static const qtyFreshHarvest = 'Fresh harvest';
  static const qty10Bags = '10 bags';
  static const qty1_5Tonnes = '1.5 tonnes';
  static const qtySmallSurplus = 'Small surplus';

  static const placeVillageMarket = 'Village market';
  static const placeNearVillage = 'Near village';
  static const placeKaleheRoad = 'Kalehe road';
  static const placeVillage = 'Village';
  static const placeNearbyHills = 'Nearby hills';
  static const placeNearKalehe = 'Near Kalehe';

  static const activeToday = 'Active today';
  static const activeYesterday = 'Active yesterday';
  static const active2DaysAgo = 'Active 2 days ago';
  static const active3DaysAgo = 'Active 3 days ago';
  static const activeThisWeek = 'Active this week';
}

/// Buckets a remote listing's server-side update time into a last-active
/// copy key, by calendar-day difference (so 23:50 yesterday is "yesterday"
/// even if less than 24h ago).
String lastActiveKeyFor(DateTime updatedAt, DateTime now) {
  final updatedDay = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(updatedDay).inDays;
  if (days <= 0) return ListingCopyKeys.activeToday;
  if (days == 1) return ListingCopyKeys.activeYesterday;
  if (days == 2) return ListingCopyKeys.active2DaysAgo;
  if (days == 3) return ListingCopyKeys.active3DaysAgo;
  return ListingCopyKeys.activeThisWeek;
}

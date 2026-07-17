import 'package:agrilumina/data/listing_copy_keys.dart';
import 'package:agrilumina/l10n/app_localizations.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:flutter/widgets.dart';

export 'package:agrilumina/l10n/app_localizations.dart';

extension AppLocalizationsX on AppLocalizations {
  /// Profile display name, or the localized seed default when unset.
  ///
  /// Treats legacy English seed `"You"` as unset so locales show
  /// [defaultDisplayName] (e.g. French `"Vous"`).
  String resolvedDisplayName(String stored) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty || trimmed == 'You') {
      return defaultDisplayName;
    }
    return trimmed;
  }

  /// Profile location, or the localized seed default when unset.
  ///
  /// Treats legacy English seed `"Not set"` as unset so locales show
  /// [defaultLocation] (e.g. French `"Non défini"`).
  String resolvedLocation(String stored) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty || trimmed == 'Not set') {
      return defaultLocation;
    }
    return trimmed;
  }

  /// Localized crop label for a canonical English vocabulary key.
  String localizedCrop(String cropKey) => switch (cropKey) {
        'Maize' => cropMaize,
        'Cassava' => cropCassava,
        'Beans' => cropBeans,
        'Groundnuts' => cropGroundnuts,
        'Rice' => cropRice,
        _ => cropKey,
      };

  String localizedQuantity(String key) => switch (key) {
        ListingCopyKeys.qtyBuyingUpTo2Tonnes => qtyBuyingUpTo2Tonnes,
        ListingCopyKeys.qtyWeeklyBuyerBags => qtyWeeklyBuyerBags,
        ListingCopyKeys.qtyAggregatorFairPrice => qtyAggregatorFairPrice,
        ListingCopyKeys.qtyNeeds500KgThisWeek => qtyNeeds500KgThisWeek,
        ListingCopyKeys.qtySmallLotsWelcome => qtySmallLotsWelcome,
        ListingCopyKeys.qty800KgReady => qty800KgReady,
        ListingCopyKeys.qtyFreshHarvest => qtyFreshHarvest,
        ListingCopyKeys.qty10Bags => qty10Bags,
        ListingCopyKeys.qty1_5Tonnes => qty1_5Tonnes,
        ListingCopyKeys.qtySmallSurplus => qtySmallSurplus,
        _ => key,
      };

  String localizedPlace(String key) => switch (key) {
        ListingCopyKeys.placeVillageMarket => placeVillageMarket,
        ListingCopyKeys.placeNearVillage => placeNearVillage,
        ListingCopyKeys.placeKaleheRoad => placeKaleheRoad,
        ListingCopyKeys.placeVillage => placeVillage,
        ListingCopyKeys.placeNearbyHills => placeNearbyHills,
        ListingCopyKeys.placeNearKalehe => placeNearKalehe,
        _ => key, // proper nouns (Kabare, Katana, …)
      };

  String localizedLastActive(String key) => switch (key) {
        ListingCopyKeys.activeToday => activeToday,
        ListingCopyKeys.activeYesterday => activeYesterday,
        ListingCopyKeys.active2DaysAgo => active2DaysAgo,
        ListingCopyKeys.active3DaysAgo => active3DaysAgo,
        ListingCopyKeys.activeThisWeek => activeThisWeek,
        _ => key,
      };

  String localizedListingQuantity(Listing listing) =>
      localizedQuantity(listing.quantityHint);

  String localizedListingPlace(Listing listing) =>
      listing.location.trim().isEmpty
          ? defaultLocation
          : localizedPlace(listing.location);

  String localizedListingLastActive(Listing listing) =>
      localizedLastActive(listing.lastActiveLabel);

  /// Display name for a listing; resolves locale default for empty/mine names.
  String listingDisplayName(Listing listing) {
    if (listing.isMine) return resolvedDisplayName(listing.name);
    return listing.name;
  }

  String roleLabel(UserRole role) => switch (role) {
        UserRole.seller => roleSeller,
        UserRole.buyer => roleBuyer,
      };

  /// Plural counterpart label for Discover/Home copy (lowercase style).
  String counterpartPlural(UserRole role) => switch (role.counterpart) {
        UserRole.buyer => buyers,
        UserRole.seller => sellers,
      };

  String interestFilterHelper(UserRole role) => role == UserRole.seller
      ? showingCropsYouSell
      : showingCropsYouBuy;

  String locationBannerForStatus(LocationFetchStatus status) =>
      switch (status) {
        LocationFetchStatus.success => sampleListingsEnableLocation,
        LocationFetchStatus.denied => locationPermissionDenied,
        LocationFetchStatus.serviceDisabled => locationServicesOff,
        LocationFetchStatus.unsupported => locationUnsupported,
        LocationFetchStatus.error => locationReadError,
      };
}

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

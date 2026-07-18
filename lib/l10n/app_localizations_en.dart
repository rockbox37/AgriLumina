// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AgriLumina';

  @override
  String get navHome => 'Home';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navCredits => 'Credits';

  @override
  String get navProfile => 'Profile';

  @override
  String get brandHomeTooltip => 'Home';

  @override
  String get brandHomeSemantics => 'AgriLumina home';

  @override
  String creditsCount(int count) {
    return '$count credits';
  }

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String findNearbyByDistance(String counterpart) {
    return 'Find nearby $counterpart by distance.';
  }

  @override
  String get buyers => 'buyers';

  @override
  String get sellers => 'sellers';

  @override
  String get iAmA => 'I am a…';

  @override
  String get browsingAs => 'Browsing as…';

  @override
  String get enabledRolesLabel => 'I can…';

  @override
  String get rolesRequired => 'Select at least one role.';

  @override
  String get roleSeller => 'Seller';

  @override
  String get roleBuyer => 'Buyer';

  @override
  String nearbyCount(int count, String counterpart) {
    return '$count nearby $counterpart';
  }

  @override
  String get noMatchesInSeedData => 'No matches in seed data yet';

  @override
  String closestListing(String name, String distance) {
    return 'Closest: $name · $distance';
  }

  @override
  String spendCreditToUnlock(int cost) {
    return 'Spend $cost credit to unlock a phone number.';
  }

  @override
  String get findBuyers => 'Find Buyers';

  @override
  String get findSellers => 'Find Sellers';

  @override
  String get refreshLocation => 'Refresh location';

  @override
  String get filterAll => 'All';

  @override
  String get showingCropsYouSell => 'Showing crops you sell';

  @override
  String get showingCropsYouBuy => 'Showing crops you buy';

  @override
  String searchCounterparts(String counterpart) {
    return 'Search $counterpart';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String noCounterpartsNearbyYet(String counterpart) {
    return 'No $counterpart nearby yet.';
  }

  @override
  String noCropCounterpartsNearby(String crop, String counterpart) {
    return 'No $crop $counterpart nearby.';
  }

  @override
  String noCounterpartsForInterests(String counterpart) {
    return 'No $counterpart nearby for your interests.';
  }

  @override
  String noCounterpartsNearby(String counterpart) {
    return 'No $counterpart nearby.';
  }

  @override
  String noSearchMatches(String query, String scope) {
    return 'No matches for \"$query\" among $scope.';
  }

  @override
  String nearYouBanner(String label) {
    return 'Near you · $label';
  }

  @override
  String get sampleListingsEnableLocation =>
      'Sample listings · enable location for nearby distances';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. Showing distances from sample listings.';

  @override
  String get locationServicesOff =>
      'Location services are off. Showing distances from sample listings.';

  @override
  String get locationUnsupported =>
      'GPS is not available on this device. Showing distances from sample listings.';

  @override
  String get locationReadError =>
      'Could not read location. Showing distances from sample listings.';

  @override
  String get sampleArea => 'Sample area';

  @override
  String get nearSampleArea => 'Near sample area';

  @override
  String get yourCurrentLocation => 'Your current location';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String get listingTitle => 'Listing';

  @override
  String get listingNotFound => 'Listing not found.';

  @override
  String get labelRole => 'Role';

  @override
  String get labelLocation => 'Location';

  @override
  String get labelDistance => 'Distance';

  @override
  String get labelLastActive => 'Last active';

  @override
  String get contact => 'Contact';

  @override
  String get call => 'Call';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get opensDialerOrWhatsApp =>
      'Opens your phone dialer or WhatsApp. No in-app chat.';

  @override
  String phoneLockedSpendCredit(int cost) {
    return 'Phone number is locked. Spend $cost credit to unlock.';
  }

  @override
  String get contactUnlocked => 'Contact unlocked.';

  @override
  String get notEnoughCredits =>
      'Not enough credits. Add some on the Credits tab.';

  @override
  String unlockForCredit(int cost) {
    return 'Unlock for $cost credit';
  }

  @override
  String youHaveCredits(int count) {
    return 'You have $count credits.';
  }

  @override
  String get couldNotOpenDialer =>
      'Could not open the phone dialer on this device.';

  @override
  String get couldNotOpenWhatsApp =>
      'Could not open WhatsApp. Install WhatsApp or try Call instead.';

  @override
  String get yourBalance => 'Your balance';

  @override
  String creditsExplainer(int cost) {
    return 'Unlocking a contact costs $cost credit. Real payments come later — for now you can add demo credits.';
  }

  @override
  String addedDemoCredits(int count) {
    return 'Added $count demo credits.';
  }

  @override
  String addDemoCredits(int count) {
    return 'Add $count demo credits';
  }

  @override
  String addedDemoCredit(int count) {
    return 'Added $count demo credit.';
  }

  @override
  String addDemoCredit(int count) {
    return 'Add $count demo credit';
  }

  @override
  String get displayName => 'Display name';

  @override
  String get publicTagline => 'Public tagline';

  @override
  String get taglineHint => 'e.g. 100% organic farm';

  @override
  String taglineTooLong(int max) {
    return 'Tagline must be $max characters or fewer.';
  }

  @override
  String get labelTagline => 'Tagline';

  @override
  String get buyingInterests => 'Buying interests';

  @override
  String get sellingInterests => 'Selling interests';

  @override
  String get buyingInterestsEmpty => 'None yet — add crops you want to buy';

  @override
  String get sellingInterestsEmpty => 'None yet — add crops you want to sell';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get saveProfile => 'Save profile';

  @override
  String profileStats(int credits, int unlocked) {
    return 'Credits: $credits · Unlocked contacts: $unlocked';
  }

  @override
  String get defaultDisplayName => 'You';

  @override
  String get defaultLocation => 'Not set';

  @override
  String get myListing => 'My listing';

  @override
  String get publishMyListing => 'Publish my listing';

  @override
  String get editMyListing => 'Edit my listing';

  @override
  String get clearMyListing => 'Clear listing';

  @override
  String get listingPublished => 'Listing published.';

  @override
  String get listingCleared => 'Listing cleared.';

  @override
  String get labelCrop => 'Crop';

  @override
  String get labelQuantity => 'Quantity';

  @override
  String get labelPhone => 'Phone';

  @override
  String get quantityHintField => 'e.g. ~800 kg ready';

  @override
  String get phoneHintField => 'Number for Call / WhatsApp';

  @override
  String get saveListing => 'Save listing';

  @override
  String get myListingEmpty => 'No listing yet for this role.';

  @override
  String myListingSummary(String crop, String quantity) {
    return '$crop · $quantity';
  }

  @override
  String listingSubtitle(
    String crop,
    String quantity,
    String distance,
    String lastActive,
  ) {
    return '$crop · $quantity\n$distance · $lastActive';
  }

  @override
  String get cropMaize => 'Maize';

  @override
  String get cropCassava => 'Cassava';

  @override
  String get cropBeans => 'Beans';

  @override
  String get cropGroundnuts => 'Groundnuts';

  @override
  String get cropRice => 'Rice';

  @override
  String get qtyBuyingUpTo2Tonnes => 'Buying up to 2 tonnes';

  @override
  String get qtyWeeklyBuyerBags => 'Weekly buyer · bags';

  @override
  String get qtyAggregatorFairPrice => 'Aggregator · fair price';

  @override
  String get qtyNeeds500KgThisWeek => 'Needs 500 kg this week';

  @override
  String get qtySmallLotsWelcome => 'Small lots welcome';

  @override
  String get qty800KgReady => '~800 kg ready';

  @override
  String get qtyFreshHarvest => 'Fresh harvest';

  @override
  String get qty10Bags => '10 bags';

  @override
  String get qty1_5Tonnes => '1.5 tonnes';

  @override
  String get qtySmallSurplus => 'Small surplus';

  @override
  String get placeVillageMarket => 'Village market';

  @override
  String get placeNearVillage => 'Near village';

  @override
  String get placeKaleheRoad => 'Kalehe road';

  @override
  String get placeVillage => 'Village';

  @override
  String get placeNearbyHills => 'Nearby hills';

  @override
  String get placeNearKalehe => 'Near Kalehe';

  @override
  String get activeToday => 'Active today';

  @override
  String get activeYesterday => 'Active yesterday';

  @override
  String get active2DaysAgo => 'Active 2 days ago';

  @override
  String get active3DaysAgo => 'Active 3 days ago';

  @override
  String get activeThisWeek => 'Active this week';
}

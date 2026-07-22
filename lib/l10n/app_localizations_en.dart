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
  String get lookingFor => 'Looking for…';

  @override
  String get lookingForBuyers => 'Buyers';

  @override
  String get lookingForSellers => 'Sellers';

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
  String get addCropInterest => 'Add a crop';

  @override
  String get addCropInterestHint => 'Type a name or pick a suggestion';

  @override
  String didYouMeanCrop(String crop) {
    return 'Did you mean $crop?';
  }

  @override
  String useSuggestedCrop(String crop) {
    return 'Use $crop';
  }

  @override
  String addCropAsTyped(String crop) {
    return 'Add \"$crop\" anyway';
  }

  @override
  String addedCanonicalCrop(String crop) {
    return 'Added as $crop.';
  }

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

  @override
  String get navForum => 'Forum';

  @override
  String get forumTitle => 'Community forum';

  @override
  String get forumNewPost => 'New post';

  @override
  String get forumPostHint => 'Share news, prices, or questions…';

  @override
  String get forumPostAction => 'Post';

  @override
  String get forumReplyAction => 'Reply';

  @override
  String get forumReplyHint => 'Write a reply…';

  @override
  String get forumReportSpam => 'This is spam';

  @override
  String get forumReported => 'Reported';

  @override
  String get forumReportThanks => 'Thanks — this post was reported.';

  @override
  String get forumDeletePost => 'Delete post';

  @override
  String get forumDeleteConfirm => 'Delete this post?';

  @override
  String get forumPostDeleted => 'Post deleted.';

  @override
  String get forumPendingReview => 'Awaiting review';

  @override
  String get forumPendingExplainer =>
      'Only you can see this until it is reviewed.';

  @override
  String get forumOfflineBanner => 'You\'re offline — showing saved posts.';

  @override
  String get forumEmpty => 'No posts yet. Start the conversation!';

  @override
  String get forumLoadError => 'Couldn\'t load posts. Pull down to retry.';

  @override
  String forumRateLimited(int seconds) {
    return 'You\'re posting too fast. Try again in $seconds s.';
  }

  @override
  String get forumDuplicate => 'You already posted this recently.';

  @override
  String get forumPostFailed =>
      'Couldn\'t publish. Check your connection and try again.';

  @override
  String forumReplies(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
      zero: 'No replies',
    );
    return '$_temp0';
  }

  @override
  String get forumLoadMore => 'Load more';

  @override
  String get forumThreadTitle => 'Discussion';

  @override
  String get forumSetNameFirst => 'Add your name in Profile before posting.';

  @override
  String get forumJustNow => 'just now';

  @override
  String forumMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String forumHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String forumDaysAgo(int days) {
    return '$days d ago';
  }

  @override
  String get listingSyncSynced => 'Synced';

  @override
  String get listingSyncPending => 'Waiting to sync';

  @override
  String get listingSyncFailed => 'Sync failed — tap to retry';

  @override
  String get listingPublishedPendingSync =>
      'Listing saved — it will sync when you\'re online.';

  @override
  String get discoverOfflineBanner =>
      'You\'re offline — showing saved listings.';

  @override
  String get discoverSampleBanner =>
      'Can\'t connect — showing sample listings.';

  @override
  String get unlockOffline =>
      'You\'re offline. No credit was used — try again later.';

  @override
  String get unlockRateLimited =>
      'Daily contact limit reached — try again tomorrow. No credit was used.';

  @override
  String get unlockListingGone =>
      'This listing is no longer available. No credit was used.';

  @override
  String get unlockFailed =>
      'Couldn\'t get the contact. No credit was used — try again.';
}

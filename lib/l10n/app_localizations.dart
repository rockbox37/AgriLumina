import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Brand name; keep consistent across locales unless brand localization is decided.
  ///
  /// In en, this message translates to:
  /// **'AgriLumina'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get navCredits;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @brandHomeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get brandHomeTooltip;

  /// No description provided for @brandHomeSemantics.
  ///
  /// In en, this message translates to:
  /// **'AgriLumina home'**
  String get brandHomeSemantics;

  /// No description provided for @creditsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} credits'**
  String creditsCount(int count);

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(String name);

  /// No description provided for @findNearbyByDistance.
  ///
  /// In en, this message translates to:
  /// **'Find nearby {counterpart} by distance.'**
  String findNearbyByDistance(String counterpart);

  /// No description provided for @buyers.
  ///
  /// In en, this message translates to:
  /// **'buyers'**
  String get buyers;

  /// No description provided for @sellers.
  ///
  /// In en, this message translates to:
  /// **'sellers'**
  String get sellers;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a…'**
  String get iAmA;

  /// No description provided for @lookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for…'**
  String get lookingFor;

  /// No description provided for @lookingForBuyers.
  ///
  /// In en, this message translates to:
  /// **'Buyers'**
  String get lookingForBuyers;

  /// No description provided for @lookingForSellers.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get lookingForSellers;

  /// No description provided for @enabledRolesLabel.
  ///
  /// In en, this message translates to:
  /// **'I can…'**
  String get enabledRolesLabel;

  /// No description provided for @rolesRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one role.'**
  String get rolesRequired;

  /// No description provided for @roleSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get roleSeller;

  /// No description provided for @roleBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get roleBuyer;

  /// No description provided for @nearbyCount.
  ///
  /// In en, this message translates to:
  /// **'{count} nearby {counterpart}'**
  String nearbyCount(int count, String counterpart);

  /// No description provided for @noMatchesInSeedData.
  ///
  /// In en, this message translates to:
  /// **'No matches in seed data yet'**
  String get noMatchesInSeedData;

  /// No description provided for @closestListing.
  ///
  /// In en, this message translates to:
  /// **'Closest: {name} · {distance}'**
  String closestListing(String name, String distance);

  /// No description provided for @spendCreditToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Spend {cost} credit to unlock a phone number.'**
  String spendCreditToUnlock(int cost);

  /// No description provided for @findBuyers.
  ///
  /// In en, this message translates to:
  /// **'Find Buyers'**
  String get findBuyers;

  /// No description provided for @findSellers.
  ///
  /// In en, this message translates to:
  /// **'Find Sellers'**
  String get findSellers;

  /// No description provided for @refreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get refreshLocation;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @showingCropsYouSell.
  ///
  /// In en, this message translates to:
  /// **'Showing crops you sell'**
  String get showingCropsYouSell;

  /// No description provided for @showingCropsYouBuy.
  ///
  /// In en, this message translates to:
  /// **'Showing crops you buy'**
  String get showingCropsYouBuy;

  /// No description provided for @searchCounterparts.
  ///
  /// In en, this message translates to:
  /// **'Search {counterpart}'**
  String searchCounterparts(String counterpart);

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @noCounterpartsNearbyYet.
  ///
  /// In en, this message translates to:
  /// **'No {counterpart} nearby yet.'**
  String noCounterpartsNearbyYet(String counterpart);

  /// No description provided for @noCropCounterpartsNearby.
  ///
  /// In en, this message translates to:
  /// **'No {crop} {counterpart} nearby.'**
  String noCropCounterpartsNearby(String crop, String counterpart);

  /// No description provided for @noCounterpartsForInterests.
  ///
  /// In en, this message translates to:
  /// **'No {counterpart} nearby for your interests.'**
  String noCounterpartsForInterests(String counterpart);

  /// No description provided for @noCounterpartsNearby.
  ///
  /// In en, this message translates to:
  /// **'No {counterpart} nearby.'**
  String noCounterpartsNearby(String counterpart);

  /// No description provided for @noSearchMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\" among {scope}.'**
  String noSearchMatches(String query, String scope);

  /// No description provided for @nearYouBanner.
  ///
  /// In en, this message translates to:
  /// **'Near you · {label}'**
  String nearYouBanner(String label);

  /// No description provided for @sampleListingsEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Sample listings · enable location for nearby distances'**
  String get sampleListingsEnableLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Showing distances from sample listings.'**
  String get locationPermissionDenied;

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Showing distances from sample listings.'**
  String get locationServicesOff;

  /// No description provided for @locationUnsupported.
  ///
  /// In en, this message translates to:
  /// **'GPS is not available on this device. Showing distances from sample listings.'**
  String get locationUnsupported;

  /// No description provided for @locationReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read location. Showing distances from sample listings.'**
  String get locationReadError;

  /// No description provided for @sampleArea.
  ///
  /// In en, this message translates to:
  /// **'Sample area'**
  String get sampleArea;

  /// No description provided for @nearSampleArea.
  ///
  /// In en, this message translates to:
  /// **'Near sample area'**
  String get nearSampleArea;

  /// No description provided for @yourCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get yourCurrentLocation;

  /// Metric distance. Units strategy: km for all locales in MVP; mi can follow later.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String distanceKm(String value);

  /// No description provided for @listingTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listingTitle;

  /// No description provided for @listingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Listing not found.'**
  String get listingNotFound;

  /// No description provided for @labelRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get labelRole;

  /// No description provided for @labelLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get labelLocation;

  /// No description provided for @labelDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get labelDistance;

  /// No description provided for @labelLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get labelLastActive;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @opensDialerOrWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Opens your phone dialer or WhatsApp. No in-app chat.'**
  String get opensDialerOrWhatsApp;

  /// No description provided for @phoneLockedSpendCredit.
  ///
  /// In en, this message translates to:
  /// **'Phone number is locked. Spend {cost} credit to unlock.'**
  String phoneLockedSpendCredit(int cost);

  /// No description provided for @contactUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Contact unlocked.'**
  String get contactUnlocked;

  /// No description provided for @notEnoughCredits.
  ///
  /// In en, this message translates to:
  /// **'Not enough credits. Add some on the Credits tab.'**
  String get notEnoughCredits;

  /// No description provided for @unlockForCredit.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {cost} credit'**
  String unlockForCredit(int cost);

  /// No description provided for @youHaveCredits.
  ///
  /// In en, this message translates to:
  /// **'You have {count} credits.'**
  String youHaveCredits(int count);

  /// No description provided for @couldNotOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone dialer on this device.'**
  String get couldNotOpenDialer;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Install WhatsApp or try Call instead.'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @yourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get yourBalance;

  /// No description provided for @creditsExplainer.
  ///
  /// In en, this message translates to:
  /// **'Unlocking a contact costs {cost} credit. Real payments come later — for now you can add demo credits.'**
  String creditsExplainer(int cost);

  /// No description provided for @addedDemoCredits.
  ///
  /// In en, this message translates to:
  /// **'Added {count} demo credits.'**
  String addedDemoCredits(int count);

  /// No description provided for @addDemoCredits.
  ///
  /// In en, this message translates to:
  /// **'Add {count} demo credits'**
  String addDemoCredits(int count);

  /// No description provided for @addedDemoCredit.
  ///
  /// In en, this message translates to:
  /// **'Added {count} demo credit.'**
  String addedDemoCredit(int count);

  /// No description provided for @addDemoCredit.
  ///
  /// In en, this message translates to:
  /// **'Add {count} demo credit'**
  String addDemoCredit(int count);

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @publicTagline.
  ///
  /// In en, this message translates to:
  /// **'Public tagline'**
  String get publicTagline;

  /// No description provided for @taglineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100% organic farm'**
  String get taglineHint;

  /// No description provided for @taglineTooLong.
  ///
  /// In en, this message translates to:
  /// **'Tagline must be {max} characters or fewer.'**
  String taglineTooLong(int max);

  /// No description provided for @labelTagline.
  ///
  /// In en, this message translates to:
  /// **'Tagline'**
  String get labelTagline;

  /// No description provided for @buyingInterests.
  ///
  /// In en, this message translates to:
  /// **'Buying interests'**
  String get buyingInterests;

  /// No description provided for @sellingInterests.
  ///
  /// In en, this message translates to:
  /// **'Selling interests'**
  String get sellingInterests;

  /// No description provided for @buyingInterestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'None yet — add crops you want to buy'**
  String get buyingInterestsEmpty;

  /// No description provided for @sellingInterestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'None yet — add crops you want to sell'**
  String get sellingInterestsEmpty;

  /// No description provided for @addCropInterest.
  ///
  /// In en, this message translates to:
  /// **'Add a crop'**
  String get addCropInterest;

  /// No description provided for @addCropInterestHint.
  ///
  /// In en, this message translates to:
  /// **'Type a name or pick a suggestion'**
  String get addCropInterestHint;

  /// No description provided for @didYouMeanCrop.
  ///
  /// In en, this message translates to:
  /// **'Did you mean {crop}?'**
  String didYouMeanCrop(String crop);

  /// No description provided for @useSuggestedCrop.
  ///
  /// In en, this message translates to:
  /// **'Use {crop}'**
  String useSuggestedCrop(String crop);

  /// No description provided for @addCropAsTyped.
  ///
  /// In en, this message translates to:
  /// **'Add \"{crop}\" anyway'**
  String addCropAsTyped(String crop);

  /// No description provided for @addedCanonicalCrop.
  ///
  /// In en, this message translates to:
  /// **'Added as {crop}.'**
  String addedCanonicalCrop(String crop);

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileStats.
  ///
  /// In en, this message translates to:
  /// **'Credits: {credits} · Unlocked contacts: {unlocked}'**
  String profileStats(int credits, int unlocked);

  /// No description provided for @defaultDisplayName.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get defaultDisplayName;

  /// No description provided for @defaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get defaultLocation;

  /// No description provided for @myListing.
  ///
  /// In en, this message translates to:
  /// **'My listing'**
  String get myListing;

  /// No description provided for @publishMyListing.
  ///
  /// In en, this message translates to:
  /// **'Publish my listing'**
  String get publishMyListing;

  /// No description provided for @editMyListing.
  ///
  /// In en, this message translates to:
  /// **'Edit my listing'**
  String get editMyListing;

  /// No description provided for @clearMyListing.
  ///
  /// In en, this message translates to:
  /// **'Clear listing'**
  String get clearMyListing;

  /// No description provided for @listingPublished.
  ///
  /// In en, this message translates to:
  /// **'Listing published.'**
  String get listingPublished;

  /// No description provided for @listingCleared.
  ///
  /// In en, this message translates to:
  /// **'Listing cleared.'**
  String get listingCleared;

  /// No description provided for @labelCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get labelCrop;

  /// No description provided for @labelQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get labelQuantity;

  /// No description provided for @labelPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get labelPhone;

  /// No description provided for @quantityHintField.
  ///
  /// In en, this message translates to:
  /// **'e.g. ~800 kg ready'**
  String get quantityHintField;

  /// No description provided for @phoneHintField.
  ///
  /// In en, this message translates to:
  /// **'Number for Call / WhatsApp'**
  String get phoneHintField;

  /// No description provided for @saveListing.
  ///
  /// In en, this message translates to:
  /// **'Save listing'**
  String get saveListing;

  /// No description provided for @myListingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No listing yet for this role.'**
  String get myListingEmpty;

  /// No description provided for @myListingSummary.
  ///
  /// In en, this message translates to:
  /// **'{crop} · {quantity}'**
  String myListingSummary(String crop, String quantity);

  /// No description provided for @listingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{crop} · {quantity}\n{distance} · {lastActive}'**
  String listingSubtitle(
    String crop,
    String quantity,
    String distance,
    String lastActive,
  );

  /// No description provided for @cropMaize.
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get cropMaize;

  /// No description provided for @cropCassava.
  ///
  /// In en, this message translates to:
  /// **'Cassava'**
  String get cropCassava;

  /// No description provided for @cropBeans.
  ///
  /// In en, this message translates to:
  /// **'Beans'**
  String get cropBeans;

  /// No description provided for @cropGroundnuts.
  ///
  /// In en, this message translates to:
  /// **'Groundnuts'**
  String get cropGroundnuts;

  /// No description provided for @cropRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get cropRice;

  /// No description provided for @qtyBuyingUpTo2Tonnes.
  ///
  /// In en, this message translates to:
  /// **'Buying up to 2 tonnes'**
  String get qtyBuyingUpTo2Tonnes;

  /// No description provided for @qtyWeeklyBuyerBags.
  ///
  /// In en, this message translates to:
  /// **'Weekly buyer · bags'**
  String get qtyWeeklyBuyerBags;

  /// No description provided for @qtyAggregatorFairPrice.
  ///
  /// In en, this message translates to:
  /// **'Aggregator · fair price'**
  String get qtyAggregatorFairPrice;

  /// No description provided for @qtyNeeds500KgThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Needs 500 kg this week'**
  String get qtyNeeds500KgThisWeek;

  /// No description provided for @qtySmallLotsWelcome.
  ///
  /// In en, this message translates to:
  /// **'Small lots welcome'**
  String get qtySmallLotsWelcome;

  /// No description provided for @qty800KgReady.
  ///
  /// In en, this message translates to:
  /// **'~800 kg ready'**
  String get qty800KgReady;

  /// No description provided for @qtyFreshHarvest.
  ///
  /// In en, this message translates to:
  /// **'Fresh harvest'**
  String get qtyFreshHarvest;

  /// No description provided for @qty10Bags.
  ///
  /// In en, this message translates to:
  /// **'10 bags'**
  String get qty10Bags;

  /// No description provided for @qty1_5Tonnes.
  ///
  /// In en, this message translates to:
  /// **'1.5 tonnes'**
  String get qty1_5Tonnes;

  /// No description provided for @qtySmallSurplus.
  ///
  /// In en, this message translates to:
  /// **'Small surplus'**
  String get qtySmallSurplus;

  /// No description provided for @placeVillageMarket.
  ///
  /// In en, this message translates to:
  /// **'Village market'**
  String get placeVillageMarket;

  /// No description provided for @placeNearVillage.
  ///
  /// In en, this message translates to:
  /// **'Near village'**
  String get placeNearVillage;

  /// No description provided for @placeKaleheRoad.
  ///
  /// In en, this message translates to:
  /// **'Kalehe road'**
  String get placeKaleheRoad;

  /// No description provided for @placeVillage.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get placeVillage;

  /// No description provided for @placeNearbyHills.
  ///
  /// In en, this message translates to:
  /// **'Nearby hills'**
  String get placeNearbyHills;

  /// No description provided for @placeNearKalehe.
  ///
  /// In en, this message translates to:
  /// **'Near Kalehe'**
  String get placeNearKalehe;

  /// No description provided for @activeToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get activeToday;

  /// No description provided for @activeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Active yesterday'**
  String get activeYesterday;

  /// No description provided for @active2DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Active 2 days ago'**
  String get active2DaysAgo;

  /// No description provided for @active3DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Active 3 days ago'**
  String get active3DaysAgo;

  /// No description provided for @activeThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Active this week'**
  String get activeThisWeek;

  /// No description provided for @navForum.
  ///
  /// In en, this message translates to:
  /// **'Forum'**
  String get navForum;

  /// No description provided for @forumTitle.
  ///
  /// In en, this message translates to:
  /// **'Community forum'**
  String get forumTitle;

  /// No description provided for @forumNewPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get forumNewPost;

  /// No description provided for @forumPostHint.
  ///
  /// In en, this message translates to:
  /// **'Share news, prices, or questions…'**
  String get forumPostHint;

  /// No description provided for @forumPostAction.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get forumPostAction;

  /// No description provided for @forumReplyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get forumReplyAction;

  /// No description provided for @forumReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get forumReplyHint;

  /// No description provided for @forumReportSpam.
  ///
  /// In en, this message translates to:
  /// **'This is spam'**
  String get forumReportSpam;

  /// No description provided for @forumReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get forumReported;

  /// No description provided for @forumReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — this post was reported.'**
  String get forumReportThanks;

  /// No description provided for @forumDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get forumDeletePost;

  /// No description provided for @forumDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get forumDeleteConfirm;

  /// No description provided for @forumPostDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted.'**
  String get forumPostDeleted;

  /// No description provided for @forumPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get forumPendingReview;

  /// No description provided for @forumPendingExplainer.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this until it is reviewed.'**
  String get forumPendingExplainer;

  /// No description provided for @forumOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — showing saved posts.'**
  String get forumOfflineBanner;

  /// No description provided for @forumEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Start the conversation!'**
  String get forumEmpty;

  /// No description provided for @forumLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load posts. Pull down to retry.'**
  String get forumLoadError;

  /// No description provided for @forumRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You\'re posting too fast. Try again in {seconds} s.'**
  String forumRateLimited(int seconds);

  /// No description provided for @forumDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already posted this recently.'**
  String get forumDuplicate;

  /// No description provided for @forumPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish. Check your connection and try again.'**
  String get forumPostFailed;

  /// No description provided for @forumReplies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No replies} =1{1 reply} other{{count} replies}}'**
  String forumReplies(num count);

  /// No description provided for @forumLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get forumLoadMore;

  /// No description provided for @forumThreadTitle.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get forumThreadTitle;

  /// No description provided for @forumSetNameFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your name in Profile before posting.'**
  String get forumSetNameFirst;

  /// No description provided for @forumJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get forumJustNow;

  /// No description provided for @forumMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String forumMinutesAgo(int minutes);

  /// No description provided for @forumHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String forumHoursAgo(int hours);

  /// No description provided for @forumDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} d ago'**
  String forumDaysAgo(int days);

  /// No description provided for @listingSyncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get listingSyncSynced;

  /// No description provided for @listingSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get listingSyncPending;

  /// No description provided for @listingSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed — tap to retry'**
  String get listingSyncFailed;

  /// No description provided for @listingPublishedPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Listing saved — it will sync when you\'re online.'**
  String get listingPublishedPendingSync;

  /// No description provided for @discoverOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — showing saved listings.'**
  String get discoverOfflineBanner;

  /// No description provided for @discoverSampleBanner.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect — showing sample listings.'**
  String get discoverSampleBanner;

  /// No description provided for @unlockOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. No credit was used — try again later.'**
  String get unlockOffline;

  /// No description provided for @unlockRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Daily contact limit reached — try again tomorrow. No credit was used.'**
  String get unlockRateLimited;

  /// No description provided for @unlockListingGone.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer available. No credit was used.'**
  String get unlockListingGone;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the contact. No credit was used — try again.'**
  String get unlockFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

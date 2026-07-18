import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';
import 'package:agrilumina/data/listing_copy_keys.dart';
import 'package:agrilumina/data/mock_listings.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/local_state_store.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:agrilumina/utils/geo.dart';

/// Shared app state for the MVP vertical slice.
///
/// Role model:
/// - [enabledRoles]: capabilities (buy and/or sell; interest lists; my listing
///   per role). At least one role is always required.
/// - [activeRole]: lightweight browsing lens for Discover counterparts
///   (must be one of [enabledRoles]).
class AppState extends ChangeNotifier {
  AppState({
    this.credits = 5,
    Set<UserRole>? enabledRoles,
    UserRole? activeRole,
    UserRole? role,
    this.displayName = '',
    this.location = '',
    this.tagline = '',
    List<String>? buyingInterests,
    List<String>? sellingInterests,
    Set<String>? unlockedListingIds,
    this.mySellerListing,
    this.myBuyerListing,
    List<Listing>? listings,
    LocationService? locationService,
    LocalStateStore? store,
  })  : enabledRoles = _initEnabledRoles(enabledRoles, activeRole, role),
        activeRole = _initActiveRole(enabledRoles, activeRole, role),
        buyingInterests = List<String>.from(buyingInterests ?? const []),
        sellingInterests =
            List<String>.from(sellingInterests ?? const ['Maize']),
        unlockedListingIds = {...?unlockedListingIds},
        _seedListings = List.unmodifiable(listings ?? mockListings),
        _locationService = locationService ?? PluginLocationService(),
        _store = store;

  /// Builds [AppState] from persisted MVP fields (and keeps saving mutations).
  factory AppState.fromStore(
    LocalStateStore store, {
    LocationService? locationService,
    List<Listing>? listings,
  }) {
    final snap = store.load();
    return AppState(
      credits: snap.credits,
      enabledRoles: snap.enabledRoles,
      activeRole: snap.activeRole,
      displayName: snap.displayName,
      location: snap.location,
      tagline: snap.tagline,
      buyingInterests: snap.buyingInterests,
      sellingInterests: snap.sellingInterests,
      unlockedListingIds: snap.unlockedListingIds,
      mySellerListing: snap.mySellerListing,
      myBuyerListing: snap.myBuyerListing,
      listings: listings,
      locationService: locationService,
      store: store,
    );
  }

  static const int unlockContactCost = 1;
  static const int homeTabIndex = 0;
  static const int discoverTabIndex = 1;

  /// Bottom-nav indices: 0 Home, 1 Discover, 2 Credits, 3 Profile.
  int shellTabIndex = 0;

  int credits;

  /// Roles the user has enabled as capabilities. Always non-empty.
  Set<UserRole> enabledRoles;

  /// Role used for Discover/Home browsing. Always ∈ [enabledRoles].
  UserRole activeRole;

  /// Alias for [activeRole] (legacy call sites / tests).
  UserRole get role => activeRole;

  String displayName;
  String location;

  /// Public short blurb shown on Discover cards / listing detail.
  String tagline;

  /// Crops the user wants to buy (shared Discover vocabulary).
  List<String> buyingInterests;

  /// Crops the user wants to sell (shared Discover vocabulary).
  List<String> sellingInterests;

  /// One published listing for the seller role (null = unpublished).
  Listing? mySellerListing;

  /// One published listing for the buyer role (null = unpublished).
  Listing? myBuyerListing;

  final List<Listing> _seedListings;
  final Set<String> unlockedListingIds;

  final LocationService _locationService;
  final LocalStateStore? _store;
  Future<void>? _persistFuture;

  UserLocation? userPosition;
  bool locationLoading = false;

  /// Status for the Discover location banner when GPS is unavailable.
  LocationFetchStatus? locationBannerStatus;

  /// Interest list used for Discover soft-filter for the active role.
  List<String> get relevantInterests =>
      activeRole == UserRole.seller ? sellingInterests : buyingInterests;

  /// Active-role listing (one per role for MVP).
  Listing? get myListing =>
      activeRole == UserRole.seller ? mySellerListing : myBuyerListing;

  /// Seed mocks plus any published local listings.
  List<Listing> get listings => [
        ..._seedListings,
        ?mySellerListing,
        ?myBuyerListing,
      ];

  /// True when Discover should show live GPS-based distances.
  bool get usingGps => userPosition != null;

  /// Approximate place kind for the device position (localize in UI).
  ApproximateLocationKind get deviceLocationKind {
    final pos = userPosition;
    if (pos == null) return ApproximateLocationKind.nearSampleArea;
    return approximateLocationKind(pos.latitude, pos.longitude);
  }

  double distanceKmFor(Listing listing) {
    final pos = userPosition;
    if (pos == null) return listing.distanceKm;
    return roundKm(
      haversineKm(
        pos.latitude,
        pos.longitude,
        listing.latitude,
        listing.longitude,
      ),
    );
  }

  List<Listing> get nearbyCounterparts {
    final want = activeRole.counterpart;
    final nearby = listings
        .where((l) => l.role == want)
        .map((l) => l.copyWith(distanceKm: distanceKmFor(l)))
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return nearby;
  }

  bool isUnlocked(String listingId) => unlockedListingIds.contains(listingId);

  bool isRoleEnabled(UserRole value) => enabledRoles.contains(value);

  LocalStateSnapshot get persistedSnapshot => LocalStateSnapshot(
        credits: credits,
        enabledRoles: enabledRoles,
        activeRole: activeRole,
        displayName: displayName,
        location: location,
        tagline: tagline,
        buyingInterests: buyingInterests,
        sellingInterests: sellingInterests,
        unlockedListingIds: unlockedListingIds,
        mySellerListing: mySellerListing,
        myBuyerListing: myBuyerListing,
      );

  void _persist() {
    final store = _store;
    if (store == null) return;
    _persistFuture = store.save(persistedSnapshot);
  }

  /// Awaits the latest persist write (for tests).
  Future<void> waitForPersistence() async {
    await _persistFuture;
  }

  void goToTab(int index) {
    final changed = shellTabIndex != index;
    if (changed) {
      shellTabIndex = index;
      notifyListeners();
    }
    if (index == discoverTabIndex) {
      unawaited(refreshLocation());
    }
  }

  /// Requests a fresh GPS fix. Falls back to seed listing distances on failure.
  Future<void> refreshLocation() async {
    if (locationLoading) return;
    locationLoading = true;
    notifyListeners();

    final result = await _locationService.fetchCurrentLocation();

    locationLoading = false;
    if (result.isSuccess && result.position != null) {
      userPosition = result.position;
      locationBannerStatus = null;
    } else {
      userPosition = null;
      locationBannerStatus = result.status == LocationFetchStatus.success
          ? LocationFetchStatus.error
          : result.status;
    }
    notifyListeners();
  }

  /// Sets the browsing role. No-op if [value] is not enabled.
  void setActiveRole(UserRole value) {
    if (!enabledRoles.contains(value)) return;
    if (activeRole == value) return;
    activeRole = value;
    notifyListeners();
    _persist();
  }

  /// Legacy alias for [setActiveRole].
  void setRole(UserRole value) => setActiveRole(value);

  /// Enables or disables a capability role.
  ///
  /// Returns false when disabling would leave zero roles (at least one required).
  /// When the active role is disabled, [activeRole] moves to another enabled role.
  bool setRoleEnabled(UserRole value, {required bool enabled}) {
    if (enabled) {
      if (enabledRoles.contains(value)) return true;
      enabledRoles = {...enabledRoles, value};
    } else {
      if (!enabledRoles.contains(value)) return true;
      if (enabledRoles.length <= 1) return false;
      enabledRoles = {...enabledRoles}..remove(value);
      if (activeRole == value) {
        activeRole = enabledRoles.contains(UserRole.seller)
            ? UserRole.seller
            : enabledRoles.first;
      }
    }
    notifyListeners();
    _persist();
    return true;
  }

  /// Replaces [enabledRoles]. Returns false if [roles] is empty.
  bool setEnabledRoles(Set<UserRole> roles) {
    if (roles.isEmpty) return false;
    enabledRoles = {...roles};
    if (!enabledRoles.contains(activeRole)) {
      activeRole = enabledRoles.contains(UserRole.seller)
          ? UserRole.seller
          : enabledRoles.first;
    }
    notifyListeners();
    _persist();
    return true;
  }

  void addCredits(int amount) {
    if (amount <= 0) return;
    credits += amount;
    notifyListeners();
    _persist();
  }

  /// Spends [unlockContactCost] credit to reveal contact for [listingId].
  /// Returns false if already unlocked, listing missing, or not enough credits.
  bool unlockContact(String listingId) {
    if (unlockedListingIds.contains(listingId)) return true;
    if (!listings.any((l) => l.id == listingId)) return false;
    if (credits < unlockContactCost) return false;

    credits -= unlockContactCost;
    unlockedListingIds.add(listingId);
    notifyListeners();
    _persist();
    return true;
  }

  /// Adds [crop] to buying interests.
  ///
  /// Prefers a canonical vocabulary id when [crop] matches exactly or via
  /// alias; otherwise stores a normalized custom name. Ignores empties and
  /// case-insensitive duplicates.
  void addBuyingInterest(String crop) {
    if (!_tryAddInterest(buyingInterests, crop)) return;
    notifyListeners();
    _persist();
  }

  /// Removes [crop] from buying interests if present (case-insensitive).
  void removeBuyingInterest(String crop) {
    if (!_removeInterest(buyingInterests, crop)) return;
    notifyListeners();
    _persist();
  }

  /// Toggles [crop] on the buying list (vocabulary only).
  void toggleBuyingInterest(String crop) {
    if (!isKnownCrop(crop)) return;
    if (interestContains(buyingInterests, crop)) {
      buyingInterests.removeWhere((c) => c.toLowerCase() == crop.toLowerCase());
    } else {
      buyingInterests.add(crop);
    }
    notifyListeners();
    _persist();
  }

  /// Adds [crop] to selling interests (canonical preferred; custom allowed).
  void addSellingInterest(String crop) {
    if (!_tryAddInterest(sellingInterests, crop)) return;
    notifyListeners();
    _persist();
  }

  /// Removes [crop] from selling interests if present (case-insensitive).
  void removeSellingInterest(String crop) {
    if (!_removeInterest(sellingInterests, crop)) return;
    notifyListeners();
    _persist();
  }

  /// Toggles [crop] on the selling list (vocabulary only).
  void toggleSellingInterest(String crop) {
    if (!isKnownCrop(crop)) return;
    if (interestContains(sellingInterests, crop)) {
      sellingInterests
          .removeWhere((c) => c.toLowerCase() == crop.toLowerCase());
    } else {
      sellingInterests.add(crop);
    }
    notifyListeners();
    _persist();
  }

  bool _tryAddInterest(List<String> list, String crop) {
    final id = resolveCropInterestId(crop);
    if (id == null) return false;
    if (interestContains(list, id)) return false;
    list.add(id);
    return true;
  }

  bool _removeInterest(List<String> list, String crop) {
    final before = list.length;
    list.removeWhere((c) => c.toLowerCase() == crop.toLowerCase());
    return list.length < before;
  }

  void updateProfile({
    String? displayName,
    String? location,
    String? tagline,
  }) {
    if (displayName != null) this.displayName = displayName;
    if (location != null) this.location = location;
    if (tagline != null) {
      this.tagline = tagline;
      // Keep published listings in sync with the public blurb.
      if (mySellerListing != null) {
        mySellerListing = mySellerListing!.copyWith(tagline: tagline);
      }
      if (myBuyerListing != null) {
        myBuyerListing = myBuyerListing!.copyWith(tagline: tagline);
      }
    }
    notifyListeners();
    _persist();
  }

  /// Creates or replaces the active-role listing. Returns false if invalid.
  bool publishMyListing({
    required String crop,
    required String quantityHint,
    required String phone,
    String? name,
    String? location,
  }) {
    if (!isKnownCrop(crop)) return false;
    final trimmedQty = quantityHint.trim();
    final trimmedPhone = phone.trim();
    if (trimmedQty.isEmpty || trimmedPhone.isEmpty) return false;

    final lat = userPosition?.latitude ?? bugobeLatitude;
    final lon = userPosition?.longitude ?? bugobeLongitude;
    final listing = Listing(
      id: Listing.myIdFor(activeRole),
      name: (name ?? displayName).trim(),
      role: activeRole,
      crop: crop,
      quantityHint: trimmedQty,
      distanceKm: 0,
      latitude: lat,
      longitude: lon,
      location: (location ?? this.location).trim(),
      lastActiveLabel: ListingCopyKeys.activeToday,
      phone: trimmedPhone,
      tagline: tagline.trim(),
    );

    if (activeRole == UserRole.seller) {
      mySellerListing = listing;
    } else {
      myBuyerListing = listing;
    }
    notifyListeners();
    _persist();
    return true;
  }

  /// Clears the active-role listing if present.
  void clearMyListing() {
    if (activeRole == UserRole.seller) {
      if (mySellerListing == null) return;
      mySellerListing = null;
    } else {
      if (myBuyerListing == null) return;
      myBuyerListing = null;
    }
    notifyListeners();
    _persist();
  }

  static Set<UserRole> _initEnabledRoles(
    Set<UserRole>? enabledRoles,
    UserRole? activeRole,
    UserRole? role,
  ) {
    if (enabledRoles != null && enabledRoles.isNotEmpty) {
      return {...enabledRoles};
    }
    // Explicit legacy `role:` / `activeRole:` alone → that single capability.
    if (role != null || activeRole != null) {
      return {activeRole ?? role!};
    }
    // Fresh in-memory default: both capabilities.
    return {UserRole.seller, UserRole.buyer};
  }

  static UserRole _initActiveRole(
    Set<UserRole>? enabledRoles,
    UserRole? activeRole,
    UserRole? role,
  ) {
    final enabled = _initEnabledRoles(enabledRoles, activeRole, role);
    final preferred = activeRole ?? role;
    if (preferred != null && enabled.contains(preferred)) return preferred;
    return enabled.contains(UserRole.seller)
        ? UserRole.seller
        : enabled.first;
  }
}

/// Provides [AppState] to the widget tree.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}

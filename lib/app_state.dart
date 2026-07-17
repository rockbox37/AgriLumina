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
class AppState extends ChangeNotifier {
  AppState({
    this.credits = 5,
    this.role = UserRole.seller,
    this.displayName = '',
    this.location = '',
    List<String>? buyingInterests,
    List<String>? sellingInterests,
    Set<String>? unlockedListingIds,
    this.mySellerListing,
    this.myBuyerListing,
    List<Listing>? listings,
    LocationService? locationService,
    LocalStateStore? store,
  })  : buyingInterests = List<String>.from(buyingInterests ?? const []),
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
      role: snap.role,
      displayName: snap.displayName,
      location: snap.location,
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
  UserRole role;
  String displayName;
  String location;

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
      role == UserRole.seller ? sellingInterests : buyingInterests;

  /// Active-role listing (one per role for MVP).
  Listing? get myListing =>
      role == UserRole.seller ? mySellerListing : myBuyerListing;

  /// Seed mocks plus any published local listings.
  List<Listing> get listings => [
        ..._seedListings,
        if (mySellerListing != null) mySellerListing!,
        if (myBuyerListing != null) myBuyerListing!,
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
    final want = role.counterpart;
    final nearby = listings
        .where((l) => l.role == want)
        .map((l) => l.copyWith(distanceKm: distanceKmFor(l)))
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return nearby;
  }

  bool isUnlocked(String listingId) => unlockedListingIds.contains(listingId);

  LocalStateSnapshot get persistedSnapshot => LocalStateSnapshot(
        credits: credits,
        role: role,
        displayName: displayName,
        location: location,
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

  void setRole(UserRole value) {
    if (role == value) return;
    role = value;
    notifyListeners();
    _persist();
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

  /// Adds [crop] to buying interests. Ignores unknown crops and duplicates.
  void addBuyingInterest(String crop) {
    if (!_tryAddInterest(buyingInterests, crop)) return;
    notifyListeners();
    _persist();
  }

  /// Removes [crop] from buying interests if present.
  void removeBuyingInterest(String crop) {
    if (!buyingInterests.remove(crop)) return;
    notifyListeners();
    _persist();
  }

  /// Toggles [crop] on the buying list (vocabulary only).
  void toggleBuyingInterest(String crop) {
    if (!isKnownCrop(crop)) return;
    if (buyingInterests.contains(crop)) {
      buyingInterests.remove(crop);
    } else {
      buyingInterests.add(crop);
    }
    notifyListeners();
    _persist();
  }

  /// Adds [crop] to selling interests. Ignores unknown crops and duplicates.
  void addSellingInterest(String crop) {
    if (!_tryAddInterest(sellingInterests, crop)) return;
    notifyListeners();
    _persist();
  }

  /// Removes [crop] from selling interests if present.
  void removeSellingInterest(String crop) {
    if (!sellingInterests.remove(crop)) return;
    notifyListeners();
    _persist();
  }

  /// Toggles [crop] on the selling list (vocabulary only).
  void toggleSellingInterest(String crop) {
    if (!isKnownCrop(crop)) return;
    if (sellingInterests.contains(crop)) {
      sellingInterests.remove(crop);
    } else {
      sellingInterests.add(crop);
    }
    notifyListeners();
    _persist();
  }

  bool _tryAddInterest(List<String> list, String crop) {
    if (!isKnownCrop(crop)) return false;
    if (list.contains(crop)) return false;
    list.add(crop);
    return true;
  }

  void updateProfile({
    String? displayName,
    String? location,
  }) {
    if (displayName != null) this.displayName = displayName;
    if (location != null) this.location = location;
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
      id: Listing.myIdFor(role),
      name: (name ?? displayName).trim(),
      role: role,
      crop: crop,
      quantityHint: trimmedQty,
      distanceKm: 0,
      latitude: lat,
      longitude: lon,
      location: (location ?? this.location).trim(),
      lastActiveLabel: ListingCopyKeys.activeToday,
      phone: trimmedPhone,
    );

    if (role == UserRole.seller) {
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
    if (role == UserRole.seller) {
      if (mySellerListing == null) return;
      mySellerListing = null;
    } else {
      if (myBuyerListing == null) return;
      myBuyerListing = null;
    }
    notifyListeners();
    _persist();
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

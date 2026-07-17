import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';
import 'package:agrilumina/data/mock_listings.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:agrilumina/utils/geo.dart';

/// Shared app state for the MVP vertical slice.
class AppState extends ChangeNotifier {
  AppState({
    this.credits = 5,
    this.role = UserRole.seller,
    this.displayName = 'You',
    this.location = 'Not set',
    List<String>? buyingInterests,
    List<String>? sellingInterests,
    List<Listing>? listings,
    LocationService? locationService,
  })  : buyingInterests = List<String>.from(buyingInterests ?? const []),
        sellingInterests =
            List<String>.from(sellingInterests ?? const ['Maize']),
        listings = List.unmodifiable(listings ?? mockListings),
        _locationService = locationService ?? PluginLocationService();

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

  final List<Listing> listings;
  final Set<String> unlockedListingIds = {};

  final LocationService _locationService;

  UserLocation? userPosition;
  bool locationLoading = false;
  String? locationBannerMessage;

  /// Interest list used for Discover soft-filter for the active role.
  List<String> get relevantInterests =>
      role == UserRole.seller ? sellingInterests : buyingInterests;

  /// True when Discover should show live GPS-based distances.
  bool get usingGps => userPosition != null;

  /// Approximate place label for the device position (or sample-area fallback).
  String get deviceLocationLabel {
    final pos = userPosition;
    if (pos == null) return sampleAreaLabel;
    return approximateLocationLabel(pos.latitude, pos.longitude);
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
      locationBannerMessage = null;
    } else {
      userPosition = null;
      locationBannerMessage = result.message ??
          'Could not read location. Showing distances from sample listings.';
    }
    notifyListeners();
  }

  void setRole(UserRole value) {
    if (role == value) return;
    role = value;
    notifyListeners();
  }

  void addCredits(int amount) {
    if (amount <= 0) return;
    credits += amount;
    notifyListeners();
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
    return true;
  }

  /// Adds [crop] to buying interests. Ignores unknown crops and duplicates.
  void addBuyingInterest(String crop) {
    if (!_tryAddInterest(buyingInterests, crop)) return;
    notifyListeners();
  }

  /// Removes [crop] from buying interests if present.
  void removeBuyingInterest(String crop) {
    if (!buyingInterests.remove(crop)) return;
    notifyListeners();
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
  }

  /// Adds [crop] to selling interests. Ignores unknown crops and duplicates.
  void addSellingInterest(String crop) {
    if (!_tryAddInterest(sellingInterests, crop)) return;
    notifyListeners();
  }

  /// Removes [crop] from selling interests if present.
  void removeSellingInterest(String crop) {
    if (!sellingInterests.remove(crop)) return;
    notifyListeners();
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

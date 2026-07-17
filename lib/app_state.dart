import 'dart:async';

import 'package:flutter/material.dart';
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
    this.location = bugobeLocationLabel,
    this.cropInterest = 'Maize',
    List<Listing>? listings,
    LocationService? locationService,
  })  : listings = List.unmodifiable(listings ?? mockListings),
        _locationService = locationService ?? PluginLocationService();

  static const int unlockContactCost = 1;
  static const int discoverTabIndex = 1;

  /// Bottom-nav indices: 0 Home, 1 Discover, 2 Credits, 3 Profile.
  int shellTabIndex = 0;

  int credits;
  UserRole role;
  String displayName;
  String location;
  String cropInterest;
  final List<Listing> listings;
  final Set<String> unlockedListingIds = {};

  final LocationService _locationService;

  UserLocation? userPosition;
  bool locationLoading = false;
  String? locationBannerMessage;

  /// True when Discover should show live GPS-based distances.
  bool get usingGps => userPosition != null;

  /// Approximate place label for the device position (or Bugobe fallback).
  String get deviceLocationLabel {
    final pos = userPosition;
    if (pos == null) return bugobeLocationLabel;
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

  /// Requests a fresh GPS fix. Falls back to Bugobe seed distances on failure.
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
          'Could not read location. Showing distances from sample listings near Bugobe.';
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

  void updateProfile({
    String? displayName,
    String? location,
    String? cropInterest,
  }) {
    if (displayName != null) this.displayName = displayName;
    if (location != null) this.location = location;
    if (cropInterest != null) this.cropInterest = cropInterest;
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

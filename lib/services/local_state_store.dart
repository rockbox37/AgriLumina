import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';

/// Snapshot of MVP fields persisted across cold starts.
class LocalStateSnapshot {
  const LocalStateSnapshot({
    required this.credits,
    required this.enabledRoles,
    required this.activeRole,
    required this.displayName,
    required this.location,
    required this.tagline,
    required this.buyingInterests,
    required this.sellingInterests,
    required this.unlockedListingIds,
    this.mySellerListing,
    this.myBuyerListing,
  });

  /// Defaults used when no prefs have been written yet.
  factory LocalStateSnapshot.defaults() => LocalStateSnapshot(
        credits: 5,
        // New installs can buy and sell; browsing starts as seller.
        enabledRoles: const {UserRole.seller, UserRole.buyer},
        activeRole: UserRole.seller,
        displayName: '',
        location: '',
        tagline: '',
        buyingInterests: const [],
        sellingInterests: const ['Maize'],
        unlockedListingIds: <String>{},
      );

  final int credits;

  /// Roles the user has enabled (capabilities). Always non-empty.
  final Set<UserRole> enabledRoles;

  /// Role used for Discover/Home browsing (must be in [enabledRoles]).
  final UserRole activeRole;

  final String displayName;
  final String location;

  /// Short public blurb shown on Discover cards.
  final String tagline;

  final List<String> buyingInterests;
  final List<String> sellingInterests;
  final Set<String> unlockedListingIds;
  final Listing? mySellerListing;
  final Listing? myBuyerListing;
}

/// Reads/writes local MVP state via [SharedPreferences].
class LocalStateStore {
  LocalStateStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kCredits = 'mvp.credits';
  /// Legacy single-role key; still written as [activeRole] for older builds.
  static const _kRole = 'mvp.role';
  static const _kEnabledRoles = 'mvp.enabledRoles';
  static const _kActiveRole = 'mvp.activeRole';
  static const _kDisplayName = 'mvp.displayName';
  static const _kLocation = 'mvp.location';
  static const _kTagline = 'mvp.tagline';
  static const _kBuyingInterests = 'mvp.buyingInterests';
  static const _kSellingInterests = 'mvp.sellingInterests';
  static const _kUnlockedListingIds = 'mvp.unlockedListingIds';
  static const _kMySellerListing = 'mvp.mySellerListing';
  static const _kMyBuyerListing = 'mvp.myBuyerListing';

  static Future<LocalStateStore> open() async {
    return LocalStateStore(await SharedPreferences.getInstance());
  }

  /// Loads persisted fields; uses [LocalStateSnapshot.defaults] when keys are absent.
  LocalStateSnapshot load() {
    final defaults = LocalStateSnapshot.defaults();
    final legacyRole = _parseRole(_prefs.getString(_kRole)) ?? defaults.activeRole;
    final enabledRoles = _loadEnabledRoles(legacyRole, defaults.enabledRoles);
    final activePreferred = _parseRole(_prefs.getString(_kActiveRole)) ??
        legacyRole;
    final activeRole = enabledRoles.contains(activePreferred)
        ? activePreferred
        : (enabledRoles.contains(UserRole.seller)
            ? UserRole.seller
            : enabledRoles.first);

    return LocalStateSnapshot(
      credits: _prefs.getInt(_kCredits) ?? defaults.credits,
      enabledRoles: enabledRoles,
      activeRole: activeRole,
      displayName: _prefs.getString(_kDisplayName) ?? defaults.displayName,
      location: _prefs.getString(_kLocation) ?? defaults.location,
      tagline: _prefs.getString(_kTagline) ?? defaults.tagline,
      buyingInterests:
          _prefs.getStringList(_kBuyingInterests) ?? defaults.buyingInterests,
      // Only seed Maize when the key has never been written.
      sellingInterests: _prefs.containsKey(_kSellingInterests)
          ? (_prefs.getStringList(_kSellingInterests) ?? const [])
          : defaults.sellingInterests,
      unlockedListingIds:
          (_prefs.getStringList(_kUnlockedListingIds) ?? const []).toSet(),
      mySellerListing: _readListing(_kMySellerListing),
      myBuyerListing: _readListing(_kMyBuyerListing),
    );
  }

  Future<void> save(LocalStateSnapshot snapshot) async {
    final enabled = snapshot.enabledRoles.isEmpty
        ? {snapshot.activeRole}
        : snapshot.enabledRoles;
    final active = enabled.contains(snapshot.activeRole)
        ? snapshot.activeRole
        : enabled.first;

    await _prefs.setInt(_kCredits, snapshot.credits);
    await _prefs.setStringList(
      _kEnabledRoles,
      enabled.map((r) => r.name).toList()..sort(),
    );
    await _prefs.setString(_kActiveRole, active.name);
    // Keep legacy key in sync so older builds still see a single role.
    await _prefs.setString(_kRole, active.name);
    await _prefs.setString(_kDisplayName, snapshot.displayName);
    await _prefs.setString(_kLocation, snapshot.location);
    await _prefs.setString(_kTagline, snapshot.tagline);
    await _prefs.setStringList(
      _kBuyingInterests,
      List<String>.from(snapshot.buyingInterests),
    );
    await _prefs.setStringList(
      _kSellingInterests,
      List<String>.from(snapshot.sellingInterests),
    );
    await _prefs.setStringList(
      _kUnlockedListingIds,
      snapshot.unlockedListingIds.toList(),
    );
    await _writeListing(_kMySellerListing, snapshot.mySellerListing);
    await _writeListing(_kMyBuyerListing, snapshot.myBuyerListing);
  }

  Set<UserRole> _loadEnabledRoles(
    UserRole legacyRole,
    Set<UserRole> defaults,
  ) {
    final raw = _prefs.getStringList(_kEnabledRoles);
    if (raw == null) {
      // New install: no role keys yet → both capabilities.
      // Legacy exclusive role: only mvp.role was written.
      if (!_prefs.containsKey(_kRole)) {
        return {...defaults};
      }
      return {legacyRole};
    }
    final parsed = raw.map(_parseRole).whereType<UserRole>().toSet();
    if (parsed.isEmpty) return {...defaults};
    return parsed;
  }

  UserRole? _parseRole(String? name) {
    if (name == UserRole.buyer.name) return UserRole.buyer;
    if (name == UserRole.seller.name) return UserRole.seller;
    return null;
  }

  Listing? _readListing(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Listing.fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeListing(String key, Listing? listing) async {
    if (listing == null) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, jsonEncode(listing.toJson()));
  }
}

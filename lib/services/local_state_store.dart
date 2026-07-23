import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:agrilumina/models/forum_post.dart';
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
  static const _kDeviceId = 'mvp.deviceId';
  static const _kForumThreadCache = 'mvp.forumThreadCache';
  static const _kForumReportedIds = 'mvp.forumReportedIds';
  static const _kForumMyPosts = 'mvp.forumMyPosts';
  static const _kForumOutbox = 'mvp.forumOutbox';
  static const _kListingSyncState = 'mvp.listingSyncState';
  static const _kDiscoverCachePrefix = 'mvp.discoverCache.';
  static const _kUnlockedPhones = 'mvp.unlockedPhones';

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

  /// Stable anonymous device identity (created once, then reused).
  ///
  /// Acts as this device's secret for backend writes (forum posts, later
  /// listings sync) — never shown in any public payload.
  String deviceId() {
    final existing = _prefs.getString(_kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    // Fire-and-forget: the value stays stable in memory either way.
    _prefs.setString(_kDeviceId, generated);
    return generated;
  }

  /// Last fetched page of forum threads, for offline display.
  List<ForumPost> loadForumThreadCache() => _readForumPosts(_kForumThreadCache);

  Future<void> saveForumThreadCache(List<ForumPost> threads) =>
      _writeForumPosts(_kForumThreadCache, threads);

  /// Posts this device has reported as spam (to disable the button locally).
  Set<String> loadReportedForumPostIds() =>
      (_prefs.getStringList(_kForumReportedIds) ?? const []).toSet();

  Future<void> saveReportedForumPostIds(Set<String> ids) =>
      _prefs.setStringList(_kForumReportedIds, ids.toList()..sort());

  /// Posts authored on this device (including ones held as pending review,
  /// which never appear in the public feed).
  List<ForumPost> loadMyForumPosts() => _readForumPosts(_kForumMyPosts);

  Future<void> saveMyForumPosts(List<ForumPost> posts) =>
      _writeForumPosts(_kForumMyPosts, posts);

  /// Queued forum writes awaiting the backend, oldest first.
  List<Map<String, Object?>> loadForumOutbox() {
    final raw = _prefs.getString(_kForumOutbox);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => Map<String, Object?>.from(m))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveForumOutbox(List<Map<String, Object?>> ops) =>
      _prefs.setString(_kForumOutbox, jsonEncode(ops));

  /// Per-role pending listing sync ops, e.g. {"seller": {"op": "upsert",
  /// "failed": false}}. Absent role = synced.
  Map<String, Map<String, Object?>> loadListingSyncState() {
    final raw = _prefs.getString(_kListingSyncState);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (k, v) => MapEntry(
          k as String,
          v is Map ? Map<String, Object?>.from(v) : <String, Object?>{},
        ),
      );
    } on FormatException {
      return {};
    }
  }

  Future<void> saveListingSyncState(
    Map<String, Map<String, Object?>> state,
  ) =>
      _prefs.setString(_kListingSyncState, jsonEncode(state));

  /// Last successful Discover fetch for a counterpart role.
  List<Listing> loadDiscoverCache(UserRole role) {
    final raw = _prefs.getString('$_kDiscoverCachePrefix${role.name}');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => Listing.fromJson(Map<String, Object?>.from(m)))
          .whereType<Listing>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveDiscoverCache(UserRole role, List<Listing> listings) =>
      _prefs.setString(
        '$_kDiscoverCachePrefix${role.name}',
        jsonEncode(listings.map((l) => l.toJson()).toList()),
      );

  /// Phones released by the contact endpoint, keyed by remote listing id.
  Map<String, String> loadUnlockedPhones() {
    final raw = _prefs.getString(_kUnlockedPhones);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry(k as String, v as String? ?? ''));
    } on FormatException {
      return {};
    }
  }

  Future<void> saveUnlockedPhones(Map<String, String> phones) =>
      _prefs.setString(_kUnlockedPhones, jsonEncode(phones));

  List<ForumPost> _readForumPosts(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ForumPost.fromJson(Map<String, Object?>.from(m)))
          .whereType<ForumPost>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeForumPosts(String key, List<ForumPost> posts) =>
      _prefs.setString(
        key,
        jsonEncode(posts.map((p) => p.toJson()).toList()),
      );

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

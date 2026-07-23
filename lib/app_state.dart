import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';
import 'package:agrilumina/data/listing_copy_keys.dart';
import 'package:agrilumina/data/mock_listings.dart';
import 'package:agrilumina/models/forum_outbox.dart';
import 'package:agrilumina/models/forum_post.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/listing_sync.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/connectivity_service.dart';
import 'package:agrilumina/services/forum_api.dart';
import 'package:agrilumina/services/listings_api.dart';
import 'package:agrilumina/services/local_state_store.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:agrilumina/utils/geo.dart';
import 'package:uuid/uuid.dart';

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
    ListingsApi? listingsApi,
    ForumApi? forumApi,
    ConnectivityService? connectivity,
  })  : enabledRoles = _initEnabledRoles(enabledRoles, activeRole, role),
        activeRole = _initActiveRole(enabledRoles, activeRole, role),
        buyingInterests = List<String>.from(buyingInterests ?? const []),
        sellingInterests =
            List<String>.from(sellingInterests ?? const ['Maize']),
        unlockedListingIds = {...?unlockedListingIds},
        _seedListings = List.unmodifiable(listings ?? mockListings),
        _locationService = locationService ?? PluginLocationService(),
        _store = store,
        _listingsApi = listingsApi ?? HttpListingsApi(),
        _forumApi = forumApi ?? HttpForumApi(),
        _connectivity = connectivity {
    _connectivitySub = _connectivity?.onReconnected.listen((_) {
      unawaited(syncPendingListings());
      unawaited(syncForumOutbox());
    });
  }

  /// Builds [AppState] from persisted MVP fields (and keeps saving mutations).
  factory AppState.fromStore(
    LocalStateStore store, {
    LocationService? locationService,
    List<Listing>? listings,
    ListingsApi? listingsApi,
    ForumApi? forumApi,
    ConnectivityService? connectivity,
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
      listingsApi: listingsApi,
      forumApi: forumApi,
      connectivity: connectivity,
    );
  }

  static const int unlockContactCost = 1;
  static const int homeTabIndex = 0;
  static const int discoverTabIndex = 1;
  static const int forumTabIndex = 2;

  /// Bottom-nav indices: 0 Home, 1 Discover, 2 Forum, 3 Credits, 4 Profile.
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
  final ListingsApi _listingsApi;
  final ForumApi _forumApi;
  final ConnectivityService? _connectivity;
  StreamSubscription<void>? _connectivitySub;
  Future<void>? _persistFuture;

  /// Seed mocks are shown only when remote is unreachable and no cache exists.
  static const bool useSeedFallback = true;

  Map<UserRole, PendingListingSync>? _listingSyncOps;
  bool _syncingListings = false;

  List<Listing>? _remoteListings;
  UserRole? _remoteListingsRole;
  bool discoverLoading = false;

  /// True when the last Discover refresh attempt failed (serving cache/seeds).
  bool discoverOffline = false;

  Map<String, String>? _unlockedPhones;

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

  /// Discover feed for the active counterpart role: live remote data when
  /// the last fetch succeeded, else the per-role cache, else seed mocks.
  List<Listing> get _feedListings {
    final counterpart = activeRole.counterpart;
    if (_remoteListings != null && _remoteListingsRole == counterpart) {
      return _remoteListings!;
    }
    final cached = _store?.loadDiscoverCache(counterpart) ?? const [];
    if (cached.isNotEmpty) return cached;
    return useSeedFallback ? _seedListings : const [];
  }

  /// Where the current feed comes from (drives the Discover banner).
  DiscoverFeedSource get discoverFeedSource {
    final counterpart = activeRole.counterpart;
    if (_remoteListings != null && _remoteListingsRole == counterpart) {
      return DiscoverFeedSource.remote;
    }
    final cached = _store?.loadDiscoverCache(counterpart) ?? const [];
    if (cached.isNotEmpty) return DiscoverFeedSource.cache;
    return DiscoverFeedSource.seed;
  }

  /// Feed listings plus any published local listings. Own remote rows are
  /// excluded server-side, so local `me-*` entries never duplicate.
  List<Listing> get listings => [
        ..._feedListings,
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

  // --- Forum (public message board) ---

  /// Stable anonymous device identity used as the author secret for backend
  /// writes. Ephemeral when no store is attached (in-memory test states).
  String get deviceId => _deviceId ??= _store?.deviceId() ?? _ephemeralId();

  String? _deviceId;

  static String _ephemeralId() =>
      'mem-${DateTime.now().microsecondsSinceEpoch}';

  Set<String>? _reportedForumPostIds;

  /// Posts this device has reported as spam.
  Set<String> get reportedForumPostIds => _reportedForumPostIds ??=
      _store?.loadReportedForumPostIds() ?? <String>{};

  bool isForumPostReported(String postId) =>
      reportedForumPostIds.contains(postId);

  void markForumPostReported(String postId) {
    if (!reportedForumPostIds.add(postId)) return;
    notifyListeners();
    final store = _store;
    if (store != null) {
      unawaited(store.saveReportedForumPostIds(reportedForumPostIds));
    }
  }

  List<ForumPost>? _myForumPosts;

  /// Posts authored on this device, newest first (including pending review).
  List<ForumPost> get myForumPosts =>
      _myForumPosts ??= List.of(_store?.loadMyForumPosts() ?? const []);

  bool isMyForumPost(String postId) =>
      myForumPosts.any((p) => p.id == postId);

  void addMyForumPost(ForumPost post) {
    myForumPosts.insert(0, post);
    notifyListeners();
    _persistMyForumPosts();
  }

  void removeMyForumPost(String postId) {
    final before = myForumPosts.length;
    myForumPosts.removeWhere((p) => p.id == postId);
    if (myForumPosts.length == before) return;
    notifyListeners();
    _persistMyForumPosts();
  }

  void _persistMyForumPosts() {
    final store = _store;
    if (store != null) {
      unawaited(store.saveMyForumPosts(myForumPosts));
    }
  }

  /// Last fetched thread page for offline display.
  List<ForumPost> get cachedForumThreads =>
      _store?.loadForumThreadCache() ?? const [];

  void cacheForumThreads(List<ForumPost> threads) {
    final store = _store;
    if (store != null) {
      unawaited(store.saveForumThreadCache(threads));
    }
  }

  // --- Forum outbox (offline posting) ---

  List<PendingForumOp>? _forumOutbox;
  bool _syncingForum = false;
  Timer? _forumRetryTimer;
  int _droppedForumReplies = 0;

  /// Queued forum writes, oldest first.
  List<PendingForumOp> get forumOutbox => _forumOutbox ??=
      (_store?.loadForumOutbox() ?? const [])
          .map(PendingForumOp.fromJson)
          .whereType<PendingForumOp>()
          .toList();

  /// Queued posts/replies as display posts, newest first.
  List<ForumPost> get queuedForumPosts => forumOutbox.reversed
      .map((op) => op.toDisplayPost())
      .whereType<ForumPost>()
      .toList();

  /// True when [postId]'s queued op failed its last replay attempt.
  bool isQueuedOpFailed(String postId) =>
      forumOutbox.any((op) => op.id == postId && op.failed);

  void _persistForumOutbox() {
    final store = _store;
    if (store != null) {
      unawaited(
        store.saveForumOutbox(
          forumOutbox.map((op) => op.toJson()).toList(),
        ),
      );
    }
  }

  /// Queues a post or reply composed while offline. Returns the display
  /// post (status queued) for immediate UI feedback.
  ForumPost queueForumPost({required String body, String? parentId}) {
    final op = PendingForumOp(
      kind: parentId == null ? ForumOutboxKind.post : ForumOutboxKind.reply,
      id: 'queued-${const Uuid().v4()}',
      body: body,
      authorName: displayName.trim(),
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    forumOutbox.add(op);
    _persistForumOutbox();
    notifyListeners();
    unawaited(syncForumOutbox());
    return op.toDisplayPost()!;
  }

  /// Queues a spam report and marks the post reported immediately
  /// (idempotent server-side; sent on the next flush).
  void queueForumReport(String postId) {
    if (isForumPostReported(postId)) return;
    markForumPostReported(postId);
    forumOutbox.add(
      PendingForumOp(
        kind: ForumOutboxKind.report,
        id: 'queued-${const Uuid().v4()}',
        postId: postId,
        createdAt: DateTime.now(),
      ),
    );
    _persistForumOutbox();
    unawaited(syncForumOutbox());
  }

  /// Returns and clears the count of queued replies dropped because their
  /// parent vanished (surfaced once in the forum UI).
  int takeDroppedForumReplyNotice() {
    final n = _droppedForumReplies;
    _droppedForumReplies = 0;
    return n;
  }

  /// Replays the outbox FIFO. Offline and rate limits stop the pass (a 429
  /// arms a retry timer); duplicates and vanished parents drop their op;
  /// other API errors mark the op failed and continue so independent ops
  /// are not starved.
  Future<void> syncForumOutbox() async {
    if (_syncingForum || forumOutbox.isEmpty) return;
    _syncingForum = true;
    var changed = false;
    try {
      for (final op in List.of(forumOutbox)) {
        try {
          switch (op.kind) {
            case ForumOutboxKind.post:
            case ForumOutboxKind.reply:
              final post = await _forumApi.createPost(
                deviceId: deviceId,
                authorName: op.authorName,
                body: op.body,
                parentId: op.parentId,
              );
              forumOutbox.remove(op);
              addMyForumPost(post);
              changed = true;
            case ForumOutboxKind.report:
              await _forumApi.reportPost(
                deviceId: deviceId,
                postId: op.postId ?? '',
              );
              forumOutbox.remove(op);
              changed = true;
          }
        } on ForumOfflineException {
          if (op.failed) {
            op.failed = false;
            changed = true;
          }
          break; // everything behind shares the dead link
        } on ForumRateLimitedException catch (e) {
          if (op.failed) {
            op.failed = false;
            changed = true;
          }
          _forumRetryTimer?.cancel();
          _forumRetryTimer = Timer(
            Duration(seconds: e.retryAfterSeconds.clamp(5, 3600)),
            () => unawaited(syncForumOutbox()),
          );
          break; // respect the server's backoff for the whole queue
        } on ForumDuplicateException {
          // Already server-side (crash-safe at-least-once dedupe).
          forumOutbox.remove(op);
          changed = true;
        } on ForumApiException catch (e) {
          if (op.kind == ForumOutboxKind.report ||
              (e.statusCode == 400 && e.error == 'invalid_parent')) {
            if (op.kind != ForumOutboxKind.report) _droppedForumReplies++;
            forumOutbox.remove(op);
          } else if (!op.failed) {
            op.failed = true;
          }
          changed = true;
        } on Exception {
          if (!op.failed) {
            op.failed = true;
            changed = true;
          }
        }
      }
    } finally {
      _syncingForum = false;
    }
    if (changed) {
      _persistForumOutbox();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _connectivity?.dispose();
    _forumRetryTimer?.cancel();
    super.dispose();
  }

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
      unawaited(refreshDiscover());
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
    // The counterpart changed; the remote feed is role-filtered server-side.
    if (_remoteListingsRole != value.counterpart) {
      unawaited(refreshDiscover());
    }
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

  // --- Remote listings sync (#25) ---

  Map<UserRole, PendingListingSync> get _syncOps =>
      _listingSyncOps ??= _loadSyncOps();

  Map<UserRole, PendingListingSync> _loadSyncOps() {
    final raw = _store?.loadListingSyncState() ?? const {};
    final ops = <UserRole, PendingListingSync>{};
    for (final entry in raw.entries) {
      final role = entry.key == UserRole.seller.name
          ? UserRole.seller
          : entry.key == UserRole.buyer.name
              ? UserRole.buyer
              : null;
      final op = PendingListingSync.fromJson(entry.value);
      if (role != null && op != null) ops[role] = op;
    }
    return ops;
  }

  void _persistSyncOps() {
    final store = _store;
    if (store == null) return;
    unawaited(
      store.saveListingSyncState(
        _syncOps.map((role, op) => MapEntry(role.name, op.toJson())),
      ),
    );
  }

  /// Sync status for one role's listing.
  ListingSyncStatus listingSyncStatusFor(UserRole role) {
    final op = _syncOps[role];
    if (op == null) return ListingSyncStatus.synced;
    return op.failed ? ListingSyncStatus.failed : ListingSyncStatus.pending;
  }

  /// Sync status for the active role (drives the Profile chip).
  ListingSyncStatus get myListingSyncStatus =>
      listingSyncStatusFor(activeRole);

  void _enqueueListingOp(UserRole role, PendingListingOp op) {
    _syncOps[role] = PendingListingSync(op: op);
    _persistSyncOps();
    notifyListeners();
  }

  Listing? _listingFor(UserRole role) =>
      role == UserRole.seller ? mySellerListing : myBuyerListing;

  /// Flushes queued listing ops to the backend. Offline keeps ops pending;
  /// API errors mark them failed (both retried on the next trigger: app
  /// start, publish/clear, Discover refresh, or a failed-chip tap).
  Future<void> syncPendingListings() async {
    if (_syncingListings || _syncOps.isEmpty) return;
    _syncingListings = true;
    var changed = false;
    try {
      for (final role in UserRole.values) {
        final pending = _syncOps[role];
        if (pending == null) continue;
        // The listing may have been cleared since an upsert was queued.
        final effectiveOp = pending.op == PendingListingOp.upsert &&
                _listingFor(role) == null
            ? PendingListingOp.delete
            : pending.op;
        try {
          if (effectiveOp == PendingListingOp.upsert) {
            await _listingsApi.upsertListing(
              deviceId: deviceId,
              listing: _listingFor(role)!,
            );
          } else {
            await _listingsApi.deleteListing(deviceId: deviceId, role: role);
          }
          _syncOps.remove(role);
          changed = true;
        } on ListingsOfflineException {
          if (pending.failed) {
            pending.failed = false;
            changed = true;
          }
        } on Exception {
          if (!pending.failed) {
            pending.failed = true;
            changed = true;
          }
        }
      }
    } finally {
      _syncingListings = false;
    }
    if (changed) {
      _persistSyncOps();
      notifyListeners();
    }
  }

  // --- Remote Discover (#26) ---

  /// Refreshes the Discover feed: flush pending sync, refresh GPS, fetch
  /// remote counterparts. Failure keeps the previous feed and flips
  /// [discoverOffline].
  Future<void> refreshDiscover() async {
    unawaited(syncPendingListings());
    if (discoverLoading) return;
    discoverLoading = true;
    notifyListeners();
    await refreshLocation();
    final counterpart = activeRole.counterpart;
    try {
      final fetched = await _listingsApi.fetchListings(
        role: counterpart,
        excludeDeviceId: deviceId,
        lat: userPosition?.latitude,
        lon: userPosition?.longitude,
        radiusKm: userPosition == null ? null : ListingsConfig.radiusKm,
      );
      _remoteListings = fetched;
      _remoteListingsRole = counterpart;
      discoverOffline = false;
      final store = _store;
      if (store != null) {
        unawaited(store.saveDiscoverCache(counterpart, fetched));
      }
    } on Exception {
      discoverOffline = true;
    }
    discoverLoading = false;
    notifyListeners();
  }

  // --- Contact unlock (#26) ---

  Map<String, String> get _phones =>
      _unlockedPhones ??= _store?.loadUnlockedPhones() ?? {};

  /// Phone to display for [listing]: local value (seeds, own listings) or
  /// the cached contact-endpoint result.
  String phoneFor(Listing listing) =>
      listing.phone.isNotEmpty ? listing.phone : _phones[listing.id] ?? '';

  /// Unlocks contact for [listingId]. Spends [unlockContactCost] only when
  /// the phone is actually obtained; failures never consume a credit.
  Future<ContactUnlockResult> unlockListingContact(String listingId) async {
    final matches = listings.where((l) => l.id == listingId);
    if (matches.isEmpty) {
      return const ContactUnlockResult(ContactUnlockStatus.notFound);
    }
    final listing = matches.first;
    final alreadyUnlocked = unlockedListingIds.contains(listingId);

    // Phone available locally (seeds, own listings, previously cached).
    if (phoneFor(listing).isNotEmpty) {
      if (!alreadyUnlocked) {
        if (credits < unlockContactCost) {
          return const ContactUnlockResult(ContactUnlockStatus.noCredits);
        }
        credits -= unlockContactCost;
        unlockedListingIds.add(listingId);
        notifyListeners();
        _persist();
      }
      return ContactUnlockResult(
        ContactUnlockStatus.unlocked,
        phoneFor(listing),
      );
    }

    // Remote listing: fetch the phone first, charge only on success. An
    // already-unlocked listing whose cached phone was lost refetches free.
    if (!alreadyUnlocked && credits < unlockContactCost) {
      return const ContactUnlockResult(ContactUnlockStatus.noCredits);
    }
    try {
      final phone = await _listingsApi.fetchContactPhone(
        deviceId: deviceId,
        listingId: listingId,
      );
      if (!alreadyUnlocked) {
        credits -= unlockContactCost;
        unlockedListingIds.add(listingId);
      }
      _phones[listingId] = phone;
      final store = _store;
      if (store != null) {
        unawaited(store.saveUnlockedPhones(_phones));
      }
      notifyListeners();
      _persist();
      return ContactUnlockResult(ContactUnlockStatus.unlocked, phone);
    } on ListingsOfflineException {
      return const ContactUnlockResult(ContactUnlockStatus.offline);
    } on ContactRateLimitedException {
      return const ContactUnlockResult(ContactUnlockStatus.rateLimited);
    } on ListingNotFoundException {
      return const ContactUnlockResult(ContactUnlockStatus.notFound);
    } on Exception {
      return const ContactUnlockResult(ContactUnlockStatus.error);
    }
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
    _enqueueListingOp(activeRole, PendingListingOp.upsert);
    unawaited(syncPendingListings());
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
    _enqueueListingOp(activeRole, PendingListingOp.delete);
    unawaited(syncPendingListings());
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

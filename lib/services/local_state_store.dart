import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/models/user_role.dart';

/// Snapshot of MVP fields persisted across cold starts.
class LocalStateSnapshot {
  const LocalStateSnapshot({
    required this.credits,
    required this.role,
    required this.displayName,
    required this.location,
    required this.buyingInterests,
    required this.sellingInterests,
    required this.unlockedListingIds,
  });

  /// Defaults used when no prefs have been written yet.
  factory LocalStateSnapshot.defaults() => LocalStateSnapshot(
        credits: 5,
        role: UserRole.seller,
        displayName: '',
        location: '',
        buyingInterests: const [],
        sellingInterests: const ['Maize'],
        unlockedListingIds: <String>{},
      );

  final int credits;
  final UserRole role;
  final String displayName;
  final String location;
  final List<String> buyingInterests;
  final List<String> sellingInterests;
  final Set<String> unlockedListingIds;
}

/// Reads/writes local MVP state via [SharedPreferences].
class LocalStateStore {
  LocalStateStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kCredits = 'mvp.credits';
  static const _kRole = 'mvp.role';
  static const _kDisplayName = 'mvp.displayName';
  static const _kLocation = 'mvp.location';
  static const _kBuyingInterests = 'mvp.buyingInterests';
  static const _kSellingInterests = 'mvp.sellingInterests';
  static const _kUnlockedListingIds = 'mvp.unlockedListingIds';

  static Future<LocalStateStore> open() async {
    return LocalStateStore(await SharedPreferences.getInstance());
  }

  /// Loads persisted fields; uses [LocalStateSnapshot.defaults] when keys are absent.
  LocalStateSnapshot load() {
    final defaults = LocalStateSnapshot.defaults();
    final roleName = _prefs.getString(_kRole);
    final role = roleName == UserRole.buyer.name
        ? UserRole.buyer
        : roleName == UserRole.seller.name
            ? UserRole.seller
            : defaults.role;

    return LocalStateSnapshot(
      credits: _prefs.getInt(_kCredits) ?? defaults.credits,
      role: role,
      displayName: _prefs.getString(_kDisplayName) ?? defaults.displayName,
      location: _prefs.getString(_kLocation) ?? defaults.location,
      buyingInterests:
          _prefs.getStringList(_kBuyingInterests) ?? defaults.buyingInterests,
      // Only seed Maize when the key has never been written.
      sellingInterests: _prefs.containsKey(_kSellingInterests)
          ? (_prefs.getStringList(_kSellingInterests) ?? const [])
          : defaults.sellingInterests,
      unlockedListingIds:
          (_prefs.getStringList(_kUnlockedListingIds) ?? const []).toSet(),
    );
  }

  Future<void> save(LocalStateSnapshot snapshot) async {
    await _prefs.setInt(_kCredits, snapshot.credits);
    await _prefs.setString(_kRole, snapshot.role.name);
    await _prefs.setString(_kDisplayName, snapshot.displayName);
    await _prefs.setString(_kLocation, snapshot.location);
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
  }
}

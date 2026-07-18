import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/screens/listing_detail_screen.dart';
import 'package:agrilumina/utils/crop_filter.dart';
import 'package:agrilumina/utils/geo.dart';
import 'package:agrilumina/utils/listing_search.dart';
import 'package:agrilumina/utils/locale_format.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

export 'package:agrilumina/data/crop_vocabulary.dart' show discoverCropFilters;

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  DiscoverCropMode _cropMode = DiscoverCropMode.softInterest;
  String? _manualCrop;
  UserRole? _trackedRole;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncRole(UserRole role) {
    if (_trackedRole == role) return;
    _trackedRole = role;
    _cropMode = DiscoverCropMode.softInterest;
    _manualCrop = null;
  }

  void _onCropSelected(String? crop) {
    setState(() {
      if (crop == null) {
        _cropMode = DiscoverCropMode.showAll;
        _manualCrop = null;
        return;
      }
      if (_cropMode == DiscoverCropMode.manualCrop && _manualCrop == crop) {
        _cropMode = DiscoverCropMode.softInterest;
        _manualCrop = null;
        return;
      }
      _cropMode = DiscoverCropMode.manualCrop;
      _manualCrop = crop;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final l10n = context.l10n;
        _syncRole(state.activeRole);

        final list = state.nearbyCounterparts;
        final interests = state.relevantInterests;
        final cropFiltered = filterListingsByCrop(
          listings: list,
          mode: _cropMode,
          manualCrop: _manualCrop,
          relevantInterests: interests,
        );
        final filtered = filterListingsByQuery(
          cropFiltered,
          _searchController.text,
          l10n: l10n,
        );

        final interestSoftActive = isInterestSoftFilterActive(
          mode: _cropMode,
          relevantInterests: interests,
        );
        final title = state.activeRole == UserRole.seller
            ? l10n.findBuyers
            : l10n.findSellers;
        final counterpart = l10n.counterpartPlural(state.activeRole);

        return Scaffold(
          appBar: AppBar(
            leading: const BrandHomeLeading(),
            title: Text(title),
            actions: [
              if (state.locationLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: l10n.refreshLocation,
                  onPressed: state.refreshLocation,
                  icon: const Icon(Icons.my_location),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    l10n.creditsCount(state.credits),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LocationBanner(state: state),
              // Looking-for switcher only when both roles are enabled.
              // With a single capability, activeRole follows that role and
              // the AppBar title already says Find Buyers / Find Sellers.
              if (state.enabledRoles.length > 1)
                _LookingForSwitcher(
                  activeRole: state.activeRole,
                  onChanged: state.setActiveRole,
                ),
              if (list.isNotEmpty) ...[
                _CropFilterBar(
                  crops: discoverCropFilters,
                  mode: _cropMode,
                  selectedCrop: _manualCrop,
                  interestSoftActive: interestSoftActive,
                  onSelected: _onCropSelected,
                ),
                if (interestSoftActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      interestFilterHelperText(l10n, state.activeRole),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                _DiscoverSearchField(
                  controller: _searchController,
                  counterpart: counterpart,
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ],
              Expanded(
                child: _buildBody(
                  list: list,
                  cropFiltered: cropFiltered,
                  filtered: filtered,
                  cropMode: _cropMode,
                  manualCrop: _manualCrop,
                  interestSoftActive: interestSoftActive,
                  searchQuery: _searchController.text,
                  counterpart: counterpart,
                  state: state,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required List<Listing> list,
    required List<Listing> cropFiltered,
    required List<Listing> filtered,
    required DiscoverCropMode cropMode,
    required String? manualCrop,
    required bool interestSoftActive,
    required String searchQuery,
    required String counterpart,
    required AppState state,
  }) {
    final l10n = context.l10n;

    if (list.isEmpty) {
      return Center(
        child: Text(l10n.noCounterpartsNearbyYet(counterpart)),
      );
    }

    if (cropFiltered.isEmpty) {
      final message =
          cropMode == DiscoverCropMode.manualCrop && manualCrop != null
              ? l10n.noCropCounterpartsNearby(
                  l10n.localizedCrop(manualCrop),
                  counterpart,
                )
              : interestSoftActive
                  ? l10n.noCounterpartsForInterests(counterpart)
                  : l10n.noCounterpartsNearby(counterpart);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final trimmedQuery = searchQuery.trim();
    if (filtered.isEmpty) {
      final scope = cropMode == DiscoverCropMode.manualCrop &&
              manualCrop != null
          ? '${l10n.localizedCrop(manualCrop)} $counterpart'
          : counterpart;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.noSearchMatches(trimmedQuery, scope),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final listing = filtered[index];
        return _ListingTile(
          listing: listing,
          unlocked: state.isUnlocked(listing.id),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ListingDetailScreen(
                  listingId: listing.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Discover browse lens: choose counterparts (Buyers vs Sellers).
///
/// Selecting Buyers sets [UserRole.seller] (you sell → find buyers);
/// selecting Sellers sets [UserRole.buyer].
class _LookingForSwitcher extends StatelessWidget {
  const _LookingForSwitcher({
    required this.activeRole,
    required this.onChanged,
  });

  final UserRole activeRole;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      key: const Key('discover_looking_for'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.lookingFor,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<UserRole>(
            segments: [
              ButtonSegment<UserRole>(
                value: UserRole.seller,
                label: Text(l10n.lookingForBuyers),
                icon: const Icon(Icons.storefront),
              ),
              ButtonSegment<UserRole>(
                value: UserRole.buyer,
                label: Text(l10n.lookingForSellers),
                icon: const Icon(Icons.agriculture),
              ),
            ],
            selected: {activeRole},
            onSelectionChanged: (roles) => onChanged(roles.first),
          ),
        ],
      ),
    );
  }
}

class _DiscoverSearchField extends StatelessWidget {
  const _DiscoverSearchField({
    required this.controller,
    required this.counterpart,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String counterpart;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: TextField(
        key: const Key('discover_search_field'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.searchCounterparts(counterpart),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.clearSearch,
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _CropFilterBar extends StatelessWidget {
  const _CropFilterBar({
    required this.crops,
    required this.mode,
    required this.selectedCrop,
    required this.interestSoftActive,
    required this.onSelected,
  });

  final List<String> crops;
  final DiscoverCropMode mode;
  final String? selectedCrop;
  final bool interestSoftActive;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allSelected = mode == DiscoverCropMode.showAll ||
        (mode == DiscoverCropMode.softInterest && !interestSoftActive);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.filterAll),
              selected: allSelected,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...crops.map(
            (crop) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(l10n.localizedCrop(crop)),
                selected:
                    mode == DiscoverCropMode.manualCrop && selectedCrop == crop,
                onSelected: (_) => onSelected(crop),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final usingGps = state.usingGps;
    final status = state.locationBannerStatus;
    final background = usingGps
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = usingGps
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    final placeLabel = switch (state.deviceLocationKind) {
      ApproximateLocationKind.nearSampleArea => l10n.nearSampleArea,
      ApproximateLocationKind.currentLocation => l10n.yourCurrentLocation,
    };

    final bannerText = usingGps
        ? l10n.nearYouBanner(placeLabel)
        : (status != null
            ? l10n.locationBannerForStatus(status)
            : l10n.sampleListingsEnableLocation);

    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              usingGps ? Icons.location_on : Icons.location_off_outlined,
              size: 20,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bannerText,
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({
    required this.listing,
    required this.unlocked,
    required this.onTap,
  });

  final Listing listing;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cropLabel = l10n.localizedCrop(listing.crop);
    final tagline = listing.tagline.trim();
    final details = l10n.listingSubtitle(
      cropLabel,
      l10n.localizedListingQuantity(listing),
      formatDistanceKmLocalized(l10n, listing.distanceKm),
      l10n.localizedListingLastActive(listing),
    );
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          cropLabel.isEmpty ? '?' : cropLabel[0].toUpperCase(),
        ),
      ),
      title: Text(context.l10n.listingDisplayName(listing)),
      subtitle: tagline.isEmpty
          ? Text(details)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tagline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(details),
              ],
            ),
      isThreeLine: true,
      trailing: Icon(
        unlocked ? Icons.lock_open : Icons.lock_outline,
        color: unlocked
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}

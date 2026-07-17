import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/screens/listing_detail_screen.dart';
import 'package:agrilumina/utils/geo.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final list = state.nearbyCounterparts;
        final title = state.role == UserRole.seller
            ? 'Nearby buyers'
            : 'Nearby sellers';

        return Scaffold(
          appBar: AppBar(
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
                  tooltip: 'Refresh location',
                  onPressed: state.refreshLocation,
                  icon: const Icon(Icons.my_location),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '${state.credits} credits',
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
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          'No ${state.role.counterpart.label.toLowerCase()}s nearby yet.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final listing = list[index];
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
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usingGps = state.usingGps;
    final message = state.locationBannerMessage;
    final background = usingGps
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = usingGps
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

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
                usingGps
                    ? 'Near you · ${state.deviceLocationLabel}'
                    : (message ??
                        'Using $bugobeLocationLabel · enable location for nearby distances'),
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
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          listing.crop.isEmpty ? '?' : listing.crop[0].toUpperCase(),
        ),
      ),
      title: Text(listing.name),
      subtitle: Text(
        '${listing.crop} · ${listing.quantityHint}\n'
        '${formatDistanceKm(listing.distanceKm)} · ${listing.lastActiveLabel}',
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

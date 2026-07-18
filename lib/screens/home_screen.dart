import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/screens/publish_listing_screen.dart';
import 'package:agrilumina/utils/locale_format.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final l10n = context.l10n;
        final counterparts = state.nearbyCounterparts;
        final counterpartLabel = l10n.counterpartPlural(state.activeRole);

        return Scaffold(
          appBar: AppBar(
            leading: const BrandHomeLeading(),
            title: const BrandLogo(height: 32),
            titleSpacing: 8,
            actions: [
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
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandLogo(height: 72),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.welcomeUser(l10n.resolvedDisplayName(state.displayName)),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.findNearbyByDistance(counterpartLabel),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${counterparts.length}'),
                  ),
                  title: Text(
                    l10n.nearbyCount(counterparts.length, counterpartLabel),
                  ),
                  subtitle: Text(
                    counterparts.isEmpty
                        ? l10n.noMatchesInSeedData
                        : l10n.closestListing(
                            l10n.listingDisplayName(counterparts.first),
                            formatDistanceKmLocalized(
                              l10n,
                              counterparts.first.distanceKm,
                            ),
                          ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => state.goToTab(1),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.campaign_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(l10n.myListing),
                  subtitle: Text(
                    state.myListing == null
                        ? l10n.myListingEmpty
                        : l10n.myListingSummary(
                            l10n.localizedCrop(state.myListing!.crop),
                            l10n.localizedListingQuantity(state.myListing!),
                          ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PublishListingScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.spendCreditToUnlock(AppState.unlockContactCost),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

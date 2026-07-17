import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/services/contact_launcher.dart';
import 'package:agrilumina/utils/locale_format.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({
    super.key,
    required this.listingId,
    ContactLauncher? contactLauncher,
  }) : contactLauncher = contactLauncher ?? const UrlLauncherContactLauncher();

  final String listingId;
  final ContactLauncher contactLauncher;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final l10n = context.l10n;
        final matches = state.listings.where((l) => l.id == listingId);
        final Listing? listing = matches.isEmpty ? null : matches.first;

        if (listing == null) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: BrandHomeLeading.backAndBrandLeadingWidth,
              leading: const BrandHomeLeading(includeBackWhenCanPop: true),
              title: Text(l10n.listingTitle),
            ),
            body: Center(child: Text(l10n.listingNotFound)),
          );
        }

        final unlocked = state.isUnlocked(listing.id);

        return Scaffold(
          appBar: AppBar(
            leadingWidth: BrandHomeLeading.backAndBrandLeadingWidth,
            leading: const BrandHomeLeading(includeBackWhenCanPop: true),
            title: Text(l10n.listingDisplayName(listing)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.localizedCrop(listing.crop),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.localizedListingQuantity(listing)),
              const SizedBox(height: 16),
              _InfoRow(
                label: l10n.labelRole,
                value: listing.role.label(l10n),
              ),
              _InfoRow(
                label: l10n.labelLocation,
                value: l10n.localizedListingPlace(listing),
              ),
              _InfoRow(
                label: l10n.labelDistance,
                value: formatDistanceKmLocalized(
                  l10n,
                  state.distanceKmFor(listing),
                ),
              ),
              _InfoRow(
                label: l10n.labelLastActive,
                value: l10n.localizedListingLastActive(listing),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.contact,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (unlocked) ...[
                SelectableText(
                  listing.phone,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _launchCall(context, listing.phone),
                        icon: const Icon(Icons.call),
                        label: Text(l10n.call),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            _launchWhatsApp(context, listing.phone),
                        icon: const Icon(Icons.chat),
                        label: Text(l10n.whatsApp),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.opensDialerOrWhatsApp,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ] else ...[
                Text(
                  l10n.phoneLockedSpendCredit(AppState.unlockContactCost),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    final ok = state.unlockContact(listing.id);
                    final messenger = ScaffoldMessenger.of(context);
                    if (ok) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.contactUnlocked)),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.notEnoughCredits)),
                      );
                    }
                  },
                  icon: const Icon(Icons.lock_open),
                  label: Text(
                    l10n.unlockForCredit(AppState.unlockContactCost),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.youHaveCredits(state.credits),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchCall(BuildContext context, String phone) async {
    final ok = await contactLauncher.call(phone);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenDialer)),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final ok = await contactLauncher.openWhatsApp(phone);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenWhatsApp)),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

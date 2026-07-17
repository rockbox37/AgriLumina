import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/services/contact_launcher.dart';
import 'package:agrilumina/utils/geo.dart';
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
        final matches =
            state.listings.where((l) => l.id == listingId);
        final Listing? listing =
            matches.isEmpty ? null : matches.first;

        if (listing == null) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: BrandHomeLeading.backAndBrandLeadingWidth,
              leading: const BrandHomeLeading(includeBackWhenCanPop: true),
              title: const Text('Listing'),
            ),
            body: const Center(child: Text('Listing not found.')),
          );
        }

        final unlocked = state.isUnlocked(listing.id);

        return Scaffold(
          appBar: AppBar(
            leadingWidth: BrandHomeLeading.backAndBrandLeadingWidth,
            leading: const BrandHomeLeading(includeBackWhenCanPop: true),
            title: Text(listing.name),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                listing.crop,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(listing.quantityHint),
              const SizedBox(height: 16),
              _InfoRow(label: 'Role', value: listing.role.label),
              _InfoRow(label: 'Location', value: listing.location),
              _InfoRow(
                label: 'Distance',
                value: formatDistanceKm(state.distanceKmFor(listing)),
              ),
              _InfoRow(label: 'Last active', value: listing.lastActiveLabel),
              const SizedBox(height: 24),
              Text(
                'Contact',
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
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            _launchWhatsApp(context, listing.phone),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Opens your phone dialer or WhatsApp. No in-app chat.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ] else ...[
                Text(
                  'Phone number is locked. Spend '
                  '${AppState.unlockContactCost} credit to unlock.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    final ok = state.unlockContact(listing.id);
                    final messenger = ScaffoldMessenger.of(context);
                    if (ok) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Contact unlocked.')),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Not enough credits. Add some on the Credits tab.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.lock_open),
                  label: Text(
                    'Unlock for ${AppState.unlockContactCost} credit',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have ${state.credits} credits.',
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
        const SnackBar(
          content: Text('Could not open the phone dialer on this device.'),
        ),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final ok = await contactLauncher.openWhatsApp(phone);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open WhatsApp. Install WhatsApp or try Call instead.',
          ),
        ),
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

import 'package:flutter/material.dart';
import 'package:agrilumina/admin/admin_models.dart';
import 'package:agrilumina/admin/main_admin.dart';

/// All marketplace listings with god-mode fields (phone, device id) and
/// moderation actions. Expired listings (past the read-side 30-day horizon)
/// are flagged; they are invisible to the app but still stored.
class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  List<AdminListing> _listings = const [];
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    final api = AdminStateScope.of(context).api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await api.fetchListings();
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _delete(AdminListing listing) async {
    final state = AdminStateScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this listing?'),
        content: Text(
          '${listing.name} · ${listing.crop} (${listing.role}) will be '
          'removed permanently. The owner is not notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('listing_delete_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete listing'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await state.api.deleteListing(listing.id);
      messenger.showSnackBar(const SnackBar(content: Text('Listing deleted.')));
      await _load();
      await state.refreshStats();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _banOwner(AdminListing listing) async {
    final state = AdminStateScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban this device?'),
        content: Text(
          'Device ${listing.ownerDeviceId} will be unable to post or '
          'publish. Existing rows are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ban device'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await state.api.banDevice(
        listing.ownerDeviceId,
        'Banned from listing ${listing.id}',
      );
      messenger.showSnackBar(const SnackBar(content: Text('Device banned.')));
      await state.refreshStats();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listings'),
        actions: [
          IconButton(
            key: const Key('listings_refresh'),
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Failed to load listings: $_error'))
              : _listings.isEmpty
                  ? const Center(child: Text('No listings.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _listings.length,
                      itemBuilder: (context, i) => _ListingCard(
                        listing: _listings[i],
                        onDelete: _delete,
                        onBanOwner: _banOwner,
                      ),
                    ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.onDelete,
    required this.onBanOwner,
  });

  final AdminListing listing;
  final void Function(AdminListing) onDelete;
  final void Function(AdminListing) onBanOwner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      listing.crop,
      if (listing.quantityHint.isNotEmpty) listing.quantityHint,
      if (listing.locationText.isNotEmpty) listing.locationText,
      'updated ${listing.updatedAt.toLocal().toString().substring(0, 16)}',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.name,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Chip(
                  label: Text(listing.role),
                  visualDensity: VisualDensity.compact,
                ),
                if (listing.expired) ...[
                  const SizedBox(width: 8),
                  Chip(
                    key: Key('expired_${listing.id}'),
                    label: const Text('expired'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(meta),
            SelectableText(
              'phone ${listing.phone}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            SelectableText(
              'device ${listing.ownerDeviceId}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  key: Key('delete_listing_${listing.id}'),
                  onPressed: () => onDelete(listing),
                  child: const Text('Delete'),
                ),
                TextButton(
                  onPressed: () => onBanOwner(listing),
                  child: const Text('Ban device'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

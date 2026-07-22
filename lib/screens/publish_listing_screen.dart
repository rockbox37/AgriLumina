import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';

/// Form to create or update the active-role local listing.
class PublishListingScreen extends StatefulWidget {
  const PublishListingScreen({super.key});

  @override
  State<PublishListingScreen> createState() => _PublishListingScreenState();
}

class _PublishListingScreenState extends State<PublishListingScreen> {
  late final TextEditingController _quantityController;
  late final TextEditingController _phoneController;
  String? _crop;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final state = AppStateScope.of(context);
    final existing = state.myListing;
    final interestDefault =
        state.relevantInterests.isNotEmpty ? state.relevantInterests.first : null;
    _crop = existing?.crop ??
        interestDefault ??
        (discoverCropFilters.isNotEmpty ? discoverCropFilters.first : null);
    _quantityController =
        TextEditingController(text: existing?.quantityHint ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _quantityController.dispose();
      _phoneController.dispose();
    }
    super.dispose();
  }

  void _save() {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    final crop = _crop;
    if (crop == null) return;
    final ok = state.publishMyListing(
      crop: crop,
      quantityHint: _quantityController.text,
      phone: _phoneController.text,
    );
    if (!ok) return;
    // The remote push runs in the background; when the app already knows it
    // is offline, say so up front (the Profile chip tracks the rest).
    final message = state.discoverOffline
        ? l10n.listingPublishedPendingSync
        : l10n.listingPublished;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    final editing = state.myListing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l10n.editMyListing : l10n.publishMyListing),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.labelCrop, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final crop in discoverCropFilters)
                ChoiceChip(
                  label: Text(l10n.localizedCrop(crop)),
                  selected: _crop == crop,
                  onSelected: (_) => setState(() => _crop = crop),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _quantityController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.labelQuantity,
              hintText: l10n.quantityHintField,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.labelPhone,
              hintText: l10n.phoneHintField,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _crop == null ? null : _save,
            child: Text(l10n.saveListing),
          ),
        ],
      ),
    );
  }
}

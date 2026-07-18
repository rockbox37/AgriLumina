import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/models/listing.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/screens/publish_listing_screen.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _taglineController;
  bool _initialized = false;
  String? _taglineError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    _nameController = TextEditingController(
      text: l10n.resolvedDisplayName(state.displayName),
    );
    _locationController = TextEditingController(
      text: l10n.resolvedLocation(state.location),
    );
    _taglineController = TextEditingController(text: state.tagline);
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _locationController.dispose();
      _taglineController.dispose();
    }
    super.dispose();
  }

  void _onEnabledRoleToggled(AppState state, UserRole role, bool selected) {
    final ok = state.setRoleEnabled(role, enabled: selected);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.rolesRequired)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final l10n = context.l10n;
        return Scaffold(
          appBar: AppBar(
            leading: const BrandHomeLeading(),
            title: Text(l10n.navProfile),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.enabledRolesLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    key: const Key('profile_role_seller'),
                    label: Text(l10n.roleSeller),
                    selected: state.isRoleEnabled(UserRole.seller),
                    onSelected: (selected) =>
                        _onEnabledRoleToggled(state, UserRole.seller, selected),
                  ),
                  FilterChip(
                    key: const Key('profile_role_buyer'),
                    label: Text(l10n.roleBuyer),
                    selected: state.isRoleEnabled(UserRole.buyer),
                    onSelected: (selected) =>
                        _onEnabledRoleToggled(state, UserRole.buyer, selected),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.displayName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: l10n.labelLocation,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('profile_tagline_field'),
                controller: _taglineController,
                maxLength: Listing.maxTaglineLength,
                decoration: InputDecoration(
                  labelText: l10n.publicTagline,
                  hintText: l10n.taglineHint,
                  border: const OutlineInputBorder(),
                  errorText: _taglineError,
                ),
                onChanged: (_) {
                  if (_taglineError != null) {
                    setState(() => _taglineError = null);
                  }
                },
              ),
              const SizedBox(height: 24),
              _InterestSection(
                title: l10n.buyingInterests,
                emptyHint: l10n.buyingInterestsEmpty,
                selected: state.buyingInterests,
                onToggle: state.toggleBuyingInterest,
                onAdd: state.addBuyingInterest,
                onRemove: state.removeBuyingInterest,
              ),
              const SizedBox(height: 20),
              _InterestSection(
                title: l10n.sellingInterests,
                emptyHint: l10n.sellingInterestsEmpty,
                selected: state.sellingInterests,
                onToggle: state.toggleSellingInterest,
                onAdd: state.addSellingInterest,
                onRemove: state.removeSellingInterest,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.myListing,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(
                    state.myListing == null
                        ? l10n.myListingEmpty
                        : l10n.myListingSummary(
                            l10n.localizedCrop(state.myListing!.crop),
                            l10n.localizedListingQuantity(state.myListing!),
                          ),
                  ),
                  subtitle: Text(
                    state.myListing == null
                        ? l10n.publishMyListing
                        : l10n.editMyListing,
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
              if (state.myListing != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    state.clearMyListing();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.listingCleared)),
                    );
                  },
                  child: Text(l10n.clearMyListing),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final nameInput = _nameController.text.trim();
                  // Persist empty when the field matches the localized default
                  // so the name stays locale-aware.
                  final nameToStore = nameInput.isEmpty ||
                          nameInput == l10n.defaultDisplayName
                      ? ''
                      : nameInput;
                  final locationInput = _locationController.text.trim();
                  final locationToStore = locationInput.isEmpty ||
                          locationInput == l10n.defaultLocation
                      ? ''
                      : locationInput;
                  final taglineInput = _taglineController.text.trim();
                  if (taglineInput.length > Listing.maxTaglineLength) {
                    setState(() {
                      _taglineError =
                          l10n.taglineTooLong(Listing.maxTaglineLength);
                    });
                    return;
                  }
                  state.updateProfile(
                    displayName: nameToStore,
                    location: locationToStore,
                    tagline: taglineInput,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.profileSaved)),
                  );
                },
                child: Text(l10n.saveProfile),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.profileStats(
                  state.credits,
                  state.unlockedListingIds.length,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InterestSection extends StatefulWidget {
  const _InterestSection({
    required this.title,
    required this.emptyHint,
    required this.selected,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String emptyHint;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_InterestSection> createState() => _InterestSectionState();
}

class _InterestSectionState extends State<_InterestSection> {
  TextEditingController? _fieldController;
  String? _pendingCustom;
  String? _suggestion;

  void _clearPending() {
    _pendingCustom = null;
    _suggestion = null;
  }

  void _addResolved(
    String crop, {
    String? typedAs,
  }) {
    final id = resolveCropInterestId(crop);
    if (id == null) return;
    final already = interestContains(widget.selected, id);
    widget.onAdd(crop);

    if (!already &&
        typedAs != null &&
        isKnownCrop(id) &&
        id.toLowerCase() != typedAs.trim().toLowerCase()) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addedCanonicalCrop(l10n.localizedCrop(id))),
        ),
      );
    }

    _fieldController?.clear();
    setState(_clearPending);
  }

  void _submitTyped(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    final canonical = matchCanonicalCrop(trimmed);
    if (canonical != null) {
      _addResolved(canonical, typedAs: trimmed);
      return;
    }

    final suggestion = suggestCanonicalCrop(trimmed);
    final custom = normalizeCropDisplayName(trimmed);
    if (custom.isEmpty) return;

    if (suggestion != null) {
      setState(() {
        _pendingCustom = custom;
        _suggestion = suggestion;
      });
      return;
    }

    _addResolved(custom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final customSelected =
        widget.selected.where((c) => !isKnownCrop(c)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (widget.selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.emptyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final crop in discoverCropFilters)
              FilterChip(
                label: Text(l10n.localizedCrop(crop)),
                selected: interestContains(widget.selected, crop),
                onSelected: (_) => widget.onToggle(crop),
              ),
            for (final crop in customSelected)
              InputChip(
                label: Text(l10n.localizedCrop(crop)),
                onDeleted: () => widget.onRemove(crop),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Autocomplete<String>(
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            if (q.isEmpty) return const Iterable<String>.empty();
            return discoverCropFilters.where((crop) {
              final key = crop.toLowerCase();
              final label = l10n.localizedCrop(crop).toLowerCase();
              return key.contains(q) || label.contains(q);
            });
          },
          displayStringForOption: l10n.localizedCrop,
          onSelected: _addResolved,
          fieldViewBuilder: (
            context,
            textEditingController,
            focusNode,
            onFieldSubmitted,
          ) {
            _fieldController = textEditingController;
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.addCropInterest,
                hintText: l10n.addCropInterestHint,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: l10n.addCropInterest,
                  onPressed: () => _submitTyped(textEditingController.text),
                  icon: const Icon(Icons.add),
                ),
              ),
              onChanged: (_) {
                if (_pendingCustom != null || _suggestion != null) {
                  setState(_clearPending);
                }
              },
              onSubmitted: (value) {
                _submitTyped(value);
                onFieldSubmitted();
              },
            );
          },
        ),
        if (_suggestion != null && _pendingCustom != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.didYouMeanCrop(l10n.localizedCrop(_suggestion!)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () => _addResolved(_suggestion!),
                child: Text(
                  l10n.useSuggestedCrop(l10n.localizedCrop(_suggestion!)),
                ),
              ),
              TextButton(
                onPressed: () => _addResolved(_pendingCustom!),
                child: Text(l10n.addCropAsTyped(_pendingCustom!)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

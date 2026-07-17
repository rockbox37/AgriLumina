import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    _nameController = TextEditingController(
      text: l10n.resolvedDisplayName(state.displayName),
    );
    _locationController = TextEditingController(text: state.location);
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _locationController.dispose();
    }
    super.dispose();
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
              Text(l10n.labelRole, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                segments: [
                  ButtonSegment(
                    value: UserRole.seller,
                    label: Text(l10n.roleSeller),
                  ),
                  ButtonSegment(
                    value: UserRole.buyer,
                    label: Text(l10n.roleBuyer),
                  ),
                ],
                selected: {state.role},
                onSelectionChanged: (roles) => state.setRole(roles.first),
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
              const SizedBox(height: 24),
              _InterestSection(
                title: l10n.buyingInterests,
                emptyHint: l10n.buyingInterestsEmpty,
                selected: state.buyingInterests,
                onToggle: state.toggleBuyingInterest,
              ),
              const SizedBox(height: 20),
              _InterestSection(
                title: l10n.sellingInterests,
                emptyHint: l10n.sellingInterestsEmpty,
                selected: state.sellingInterests,
                onToggle: state.toggleSellingInterest,
              ),
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
                  state.updateProfile(
                    displayName: nameToStore,
                    location: _locationController.text.trim().isEmpty
                        ? state.location
                        : _locationController.text.trim(),
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

class _InterestSection extends StatelessWidget {
  const _InterestSection({
    required this.title,
    required this.emptyHint,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final String emptyHint;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              emptyHint,
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
                label: Text(crop),
                selected: selected.contains(crop),
                onSelected: (_) => onToggle(crop),
              ),
          ],
        ),
      ],
    );
  }
}

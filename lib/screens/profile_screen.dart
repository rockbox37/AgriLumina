import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/data/crop_vocabulary.dart';
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
    _nameController = TextEditingController(text: state.displayName);
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
        return Scaffold(
          appBar: AppBar(
            leading: const BrandHomeLeading(),
            title: const Text('Profile'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Role', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.seller,
                    label: Text('Seller'),
                  ),
                  ButtonSegment(
                    value: UserRole.buyer,
                    label: Text('Buyer'),
                  ),
                ],
                selected: {state.role},
                onSelectionChanged: (roles) => state.setRole(roles.first),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _InterestSection(
                title: 'Buying interests',
                emptyHint: 'None yet — add crops you want to buy',
                selected: state.buyingInterests,
                onToggle: state.toggleBuyingInterest,
              ),
              const SizedBox(height: 20),
              _InterestSection(
                title: 'Selling interests',
                emptyHint: 'None yet — add crops you want to sell',
                selected: state.sellingInterests,
                onToggle: state.toggleSellingInterest,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  state.updateProfile(
                    displayName: _nameController.text.trim().isEmpty
                        ? state.displayName
                        : _nameController.text.trim(),
                    location: _locationController.text.trim().isEmpty
                        ? state.location
                        : _locationController.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved.')),
                  );
                },
                child: const Text('Save profile'),
              ),
              const SizedBox(height: 16),
              Text(
                'Credits: ${state.credits} · '
                'Unlocked contacts: ${state.unlockedListingIds.length}',
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

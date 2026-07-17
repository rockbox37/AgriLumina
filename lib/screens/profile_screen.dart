import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/user_role.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _cropController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final state = AppStateScope.of(context);
    _nameController = TextEditingController(text: state.displayName);
    _locationController = TextEditingController(text: state.location);
    _cropController = TextEditingController(text: state.cropInterest);
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _locationController.dispose();
      _cropController.dispose();
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
          appBar: AppBar(title: const Text('Profile')),
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
              const SizedBox(height: 12),
              TextField(
                controller: _cropController,
                decoration: const InputDecoration(
                  labelText: 'Crop interest',
                  border: OutlineInputBorder(),
                ),
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
                    cropInterest: _cropController.text.trim().isEmpty
                        ? state.cropInterest
                        : _cropController.text.trim(),
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

import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/utils/geo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final counterparts = state.nearbyCounterparts;
        final counterpartLabel =
            state.role.counterpart == UserRole.buyer ? 'buyers' : 'sellers';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Agrilumina'),
            actions: [
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
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Welcome, ${state.displayName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Find nearby $counterpartLabel by distance.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text('I am a…', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.seller,
                    label: Text('Seller'),
                    icon: Icon(Icons.agriculture),
                  ),
                  ButtonSegment(
                    value: UserRole.buyer,
                    label: Text('Buyer'),
                    icon: Icon(Icons.storefront),
                  ),
                ],
                selected: {state.role},
                onSelectionChanged: (roles) => state.setRole(roles.first),
              ),
              const SizedBox(height: 28),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${counterparts.length}'),
                  ),
                  title: Text('${counterparts.length} nearby $counterpartLabel'),
                  subtitle: Text(
                    counterparts.isEmpty
                        ? 'No matches in seed data yet'
                        : 'Closest: ${counterparts.first.name} · '
                            '${formatDistanceKm(counterparts.first.distanceKm)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => state.goToTab(1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Spend ${AppState.unlockContactCost} credit to unlock a phone number.',
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

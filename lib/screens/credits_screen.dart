import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Credits')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your balance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.credits}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlocking a contact costs ${AppState.unlockContactCost} credit. '
                  'Real payments come later — for now you can add demo credits.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () {
                    state.addCredits(5);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added 5 demo credits.')),
                    );
                  },
                  child: const Text('Add 5 demo credits'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    state.addCredits(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added 1 demo credit.')),
                    );
                  },
                  child: const Text('Add 1 demo credit'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

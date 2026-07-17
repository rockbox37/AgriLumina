import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

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
            title: Text(l10n.navCredits),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.yourBalance,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.credits}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.creditsExplainer(AppState.unlockContactCost),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () {
                    state.addCredits(5);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.addedDemoCredits(5))),
                    );
                  },
                  child: Text(l10n.addDemoCredits(5)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    state.addCredits(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.addedDemoCredit(1))),
                    );
                  },
                  child: Text(l10n.addDemoCredit(1)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

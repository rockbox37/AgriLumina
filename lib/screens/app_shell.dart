import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/screens/credits_screen.dart';
import 'package:agrilumina/screens/discover_screen.dart';
import 'package:agrilumina/screens/forum_screen.dart';
import 'package:agrilumina/screens/home_screen.dart';
import 'package:agrilumina/screens/profile_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _pages = <Widget>[
    HomeScreen(),
    DiscoverScreen(),
    ForumScreen(),
    CreditsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: state.shellTabIndex,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.shellTabIndex,
            onDestinationSelected: state.goToTab,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.travel_explore_outlined),
                selectedIcon: const Icon(Icons.travel_explore),
                label: l10n.navDiscover,
              ),
              NavigationDestination(
                icon: const Icon(Icons.forum_outlined),
                selectedIcon: const Icon(Icons.forum),
                label: l10n.navForum,
              ),
              NavigationDestination(
                icon: const Icon(Icons.toll_outlined),
                selectedIcon: const Icon(Icons.toll),
                label: l10n.navCredits,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l10n.navProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}

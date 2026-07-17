import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/screens/credits_screen.dart';
import 'package:agrilumina/screens/discover_screen.dart';
import 'package:agrilumina/screens/home_screen.dart';
import 'package:agrilumina/screens/profile_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _pages = <Widget>[
    HomeScreen(),
    DiscoverScreen(),
    CreditsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.travel_explore_outlined),
                selectedIcon: Icon(Icons.travel_explore),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.toll_outlined),
                selectedIcon: Icon(Icons.toll),
                label: 'Credits',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

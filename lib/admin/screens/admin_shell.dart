import 'package:flutter/material.dart';
import 'package:agrilumina/admin/main_admin.dart';
import 'package:agrilumina/admin/screens/alerts_screen.dart';
import 'package:agrilumina/admin/screens/bans_screen.dart';
import 'package:agrilumina/admin/screens/blocklist_screen.dart';
import 'package:agrilumina/admin/screens/overview_screen.dart';
import 'package:agrilumina/admin/screens/posts_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _panes = <Widget>[
    OverviewScreen(),
    PostsScreen(),
    BlocklistScreen(),
    BansScreen(),
    AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AdminStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final unread = state.unreadAlerts;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Icon(
                    Icons.agriculture,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        key: const Key('admin_logout'),
                        tooltip: 'Sign out (${state.email})',
                        onPressed: state.logout,
                        icon: const Icon(Icons.logout),
                      ),
                    ),
                  ),
                ),
                destinations: [
                  const NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Overview'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.article_outlined),
                    selectedIcon: Icon(Icons.article),
                    label: Text('Posts'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.block_outlined),
                    selectedIcon: Icon(Icons.block),
                    label: Text('Blocklist'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.phonelink_erase_outlined),
                    selectedIcon: Icon(Icons.phonelink_erase),
                    label: Text('Bans'),
                  ),
                  NavigationRailDestination(
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications),
                    ),
                    label: const Text('Alerts'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(index: _index, children: _panes),
              ),
            ],
          ),
        );
      },
    );
  }
}

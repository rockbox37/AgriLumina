import 'package:flutter/material.dart';
import 'package:agrilumina/admin/main_admin.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AdminStateScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final stats = state.stats;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Overview'),
            actions: [
              IconButton(
                key: const Key('overview_refresh'),
                tooltip: 'Refresh',
                onPressed: state.refreshStats,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: stats == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatTile(
                          label: 'Visible posts',
                          value: stats.statusCount('visible'),
                        ),
                        _StatTile(
                          label: 'Pending review',
                          value: stats.statusCount('hidden'),
                          highlight: stats.statusCount('hidden') > 0,
                        ),
                        _StatTile(
                          label: 'Spam',
                          value: stats.statusCount('spam'),
                        ),
                        _StatTile(
                          label: 'Deleted',
                          value: stats.statusCount('deleted'),
                        ),
                        _StatTile(label: 'Posts 24h', value: stats.posts24h),
                        _StatTile(label: 'Posts 7d', value: stats.posts7d),
                        _StatTile(
                          label: 'Reports 24h',
                          value: stats.reports24h,
                        ),
                        _StatTile(label: 'Reports 7d', value: stats.reports7d),
                        _StatTile(
                          label: 'Devices 24h',
                          value: stats.activeDevices24h,
                        ),
                        _StatTile(
                          label: 'Devices 7d',
                          value: stats.activeDevices7d,
                        ),
                        _StatTile(
                          label: 'Banned devices',
                          value: stats.bannedDevices,
                        ),
                        _StatTile(
                          label: 'Unread alerts',
                          value: stats.unreadAlerts,
                          highlight: stats.unreadAlerts > 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Most reported posts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (stats.topReported.isEmpty)
                      const Text('No reported posts.')
                    else
                      ...stats.topReported.map(
                        (p) => Card(
                          child: ListTile(
                            title: Text('${p.authorName} · ${p.status}'),
                            subtitle: Text(p.snippet),
                            trailing: Chip(
                              label: Text('${p.reportCount} reports'),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: highlight ? theme.colorScheme.tertiaryContainer : null,
      child: SizedBox(
        width: 150,
        height: 96,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: theme.textTheme.headlineSmall),
              const Spacer(),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

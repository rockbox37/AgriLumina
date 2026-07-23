import 'package:flutter/material.dart';
import 'package:agrilumina/admin/admin_models.dart';
import 'package:agrilumina/admin/main_admin.dart';

const _ruleLabels = <String, String>{
  'auto_hidden_heuristic': 'Post auto-hidden by spam heuristics',
  'auto_hidden_reports': 'Post auto-hidden by user reports',
  'post_rate_spike': 'Posting-rate spike (posts/hour)',
  'report_rate_spike': 'Report-rate spike (reports/hour)',
  'listing_rate_spike': 'New-listing spike (listings/hour)',
  'contact_rate_spike': 'Contact-unlock spike (unlocks/hour)',
};

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AdminAlert> _alerts = const [];
  List<AlertRule> _rules = const [];
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    final api = AdminStateScope.of(context).api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final alerts = await api.fetchAlerts();
      final rules = await api.fetchRules();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _rules = rules;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _markRead(AdminAlert alert) async {
    final state = AdminStateScope.of(context);
    await state.api.markAlertRead(alert.id);
    await _load();
    await state.refreshStats();
  }

  Future<void> _toggleRule(AlertRule rule) async {
    final api = AdminStateScope.of(context).api;
    await api.updateRule(rule.id, enabled: !rule.enabled);
    await _load();
  }

  Future<void> _editThreshold(AlertRule rule) async {
    final api = AdminStateScope.of(context).api;
    final controller = TextEditingController(text: '${rule.threshold}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_ruleLabels[rule.id] ?? rule.id),
        content: TextField(
          key: const Key('rule_threshold_field'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Threshold (events per hour)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('rule_threshold_save'),
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      await api.updateRule(rule.id, threshold: value);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            key: const Key('alerts_refresh'),
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Failed to load alerts: $_error'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Alert rules',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._rules.map(
                      (rule) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(_ruleLabels[rule.id] ?? rule.id),
                          subtitle: rule.threshold != null
                              ? Text('threshold: ${rule.threshold}/hour')
                              : null,
                          leading: Switch(
                            key: Key('rule_enabled_${rule.id}'),
                            value: rule.enabled,
                            onChanged: (_) => _toggleRule(rule),
                          ),
                          trailing: rule.threshold != null
                              ? IconButton(
                                  key: Key('rule_edit_${rule.id}'),
                                  tooltip: 'Edit threshold',
                                  onPressed: () => _editThreshold(rule),
                                  icon: const Icon(Icons.tune),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Alert feed',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_alerts.isEmpty)
                      const Text('No alerts yet.')
                    else
                      ..._alerts.map(
                        (alert) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: alert.read
                              ? null
                              : Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                          child: ListTile(
                            title: Text(
                              _ruleLabels[alert.ruleId] ?? alert.ruleId,
                            ),
                            subtitle: Text(
                              [
                                if (alert.subjectPostId != null)
                                  'post ${alert.subjectPostId}',
                                if (alert.detail.isNotEmpty) '${alert.detail}',
                                alert.createdAt
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                              ].join(' · '),
                            ),
                            trailing: alert.read
                                ? null
                                : TextButton(
                                    key: Key('alert_read_${alert.id}'),
                                    onPressed: () => _markRead(alert),
                                    child: const Text('Mark read'),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

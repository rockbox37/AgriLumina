import 'package:flutter/material.dart';
import 'package:agrilumina/admin/admin_models.dart';
import 'package:agrilumina/admin/main_admin.dart';

class BansScreen extends StatefulWidget {
  const BansScreen({super.key});

  @override
  State<BansScreen> createState() => _BansScreenState();
}

class _BansScreenState extends State<BansScreen> {
  final _deviceController = TextEditingController();
  final _reasonController = TextEditingController();

  List<BannedDevice> _bans = const [];
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

  @override
  void dispose() {
    _deviceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = AdminStateScope.of(context).api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bans = await api.fetchBans();
      if (!mounted) return;
      setState(() {
        _bans = bans;
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

  Future<void> _ban() async {
    final state = AdminStateScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final deviceId = _deviceController.text.trim().toLowerCase();
    if (deviceId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban this device?'),
        content: Text(
          'Device $deviceId will be unable to post or publish. '
          'Existing rows are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('ban_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ban device'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await state.api.banDevice(
        deviceId,
        _reasonController.text.trim().isEmpty
            ? 'Banned from dashboard'
            : _reasonController.text.trim(),
      );
      _deviceController.clear();
      _reasonController.clear();
      await _load();
      await state.refreshStats();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _unban(BannedDevice ban) async {
    final state = AdminStateScope.of(context);
    await state.api.unbanDevice(ban.deviceId);
    await _load();
    await state.refreshStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banned devices'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    key: const Key('ban_device_id'),
                    controller: _deviceController,
                    decoration: const InputDecoration(
                      labelText: 'Device id (uuid)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: const Key('ban_reason'),
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('ban_add'),
                  onPressed: _ban,
                  child: const Text('Ban'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Failed to load bans: $_error'))
                    : _bans.isEmpty
                        ? const Center(child: Text('No banned devices.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _bans.length,
                            itemBuilder: (context, i) {
                              final ban = _bans[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: SelectableText(
                                    ban.deviceId,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  subtitle: Text(ban.reason ?? ''),
                                  trailing: TextButton(
                                    key: Key('unban_${ban.deviceId}'),
                                    onPressed: () => _unban(ban),
                                    child: const Text('Unban'),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

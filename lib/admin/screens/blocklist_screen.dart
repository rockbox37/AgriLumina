import 'package:flutter/material.dart';
import 'package:agrilumina/admin/admin_models.dart';
import 'package:agrilumina/admin/main_admin.dart';

/// Spam blocklist management. Terms are matched against the normalized post
/// body (lowercase, no accents/punctuation), so enter them in that form.
class BlocklistScreen extends StatefulWidget {
  const BlocklistScreen({super.key});

  @override
  State<BlocklistScreen> createState() => _BlocklistScreenState();
}

class _BlocklistScreenState extends State<BlocklistScreen> {
  final _termController = TextEditingController();
  final _weightController = TextEditingController(text: '3');

  List<BlocklistEntry> _entries = const [];
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
    _termController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = AdminStateScope.of(context).api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await api.fetchBlocklist();
      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  Future<void> _add() async {
    final api = AdminStateScope.of(context).api;
    final messenger = ScaffoldMessenger.of(context);
    final term = _termController.text.trim().toLowerCase();
    final weight = int.tryParse(_weightController.text.trim()) ?? 3;
    if (term.isEmpty) return;
    try {
      await api.addBlocklistTerm(term, weight);
      _termController.clear();
      await _load();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _toggle(BlocklistEntry entry) async {
    final api = AdminStateScope.of(context).api;
    await api.updateBlocklistEntry(entry.id, active: !entry.active);
    await _load();
  }

  Future<void> _delete(BlocklistEntry entry) async {
    final api = AdminStateScope.of(context).api;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this term?'),
        content: Text(
          '"${entry.term}" will be removed from the blocklist and will no '
          'longer contribute to spam scoring.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: Key('blocklist_delete_confirm_${entry.id}'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete term'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await api.deleteBlocklistEntry(entry.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocklist'),
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
                  child: TextField(
                    key: const Key('blocklist_term'),
                    controller: _termController,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      labelText: 'New term (normalized: lowercase, no accents)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    key: const Key('blocklist_weight'),
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('blocklist_add'),
                  onPressed: _add,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Score ≥5 hides a post pending review; ≥10 marks it spam.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Failed to load blocklist: $_error'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, i) {
                          final entry = _entries[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(entry.term),
                              subtitle: Text('weight ${entry.weight}'),
                              leading: Switch(
                                key: Key('blocklist_active_${entry.id}'),
                                value: entry.active,
                                onChanged: (_) => _toggle(entry),
                              ),
                              trailing: IconButton(
                                key: Key('blocklist_delete_${entry.id}'),
                                tooltip: 'Delete term',
                                onPressed: () => _delete(entry),
                                icon: const Icon(Icons.delete_outline),
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

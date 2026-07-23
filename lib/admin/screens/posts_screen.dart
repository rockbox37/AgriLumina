import 'package:flutter/material.dart';
import 'package:agrilumina/admin/admin_models.dart';
import 'package:agrilumina/admin/main_admin.dart';

/// Moderation view over all posts with god-mode fields. Defaults to the
/// pending-review queue (status = hidden).
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const _filters = ['hidden', 'spam', 'visible', 'deleted', 'all'];

  String _filter = 'hidden';
  List<AdminPost> _posts = const [];
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
      final posts = await api.fetchPosts(
        status: _filter == 'all' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _posts = posts;
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

  Future<void> _setStatus(AdminPost post, String status) async {
    final state = AdminStateScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Approving (making visible) restores a post; only guard the destructive
    // moderation actions.
    if (status == 'spam' || status == 'deleted') {
      final label = status == 'spam' ? 'Mark as spam' : 'Delete';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            status == 'spam' ? 'Mark this post as spam?' : 'Delete this post?',
          ),
          content: Text(
            status == 'spam'
                ? 'The post will be hidden as spam. You can approve it later '
                    'to restore it.'
                : 'The post will be removed from the app. You can approve it '
                    'later to restore it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: Key('set_status_confirm_${post.id}'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(label),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await state.api.setPostStatus(post.id, status);
      messenger.showSnackBar(
        SnackBar(content: Text('Post marked $status.')),
      );
      await _load();
      await state.refreshStats();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _banDevice(AdminPost post) async {
    final state = AdminStateScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban this device?'),
        content: Text(
          'Device ${post.deviceId} will be unable to post. '
          'Existing posts are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ban device'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await state.api.banDevice(post.deviceId, 'Banned from post ${post.id}');
      messenger.showSnackBar(const SnackBar(content: Text('Device banned.')));
      await state.refreshStats();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton(
            key: const Key('posts_refresh'),
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
            child: Wrap(
              spacing: 8,
              children: _filters
                  .map(
                    (f) => FilterChip(
                      key: Key('posts_filter_$f'),
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) {
                        setState(() => _filter = f);
                        _load();
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Failed to load posts: $_error'))
                    : _posts.isEmpty
                        ? const Center(child: Text('No posts.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _posts.length,
                            itemBuilder: (context, i) => _PostCard(
                              post: _posts[i],
                              onSetStatus: _setStatus,
                              onBanDevice: _banDevice,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onSetStatus,
    required this.onBanDevice,
  });

  final AdminPost post;
  final void Function(AdminPost, String) onSetStatus;
  final void Function(AdminPost) onBanDevice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      post.parentId == null ? 'thread' : 'reply',
      'score ${post.spamScore}',
      '${post.reportCount} reports',
      if (post.hiddenReason != null) 'hidden: ${post.hiddenReason}',
      post.createdAt.toLocal().toString().substring(0, 16),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.authorName,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Chip(
                  label: Text(post.status),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(post.body),
            const SizedBox(height: 8),
            Text(
              meta,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            SelectableText(
              'device ${post.deviceId}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (post.status != 'visible')
                  FilledButton.tonal(
                    key: Key('approve_${post.id}'),
                    onPressed: () => onSetStatus(post, 'visible'),
                    child: const Text('Approve'),
                  ),
                if (post.status != 'spam')
                  OutlinedButton(
                    key: Key('spam_${post.id}'),
                    onPressed: () => onSetStatus(post, 'spam'),
                    child: const Text('Mark spam'),
                  ),
                if (post.status != 'deleted')
                  OutlinedButton(
                    key: Key('delete_${post.id}'),
                    onPressed: () => onSetStatus(post, 'deleted'),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  key: Key('ban_${post.id}'),
                  onPressed: () => onBanDevice(post),
                  child: const Text('Ban device'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

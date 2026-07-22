import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/models/forum_post.dart';
import 'package:agrilumina/screens/forum_thread_screen.dart';
import 'package:agrilumina/services/forum_api.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

/// Community forum: public threads anyone can read, post to, and reply to.
///
/// Reads come from the hosted backend (cached for offline); writes go through
/// the spam-filtered edge function. Own posts held for review are shown only
/// locally with an "awaiting review" chip.
class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key, this.api});

  /// Test override; defaults to the hosted backend.
  final ForumApi? api;

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  ForumApi? _defaultApi;
  ForumApi get _api => widget.api ?? (_defaultApi ??= HttpForumApi());

  final ScrollController _scrollController = ScrollController();

  List<ForumPost> _threads = const [];
  bool _loading = true;
  bool _offline = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final state = AppStateScope.of(context);
    try {
      final threads = await _api.fetchThreads();
      if (!mounted) return;
      state.cacheForumThreads(threads);
      _reconcilePending(state, threads);
      setState(() {
        _threads = threads;
        _loading = false;
        _offline = false;
        _hasMore = threads.length >= ForumConfig.threadsPageSize;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _threads = state.cachedForumThreads;
        _loading = false;
        _offline = true;
        _hasMore = false;
      });
    }
  }

  Future<void> _maybeLoadMore() async {
    if (_loadingMore || !_hasMore || _offline || _threads.isEmpty) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;
    setState(() => _loadingMore = true);
    try {
      final more =
          await _api.fetchThreads(before: _threads.last.lastActivityAt);
      if (!mounted) return;
      final known = _threads.map((t) => t.id).toSet();
      setState(() {
        _threads = [
          ..._threads,
          ...more.where((t) => !known.contains(t.id)),
        ];
        _hasMore = more.length >= ForumConfig.threadsPageSize;
        _loadingMore = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
    }
  }

  /// Pending posts that now appear in the public feed were approved.
  void _reconcilePending(AppState state, List<ForumPost> feed) {
    final feedIds = feed.map((t) => t.id).toSet();
    for (final post in state.myForumPosts) {
      if (post.isPendingReview && feedIds.contains(post.id)) {
        state.removeMyForumPost(post.id);
        state.addMyForumPost(post.copyWith(status: ForumPostStatus.visible));
      }
    }
  }

  Future<void> _openCompose() async {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    if (state.displayName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.forumSetNameFirst)),
      );
      return;
    }
    final created = await showModalBottomSheet<ForumPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ForumComposeSheet(
        api: _api,
        deviceId: state.deviceId,
        authorName: state.displayName.trim(),
      ),
    );
    if (created == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    AppStateScope.of(context).addMyForumPost(created);
    if (created.isPendingReview) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.forumPendingExplainer)),
      );
    } else {
      setState(() => _threads = [created, ..._threads]);
    }
  }

  Future<void> _openThread(ForumPost root) async {
    final result = await Navigator.of(context).push<ForumThreadResult>(
      MaterialPageRoute(
        builder: (_) => ForumThreadScreen(root: root, api: _api),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.deleted) {
        _threads = _threads.where((t) => t.id != root.id).toList();
      } else if (result.replyCount != null) {
        _threads = _threads
            .map(
              (t) => t.id == root.id
                  ? t.copyWith(replyCount: result.replyCount)
                  : t,
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final pending = state.myForumPosts
            .where((p) => p.isPendingReview && p.isRoot)
            .toList();
        return Scaffold(
          appBar: AppBar(
            leading: const BrandHomeLeading(),
            title: Text(l10n.forumTitle),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('forum_new_post'),
            onPressed: _openCompose,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.forumNewPost),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_offline) const _ForumOfflineBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _buildList(pending),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<ForumPost> pending) {
    final l10n = context.l10n;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_threads.isEmpty && pending.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _offline ? l10n.forumLoadError : l10n.forumEmpty,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    final itemCount = pending.length + _threads.length + (_loadingMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index < pending.length) {
          return _ThreadTile(post: pending[index], pending: true);
        }
        final threadIndex = index - pending.length;
        if (threadIndex >= _threads.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final thread = _threads[threadIndex];
        return _ThreadTile(
          post: thread,
          onTap: () => _openThread(thread),
        );
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.post, this.pending = false, this.onTap});

  final ForumPost post;
  final bool pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              post.authorName,
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            l10n.forumTimeAgo(post.lastActivityAt),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            post.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (pending)
            Chip(
              key: const Key('forum_pending_chip'),
              avatar: const Icon(Icons.hourglass_top, size: 16),
              label: Text(l10n.forumPendingReview),
              visualDensity: VisualDensity.compact,
            )
          else
            Text(
              l10n.forumReplies(post.replyCount),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ForumOfflineBanner extends StatelessWidget {
  const _ForumOfflineBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.forumOfflineBanner,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for composing a new thread. Pops with the created post.
class ForumComposeSheet extends StatefulWidget {
  const ForumComposeSheet({
    super.key,
    required this.api,
    required this.deviceId,
    required this.authorName,
  });

  final ForumApi api;
  final String deviceId;
  final String authorName;

  @override
  State<ForumComposeSheet> createState() => _ForumComposeSheetState();
}

class _ForumComposeSheetState extends State<ForumComposeSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final body = _controller.text.trim();
    if (body.length < 2 || _submitting) return;
    setState(() => _submitting = true);
    try {
      final post = await widget.api.createPost(
        deviceId: widget.deviceId,
        authorName: widget.authorName,
        body: body,
      );
      if (!mounted) return;
      Navigator.of(context).pop(post);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(forumErrorMessage(l10n, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.forumNewPost,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('forum_compose_field'),
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: l10n.forumPostHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('forum_compose_submit'),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.forumPostAction),
          ),
        ],
      ),
    );
  }
}

/// Maps forum API failures to localized user-facing copy.
String forumErrorMessage(AppLocalizations l10n, Exception e) {
  if (e is ForumRateLimitedException) {
    return l10n.forumRateLimited(e.retryAfterSeconds);
  }
  if (e is ForumDuplicateException) return l10n.forumDuplicate;
  return l10n.forumPostFailed;
}

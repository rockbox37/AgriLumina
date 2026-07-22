import 'package:flutter/material.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/l10n_extensions.dart';
import 'package:agrilumina/models/forum_post.dart';
import 'package:agrilumina/screens/forum_screen.dart' show forumErrorMessage;
import 'package:agrilumina/services/forum_api.dart';

/// Result popped back to the thread list when leaving a thread.
class ForumThreadResult {
  const ForumThreadResult({this.deleted = false, this.replyCount});

  final bool deleted;
  final int? replyCount;
}

/// A thread: root post, its replies, and a reply composer.
class ForumThreadScreen extends StatefulWidget {
  const ForumThreadScreen({super.key, required this.root, required this.api});

  final ForumPost root;
  final ForumApi api;

  @override
  State<ForumThreadScreen> createState() => _ForumThreadScreenState();
}

class _ForumThreadScreenState extends State<ForumThreadScreen> {
  final TextEditingController _replyController = TextEditingController();

  List<ForumPost> _replies = const [];
  bool _loading = true;
  bool _loadFailed = false;
  bool _submitting = false;
  bool _initialized = false;
  int? _visibleReplyCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    try {
      final replies = await widget.api.fetchReplies(widget.root.id);
      if (!mounted) return;
      setState(() {
        _replies = replies;
        _visibleReplyCount = replies.length;
        _loading = false;
        _loadFailed = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _submitReply() async {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    final body = _replyController.text.trim();
    if (body.length < 2 || _submitting) return;
    if (state.displayName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.forumSetNameFirst)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final reply = await widget.api.createPost(
        deviceId: state.deviceId,
        authorName: state.displayName.trim(),
        body: body,
        parentId: widget.root.id,
      );
      if (!mounted) return;
      AppStateScope.of(context).addMyForumPost(reply);
      _replyController.clear();
      setState(() {
        _submitting = false;
        if (!reply.isPendingReview) {
          _replies = [..._replies, reply];
          _visibleReplyCount = (_visibleReplyCount ?? 0) + 1;
        }
      });
      if (reply.isPendingReview) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.forumPendingExplainer)),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(forumErrorMessage(l10n, e))),
      );
    }
  }

  Future<void> _reportPost(ForumPost post) async {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.api.reportPost(deviceId: state.deviceId, postId: post.id);
      if (!mounted) return;
      state.markForumPostReported(post.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.forumReportThanks)),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(forumErrorMessage(l10n, e))),
      );
    }
  }

  Future<void> _deletePost(ForumPost post) async {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.forumDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              MaterialLocalizations.of(context).cancelButtonLabel,
            ),
          ),
          FilledButton(
            key: const Key('forum_delete_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.forumDeletePost),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.api.deletePost(deviceId: state.deviceId, postId: post.id);
      if (!mounted) return;
      state.removeMyForumPost(post.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.forumPostDeleted)),
      );
      if (post.id == widget.root.id) {
        navigator.pop(const ForumThreadResult(deleted: true));
      } else {
        setState(() {
          _replies = _replies.where((r) => r.id != post.id).toList();
          _visibleReplyCount = _replies.length;
        });
      }
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(forumErrorMessage(l10n, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;

    final pendingReplies = state.myForumPosts
        .where((p) => p.isPendingReview && p.parentId == widget.root.id)
        .toList();

    return PopScope<ForumThreadResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(
          result ?? ForumThreadResult(replyCount: _visibleReplyCount),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.forumThreadTitle)),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _PostCard(
                    post: widget.root,
                    isRoot: true,
                    onReport: _reportPost,
                    onDelete: _deletePost,
                  ),
                  const Divider(height: 1),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_loadFailed)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.forumLoadError,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                    ..._replies.map(
                      (reply) => _PostCard(
                        post: reply,
                        onReport: _reportPost,
                        onDelete: _deletePost,
                      ),
                    ),
                    ...pendingReplies.map(
                      (reply) => _PostCard(post: reply, pending: true),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('forum_reply_field'),
                        controller: _replyController,
                        maxLength: 2000,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: l10n.forumReplyHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('forum_reply_submit'),
                      tooltip: l10n.forumReplyAction,
                      onPressed: _submitting ? null : _submitReply,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    this.isRoot = false,
    this.pending = false,
    this.onReport,
    this.onDelete,
  });

  final ForumPost post;
  final bool isRoot;
  final bool pending;
  final void Function(ForumPost)? onReport;
  final void Function(ForumPost)? onDelete;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mine = state.isMyForumPost(post.id);
    final reported = state.isForumPostReported(post.id);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, isRoot ? 16 : 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.authorName,
                  style: isRoot
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                l10n.forumTimeAgo(post.createdAt),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (!pending && (mine || onReport != null))
                PopupMenuButton<String>(
                  key: Key('forum_post_menu_${post.id}'),
                  onSelected: (action) {
                    if (action == 'report') onReport?.call(post);
                    if (action == 'delete') onDelete?.call(post);
                  },
                  itemBuilder: (context) => [
                    if (!mine)
                      PopupMenuItem(
                        value: 'report',
                        enabled: !reported,
                        child: Text(
                          reported ? l10n.forumReported : l10n.forumReportSpam,
                        ),
                      ),
                    if (mine)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.forumDeletePost),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(post.body, style: theme.textTheme.bodyMedium),
          ),
          if (pending) ...[
            const SizedBox(height: 4),
            Chip(
              avatar: const Icon(Icons.hourglass_top, size: 16),
              label: Text(l10n.forumPendingReview),
              visualDensity: VisualDensity.compact,
            ),
          ],
          if (!isRoot) const SizedBox(height: 4),
        ],
      ),
    );
  }
}

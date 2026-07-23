import 'package:agrilumina/models/forum_post.dart';

/// Kind of queued forum write.
enum ForumOutboxKind { post, reply, report }

/// A forum write captured while offline, awaiting replay. Ops are FIFO and
/// independent: replies always reference real server ids (queued posts are
/// not tappable, so nothing can reply to an unsent post).
class PendingForumOp {
  PendingForumOp({
    required this.kind,
    required this.id,
    this.body = '',
    this.authorName = '',
    this.parentId,
    this.postId,
    required this.createdAt,
    this.failed = false,
  });

  final ForumOutboxKind kind;

  /// Client temp id (`queued-<uuid>`) for posts/replies; doubles as the
  /// display id so the queued tile is stable across rebuilds.
  final String id;

  final String body;

  /// Display-name snapshot at compose time (later profile edits don't
  /// rewrite queued posts).
  final String authorName;

  /// Reply target (real server id).
  final String? parentId;

  /// Report target (real server id).
  final String? postId;

  final DateTime createdAt;

  /// True when the last replay attempt got a non-offline, non-drop error.
  bool failed;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'id': id,
        'body': body,
        'authorName': authorName,
        'parentId': parentId,
        'postId': postId,
        'createdAt': createdAt.toIso8601String(),
        'failed': failed,
      };

  static PendingForumOp? fromJson(Map<String, Object?> json) {
    final kind = switch (json['kind']) {
      'post' => ForumOutboxKind.post,
      'reply' => ForumOutboxKind.reply,
      'report' => ForumOutboxKind.report,
      _ => null,
    };
    final id = json['id'];
    if (kind == null || id is! String || id.isEmpty) return null;
    return PendingForumOp(
      kind: kind,
      id: id,
      body: json['body'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      parentId: json['parentId'] as String?,
      postId: json['postId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      failed: json['failed'] == true,
    );
  }

  /// Display form for queued posts/replies (null for reports).
  ForumPost? toDisplayPost() {
    if (kind == ForumOutboxKind.report) return null;
    return ForumPost(
      id: id,
      parentId: parentId,
      authorName: authorName,
      body: body,
      createdAt: createdAt,
      status: ForumPostStatus.queued,
    );
  }
}

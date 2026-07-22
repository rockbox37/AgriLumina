/// Publication state of one of *my* forum posts as reported by the backend.
///
/// Public feed posts are always effectively [visible]; `pendingReview` only
/// ever applies to the author's own posts held by the spam filter.
enum ForumPostStatus { visible, pendingReview }

/// A forum post: a thread root (null [parentId]) or a single-level reply.
class ForumPost {
  const ForumPost({
    required this.id,
    this.parentId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.replyCount = 0,
    DateTime? lastActivityAt,
    this.status = ForumPostStatus.visible,
  }) : lastActivityAt = lastActivityAt ?? createdAt;

  final String id;
  final String? parentId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  /// Visible replies (roots only).
  final int replyCount;

  /// Thread sort key; bumped when a visible reply arrives (roots only).
  final DateTime lastActivityAt;

  /// Only meaningful for posts authored on this device.
  final ForumPostStatus status;

  bool get isRoot => parentId == null;
  bool get isPendingReview => status == ForumPostStatus.pendingReview;

  ForumPost copyWith({
    int? replyCount,
    DateTime? lastActivityAt,
    ForumPostStatus? status,
  }) =>
      ForumPost(
        id: id,
        parentId: parentId,
        authorName: authorName,
        body: body,
        createdAt: createdAt,
        replyCount: replyCount ?? this.replyCount,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
        status: status ?? this.status,
      );

  /// Parses a row from the public `forum_public_posts` view (or the local
  /// cache, which uses the same shape plus an optional `status`).
  static ForumPost? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final authorName = json['author_name'];
    final body = json['body'];
    final createdAt =
        DateTime.tryParse(json['created_at'] as String? ?? '');
    if (id is! String || authorName is! String || body is! String) {
      return null;
    }
    if (createdAt == null) return null;
    return ForumPost(
      id: id,
      parentId: json['parent_id'] as String?,
      authorName: authorName,
      body: body,
      createdAt: createdAt,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      lastActivityAt:
          DateTime.tryParse(json['last_activity_at'] as String? ?? ''),
      status: json['status'] == 'pending_review'
          ? ForumPostStatus.pendingReview
          : ForumPostStatus.visible,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'parent_id': parentId,
        'author_name': authorName,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'reply_count': replyCount,
        'last_activity_at': lastActivityAt.toIso8601String(),
        'status': status == ForumPostStatus.pendingReview
            ? 'pending_review'
            : 'visible',
      };
}

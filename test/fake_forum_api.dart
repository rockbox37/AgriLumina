import 'package:agrilumina/models/forum_post.dart';
import 'package:agrilumina/services/forum_api.dart';

/// Configurable in-memory ForumApi for tests.
class FakeForumApi implements ForumApi {
  FakeForumApi({
    List<ForumPost>? threads,
    Map<String, List<ForumPost>>? replies,
  })  : threads = threads ?? [],
        replies = replies ?? {};

  List<ForumPost> threads;
  Map<String, List<ForumPost>> replies;
  bool offline = false;
  ForumPostStatus nextCreateStatus = ForumPostStatus.visible;

  /// Per-call createPost outcomes; when non-empty, each call consumes one
  /// entry (an Exception to throw, or null to succeed).
  final List<Exception?> createResults = [];

  Exception? reportFailWith;

  final List<String> reportedPostIds = [];
  final List<String> deletedPostIds = [];
  final List<({String body, String? parentId})> created = [];
  int createCalls = 0;
  int contactCount = 0;
  int _idCounter = 0;

  void _failIfOffline() {
    if (offline) throw ForumOfflineException();
  }

  @override
  Future<List<ForumPost>> fetchThreads({DateTime? before}) async {
    _failIfOffline();
    return threads;
  }

  @override
  Future<List<ForumPost>> fetchReplies(String threadId) async {
    _failIfOffline();
    return replies[threadId] ?? const [];
  }

  @override
  Future<ForumPost> createPost({
    required String deviceId,
    required String authorName,
    required String body,
    String? parentId,
  }) async {
    createCalls++;
    if (createResults.isNotEmpty) {
      final result = createResults.removeAt(0);
      if (result != null) throw result;
    } else {
      _failIfOffline();
    }
    created.add((body: body, parentId: parentId));
    return ForumPost(
      id: 'created-${_idCounter++}',
      parentId: parentId,
      authorName: authorName,
      body: body,
      createdAt: DateTime.now(),
      status: nextCreateStatus,
    );
  }

  @override
  Future<void> reportPost({
    required String deviceId,
    required String postId,
  }) async {
    _failIfOffline();
    final error = reportFailWith;
    if (error != null) throw error;
    reportedPostIds.add(postId);
  }

  @override
  Future<void> deletePost({
    required String deviceId,
    required String postId,
  }) async {
    _failIfOffline();
    deletedPostIds.add(postId);
  }
}

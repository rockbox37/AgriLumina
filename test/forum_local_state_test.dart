import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/models/forum_post.dart';
import 'package:agrilumina/services/local_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStateStore> freshStore() async {
    return LocalStateStore(await SharedPreferences.getInstance());
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('deviceId is generated once and stays stable', () async {
    final store = await freshStore();
    final first = store.deviceId();

    expect(first, isNotEmpty);
    expect(store.deviceId(), first);

    // A new store over the same prefs sees the same id.
    final reopened = await freshStore();
    expect(reopened.deviceId(), first);
  });

  test('forum thread cache round-trips', () async {
    final store = await freshStore();
    final post = ForumPost(
      id: '11111111-1111-4111-8111-111111111111',
      authorName: 'Amani',
      body: 'Maize prices are up',
      createdAt: DateTime.utc(2026, 7, 22, 10),
      replyCount: 3,
      lastActivityAt: DateTime.utc(2026, 7, 22, 11),
    );

    await store.saveForumThreadCache([post]);
    final loaded = store.loadForumThreadCache();

    expect(loaded, hasLength(1));
    expect(loaded.first.id, post.id);
    expect(loaded.first.replyCount, 3);
    expect(loaded.first.lastActivityAt, post.lastActivityAt);
  });

  test('my posts keep pending status across reloads', () async {
    final store = await freshStore();
    final pending = ForumPost(
      id: '22222222-2222-4222-8222-222222222222',
      authorName: 'Amani',
      body: 'Held for review',
      createdAt: DateTime.utc(2026, 7, 22, 10),
      status: ForumPostStatus.pendingReview,
    );

    await store.saveMyForumPosts([pending]);
    final loaded = store.loadMyForumPosts();

    expect(loaded.single.isPendingReview, isTrue);
  });

  test('reported ids round-trip', () async {
    final store = await freshStore();
    await store.saveReportedForumPostIds({'b', 'a'});

    expect(store.loadReportedForumPostIds(), {'a', 'b'});
  });

  test('corrupt forum cache degrades to empty', () async {
    SharedPreferences.setMockInitialValues({
      'mvp.forumThreadCache': 'not json',
    });
    final store = await freshStore();

    expect(store.loadForumThreadCache(), isEmpty);
  });
}

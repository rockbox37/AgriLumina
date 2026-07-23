import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/models/forum_post.dart';
import 'package:agrilumina/services/forum_api.dart';
import 'package:agrilumina/services/local_state_store.dart';

import 'fake_connectivity_service.dart';
import 'fake_forum_api.dart';
import 'fake_listings_api.dart';
import 'fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeForumApi api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeForumApi();
  });

  Future<AppState> makeState({FakeConnectivityService? connectivity}) async {
    final store = LocalStateStore(await SharedPreferences.getInstance());
    return AppState.fromStore(
      store,
      locationService: FakeLocationService(),
      listingsApi: FakeListingsApi(),
      forumApi: api,
      connectivity: connectivity,
    );
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('queueing', () {
    test('queued post persists and shows as a queued display post', () async {
      api.offline = true;
      final state = await makeState();

      final post = state.queueForumPost(body: 'Offline news from Bugobe');
      await settle();

      expect(post.isQueued, isTrue);
      expect(state.queuedForumPosts.single.body, 'Offline news from Bugobe');
      expect(api.created, isEmpty);

      // Cold start over the same prefs still sees the op.
      final reloaded = await makeState();
      expect(reloaded.forumOutbox, hasLength(1));
      expect(reloaded.queuedForumPosts.single.isRoot, isTrue);
    });

    test('flush success moves the post into myForumPosts', () async {
      api.offline = true;
      final state = await makeState();
      state.queueForumPost(body: 'Will send later');
      await settle();

      api.offline = false;
      await state.syncForumOutbox();

      expect(state.forumOutbox, isEmpty);
      expect(state.queuedForumPosts, isEmpty);
      expect(state.myForumPosts.single.body, 'Will send later');
      expect(state.myForumPosts.single.status, ForumPostStatus.visible);
    });

    test('flush landing as pending_review keeps the review chip flow',
        () async {
      api.offline = true;
      final state = await makeState();
      state.queueForumPost(body: 'suspicious content');
      await settle();

      api.offline = false;
      api.nextCreateStatus = ForumPostStatus.pendingReview;
      await state.syncForumOutbox();

      expect(state.myForumPosts.single.isPendingReview, isTrue);
    });
  });

  group('replay outcomes', () {
    test('offline stops the pass after the first attempt', () async {
      api.offline = true;
      final state = await makeState();
      state.queueForumPost(body: 'first');
      state.queueForumPost(body: 'second');
      await settle();
      final callsBefore = api.createCalls;

      await state.syncForumOutbox();

      expect(api.createCalls - callsBefore, 1);
      expect(state.forumOutbox, hasLength(2));
    });

    test('429 stops the pass, keeps the op, and retries via timer', () async {
      final state = await makeState();
      api.createResults.add(const ForumRateLimitedException(1));
      state.queueForumPost(body: 'rate limited once');
      await settle();

      expect(state.forumOutbox, hasLength(1));
      // The timer (clamped to >=5s) will eventually flush; simulate the
      // retry firing by calling sync again once the fake succeeds.
      await state.syncForumOutbox();
      expect(state.forumOutbox, isEmpty);
      expect(api.created.single.body, 'rate limited once');
    });

    test('409 duplicate drops silently', () async {
      final state = await makeState();
      api.createResults.add(ForumDuplicateException());
      state.queueForumPost(body: 'already there');
      await settle();

      expect(state.forumOutbox, isEmpty);
      expect(state.myForumPosts, isEmpty);
    });

    test('invalid_parent drops the reply and raises the one-shot notice',
        () async {
      final state = await makeState();
      api.createResults
          .add(const ForumApiException(400, 'invalid_parent'));
      state.queueForumPost(body: 'orphan reply', parentId: 'gone-parent');
      await settle();

      expect(state.forumOutbox, isEmpty);
      expect(state.takeDroppedForumReplyNotice(), 1);
      expect(state.takeDroppedForumReplyNotice(), 0);
    });

    test('500 marks failed, continues, and drains FIFO on retry', () async {
      api.offline = true;
      final state = await makeState();
      state.queueForumPost(body: 'poisoned once');
      state.queueForumPost(body: 'second in line');
      await settle();

      api.offline = false;
      api.createResults.add(const ForumApiException(500));
      api.createResults.add(null);
      await state.syncForumOutbox();

      // First op failed (kept), second succeeded.
      expect(state.forumOutbox, hasLength(1));
      expect(state.forumOutbox.single.failed, isTrue);
      expect(state.isQueuedOpFailed(state.forumOutbox.single.id), isTrue);
      expect(api.created.single.body, 'second in line');

      await state.syncForumOutbox();
      expect(state.forumOutbox, isEmpty);
      expect(api.created.map((c) => c.body), [
        'second in line',
        'poisoned once',
      ]);
    });
  });

  group('reports', () {
    test('report marks reported immediately and flushes when online',
        () async {
      api.offline = true;
      final state = await makeState();

      state.queueForumReport('post-1');
      await settle();

      expect(state.isForumPostReported('post-1'), isTrue);
      expect(api.reportedPostIds, isEmpty);

      api.offline = false;
      await state.syncForumOutbox();
      expect(api.reportedPostIds, ['post-1']);
      expect(state.forumOutbox, isEmpty);
    });

    test('failed report is dropped but stays marked locally', () async {
      final state = await makeState();
      api.reportFailWith = const ForumApiException(404, 'not_found');

      state.queueForumReport('vanished-post');
      await settle();

      expect(state.forumOutbox, isEmpty);
      expect(api.reportedPostIds, isEmpty);
      expect(state.isForumPostReported('vanished-post'), isTrue);
    });

    test('duplicate queueForumReport is a no-op', () async {
      api.offline = true;
      final state = await makeState();

      state.queueForumReport('post-1');
      state.queueForumReport('post-1');
      await settle();

      expect(state.forumOutbox, hasLength(1));
    });
  });

  group('connectivity', () {
    test('reconnect flushes both the listing queue and the forum outbox',
        () async {
      final connectivity = FakeConnectivityService();
      api.offline = true;
      final listings = FakeListingsApi()..offline = true;
      final store = LocalStateStore(await SharedPreferences.getInstance());
      final state = AppState.fromStore(
        store,
        locationService: FakeLocationService(),
        listingsApi: listings,
        forumApi: api,
        connectivity: connectivity,
      );

      state.publishMyListing(
        crop: 'Maize',
        quantityHint: '5 bags',
        phone: '+243970000009',
      );
      state.queueForumPost(body: 'queued while offline');
      await settle();
      expect(listings.upserts, isEmpty);
      expect(api.created, isEmpty);

      api.offline = false;
      listings.offline = false;
      connectivity.emitReconnected();
      await settle();
      await settle();

      expect(listings.upserts, hasLength(1));
      expect(api.created.single.body, 'queued while offline');
    });

    test('dispose cancels the subscription and the service', () async {
      final connectivity = FakeConnectivityService();
      final state = await makeState(connectivity: connectivity);
      state.queueForumPost(body: 'never sent after dispose');
      await settle();
      final callsBefore = api.createCalls;

      state.dispose();
      expect(connectivity.disposed, isTrue);
      connectivity.emitReconnected();
      await settle();
      expect(api.createCalls, callsBefore);
    });
  });
}

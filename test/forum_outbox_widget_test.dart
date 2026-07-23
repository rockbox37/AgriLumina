import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/app_localizations.dart';
import 'package:agrilumina/models/forum_post.dart';
import 'package:agrilumina/screens/forum_screen.dart';
import 'package:agrilumina/services/local_state_store.dart';

import 'fake_forum_api.dart';
import 'fake_listings_api.dart';
import 'fake_location_service.dart';

ForumPost thread(String id, String body) => ForumPost(
      id: id,
      authorName: 'Amani K.',
      body: body,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

void main() {
  Future<AppState> pumpForum(WidgetTester tester, FakeForumApi api) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStateStore(await SharedPreferences.getInstance());
    final state = AppState(
      displayName: 'Chantal',
      store: store,
      locationService: FakeLocationService(),
      listingsApi: FakeListingsApi(),
      forumApi: api,
    );
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ForumScreen(api: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('offline compose queues the post with a waiting chip',
      (tester) async {
    final api = FakeForumApi(threads: [thread('t1', 'Existing thread')]);
    final state = await pumpForum(tester, api);
    api.offline = true;

    await tester.tap(find.byKey(const Key('forum_new_post')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('forum_compose_field')),
      'Composed while offline',
    );
    await tester.tap(find.byKey(const Key('forum_compose_submit')));
    await tester.pumpAndSettle();

    // Sheet closed, queued explainer shown, tile with the waiting chip
    // rendered above the feed.
    expect(find.byKey(const Key('forum_compose_field')), findsNothing);
    expect(
      find.text(
        "You're offline — this will be sent automatically when you "
        'reconnect.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('forum_queued_chip')), findsOneWidget);
    expect(find.text('Waiting to send'), findsOneWidget);
    expect(find.text('Composed while offline'), findsOneWidget);
    expect(state.forumOutbox, hasLength(1));
  });

  testWidgets('pull-to-refresh flushes the queue and converts the tile',
      (tester) async {
    final api = FakeForumApi(threads: [thread('t1', 'Existing thread')]);
    final state = await pumpForum(tester, api);
    api.offline = true;
    state.queueForumPost(body: 'Queued post body');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('forum_queued_chip')), findsOneWidget);

    api.offline = false;
    await tester.fling(
      find.text('Existing thread'),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('forum_queued_chip')), findsNothing);
    expect(state.forumOutbox, isEmpty);
    expect(api.created.single.body, 'Queued post body');
    // The sent post is now an own post (visible in the local overlay).
    expect(state.myForumPosts.single.body, 'Queued post body');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/app_localizations.dart';
import 'package:agrilumina/models/forum_post.dart';
import 'package:agrilumina/screens/forum_screen.dart';
import 'package:agrilumina/services/forum_api.dart';
import 'package:agrilumina/services/local_state_store.dart';

import 'fake_forum_api.dart';

ForumPost thread(String id, String body, {int replyCount = 0}) => ForumPost(
      id: id,
      authorName: 'Amani K.',
      body: body,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      replyCount: replyCount,
    );

Future<AppState> pumpForum(
  WidgetTester tester,
  ForumApi api, {
  String displayName = 'Chantal',
}) async {
  SharedPreferences.setMockInitialValues({});
  final store = LocalStateStore(await SharedPreferences.getInstance());
  final state = AppState(
    displayName: displayName,
    store: store,
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

void main() {
  testWidgets('shows threads with author, preview, and reply count',
      (tester) async {
    final api = FakeForumApi(
      threads: [
        thread('t1', 'Maize prices at Bugobe went up', replyCount: 2),
        thread('t2', 'Anyone storing cassava this season?'),
      ],
    );
    await pumpForum(tester, api);

    expect(find.text('Maize prices at Bugobe went up'), findsOneWidget);
    expect(find.text('Anyone storing cassava this season?'), findsOneWidget);
    expect(find.text('2 replies'), findsOneWidget);
    expect(find.text('No replies'), findsOneWidget);
  });

  testWidgets('offline shows banner with cached threads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStateStore(await SharedPreferences.getInstance());
    await store.saveForumThreadCache([thread('t1', 'Cached post body')]);

    final api = FakeForumApi()..offline = true;
    final state = AppState(
      displayName: 'Chantal',
      store: store,
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

    expect(
      find.text("You're offline — showing saved posts."),
      findsOneWidget,
    );
    expect(find.text('Cached post body'), findsOneWidget);
  });

  testWidgets('posting requires a profile name', (tester) async {
    final api = FakeForumApi();
    await pumpForum(tester, api, displayName: '');

    await tester.tap(find.byKey(const Key('forum_new_post')));
    await tester.pumpAndSettle();

    expect(
      find.text('Add your name in Profile before posting.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('forum_compose_field')), findsNothing);
  });

  testWidgets('composing a visible post adds it to the top of the list',
      (tester) async {
    final api = FakeForumApi(threads: [thread('t1', 'Existing thread')]);
    await pumpForum(tester, api);

    await tester.tap(find.byKey(const Key('forum_new_post')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('forum_compose_field')),
      'Fresh news from the market',
    );
    await tester.tap(find.byKey(const Key('forum_compose_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Fresh news from the market'), findsOneWidget);
    expect(find.byKey(const Key('forum_compose_field')), findsNothing);
  });

  testWidgets('post held by the spam filter shows awaiting-review chip',
      (tester) async {
    final api = FakeForumApi()
      ..nextCreateStatus = ForumPostStatus.pendingReview;
    final state = await pumpForum(tester, api);

    await tester.tap(find.byKey(const Key('forum_new_post')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('forum_compose_field')),
      'Suspicious-looking post',
    );
    await tester.tap(find.byKey(const Key('forum_compose_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Suspicious-looking post'), findsOneWidget);
    expect(find.byKey(const Key('forum_pending_chip')), findsOneWidget);
    expect(find.text('Awaiting review'), findsOneWidget);
    expect(state.myForumPosts.single.isPendingReview, isTrue);
  });

  testWidgets('report spam flows through the thread screen', (tester) async {
    final root = thread('t1', 'Root post body', replyCount: 1);
    final reply = ForumPost(
      id: 'r1',
      parentId: 't1',
      authorName: 'Jean-Paul B.',
      body: 'A reply worth reporting',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );
    final api = FakeForumApi(threads: [root], replies: {'t1': [reply]});
    final state = await pumpForum(tester, api);

    await tester.tap(find.text('Root post body'));
    await tester.pumpAndSettle();
    expect(find.text('A reply worth reporting'), findsOneWidget);

    await tester.tap(find.byKey(const Key('forum_post_menu_r1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This is spam'));
    await tester.pumpAndSettle();

    expect(api.reportedPostIds, ['r1']);
    expect(state.isForumPostReported('r1'), isTrue);
    expect(find.text('Thanks — this post was reported.'), findsOneWidget);

    // Menu now shows the disabled "Reported" entry.
    await tester.tap(find.byKey(const Key('forum_post_menu_r1')));
    await tester.pumpAndSettle();
    expect(find.text('Reported'), findsOneWidget);
  });

  testWidgets('own reply can be deleted from the thread screen',
      (tester) async {
    final root = thread('t1', 'Root post body');
    final api = FakeForumApi(threads: [root]);
    final state = await pumpForum(tester, api);

    await tester.tap(find.text('Root post body'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('forum_reply_field')),
      'My own reply',
    );
    await tester.tap(find.byKey(const Key('forum_reply_submit')));
    await tester.pumpAndSettle();
    expect(find.text('My own reply'), findsOneWidget);
    final replyId = state.myForumPosts.single.id;

    await tester.tap(find.byKey(Key('forum_post_menu_$replyId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forum_delete_confirm')));
    await tester.pumpAndSettle();

    expect(api.deletedPostIds, [replyId]);
    expect(find.text('My own reply'), findsNothing);
    expect(state.myForumPosts, isEmpty);
  });
}

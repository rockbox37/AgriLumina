import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/admin/admin_api.dart';
import 'package:agrilumina/admin/admin_state.dart';
import 'package:agrilumina/admin/main_admin.dart';

/// Fake backend for the login -> overview smoke path.
MockClient fakeBackend() => MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        final body = jsonDecode(request.body) as Map;
        if (body['password'] != 'right-password') {
          return http.Response(
            jsonEncode({'error_description': 'Invalid login credentials'}),
            400,
          );
        }
        return http.Response(
          jsonEncode({
            'access_token': 'jwt-1',
            'refresh_token': 'refresh-1',
            'user': {'email': 'admin@test.local'},
          }),
          200,
        );
      }
      if (request.url.path == '/rest/v1/rpc/admin_stats') {
        return http.Response(
          jsonEncode({
            'posts_by_status': {'visible': 7, 'hidden': 2, 'spam': 1},
            'posts_24h': 5,
            'posts_7d': 9,
            'reports_24h': 1,
            'reports_7d': 4,
            'active_devices_24h': 3,
            'active_devices_7d': 6,
            'banned_devices': 1,
            'unread_alerts': 2,
            'top_reported': [
              {
                'id': 'p1',
                'author_name': 'Suspicious Sam',
                'snippet': 'Dubious offer',
                'status': 'hidden',
                'report_count': 4,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('[]', 200);
    });

Future<AdminState> pumpAdminApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final state = AdminState(
    api: AdminApi(client: fakeBackend()),
    prefs: prefs,
  );
  await tester.pumpWidget(AdminApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('wrong password shows the auth error', (tester) async {
    await pumpAdminApp(tester);

    await tester.enterText(
      find.byKey(const Key('admin_email')),
      'admin@test.local',
    );
    await tester.enterText(
      find.byKey(const Key('admin_password')),
      'wrong',
    );
    await tester.tap(find.byKey(const Key('admin_login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid login credentials'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
  });

  testWidgets('login lands on overview with stats and alert badge',
      (tester) async {
    final state = await pumpAdminApp(tester);

    await tester.enterText(
      find.byKey(const Key('admin_email')),
      'admin@test.local',
    );
    await tester.enterText(
      find.byKey(const Key('admin_password')),
      'right-password',
    );
    await tester.tap(find.byKey(const Key('admin_login_submit')));
    await tester.pumpAndSettle();

    expect(state.signedIn, isTrue);
    // Stat tiles from admin_stats.
    expect(find.text('Visible posts'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Pending review'), findsOneWidget);
    // Top reported list.
    expect(find.textContaining('Suspicious Sam'), findsOneWidget);
    expect(find.text('4 reports'), findsOneWidget);
    // Unread badge on the Alerts destination.
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('logout returns to the login screen', (tester) async {
    final state = await pumpAdminApp(tester);
    await tester.enterText(
      find.byKey(const Key('admin_email')),
      'admin@test.local',
    );
    await tester.enterText(
      find.byKey(const Key('admin_password')),
      'right-password',
    );
    await tester.tap(find.byKey(const Key('admin_login_submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin_logout')));
    await tester.pumpAndSettle();

    expect(state.signedIn, isFalse);
    expect(find.byKey(const Key('admin_login_submit')), findsOneWidget);
  });
}

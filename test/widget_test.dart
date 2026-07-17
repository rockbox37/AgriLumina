import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/main.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:agrilumina/utils/geo.dart';

import 'fake_location_service.dart';

void main() {
  testWidgets('Home shows shared credits and role control', (tester) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agrilumina'), findsOneWidget);
    expect(find.text('5 credits'), findsWidgets);
    expect(find.text('I am a…'), findsOneWidget);
    expect(find.text('5 nearby buyers'), findsOneWidget);
  });

  testWidgets('Discover lists buyers and unlock spends a credit', (tester) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.text('Nearby buyers'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsOneWidget);
    expect(
      find.textContaining('Showing distances from sample listings near Bugobe'),
      findsOneWidget,
    );

    await tester.tap(find.text('Jean-Pierre M.'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unlock for 1 credit'), findsOneWidget);
    await tester.tap(find.textContaining('Unlock for 1 credit'));
    await tester.pumpAndSettle();

    expect(find.text('+243 970 111 201'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('4 credits'), findsWidgets);
  });

  testWidgets('Discover shows GPS label when location succeeds', (tester) async {
    await tester.pumpWidget(
      MyApp(
        locationService: FakeLocationService(
          result: LocationFetchResult.success(
            UserLocation(
              latitude: bugobeLatitude,
              longitude: bugobeLongitude,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Near you · Near Bugobe, DRC'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsOneWidget);
  });
}

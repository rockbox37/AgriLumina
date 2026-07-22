import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilumina/main.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/listings_api.dart';
import 'package:agrilumina/services/local_state_store.dart';

import 'fake_listings_api.dart';
import 'fake_location_service.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeListingsApi api) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStateStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MyApp(
        locationService: FakeLocationService(),
        listingsApi: api,
        stateStore: store,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDiscover(WidgetTester tester) async {
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
  }

  testWidgets('Discover shows remote counterparts and hides seeds',
      (tester) async {
    final api = FakeListingsApi();
    api.rows[UserRole.buyer] = [
      remoteListing('r1', name: 'Remote Rita', crop: 'Maize'),
    ];
    await pumpApp(tester, api);
    await openDiscover(tester);

    expect(find.text('Remote Rita'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsNothing);
    expect(find.byKey(const Key('discover_feed_banner')), findsNothing);
  });

  testWidgets('offline with no cache shows sample banner and seeds',
      (tester) async {
    final api = FakeListingsApi()..offline = true;
    await pumpApp(tester, api);
    await openDiscover(tester);

    expect(find.byKey(const Key('discover_feed_banner')), findsOneWidget);
    expect(
      find.text("Can't connect — showing sample listings."),
      findsOneWidget,
    );
    expect(find.text('Jean-Pierre M.'), findsOneWidget);
  });

  testWidgets('remote unlock fetches the phone and spends one credit',
      (tester) async {
    final api = FakeListingsApi();
    api.rows[UserRole.buyer] = [
      remoteListing('r1', name: 'Remote Rita', crop: 'Maize'),
    ];
    api.phones['r1'] = '+243 970 222 333';
    await pumpApp(tester, api);
    await openDiscover(tester);

    await tester.tap(find.text('Remote Rita'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('listing_unlock_button')));
    await tester.pumpAndSettle();

    expect(find.text('+243 970 222 333'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(api.contactCount, 1);
  });

  testWidgets('offline unlock keeps the credit and explains', (tester) async {
    final api = FakeListingsApi();
    api.rows[UserRole.buyer] = [
      remoteListing('r1', name: 'Remote Rita', crop: 'Maize'),
    ];
    await pumpApp(tester, api);
    await openDiscover(tester);
    api.contactError = ListingsOfflineException();

    await tester.tap(find.text('Remote Rita'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('listing_unlock_button')));
    await tester.pumpAndSettle();

    expect(
      find.text("You're offline. No credit was used — try again later."),
      findsOneWidget,
    );
    expect(find.textContaining('You have 5 credits'), findsOneWidget);
  });

  testWidgets('profile chip surfaces failed sync and retries on tap',
      (tester) async {
    final api = FakeListingsApi()..failWith = const ListingsApiException(500);
    await pumpApp(tester, api);

    // Publish from Profile -> My listing (card sits below the fold).
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Publish my listing'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Publish my listing'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Quantity'),
      '5 bags',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone'),
      '+243970000009',
    );
    await tester.tap(find.text('Save listing'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('profile_listing_sync_chip')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Sync failed — tap to retry'),
      findsOneWidget,
    );

    api.failWith = null;
    await tester.tap(find.byKey(const Key('profile_listing_sync_chip')));
    await tester.pumpAndSettle();

    expect(find.text('Synced'), findsOneWidget);
    expect(api.upserts, hasLength(1));
  });
}

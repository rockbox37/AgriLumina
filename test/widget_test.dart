import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/main.dart';
import 'package:agrilumina/screens/listing_detail_screen.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:agrilumina/utils/geo.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

import 'fake_contact_launcher.dart';
import 'fake_location_service.dart';

void main() {
  testWidgets('Home shows shared credits and role control', (tester) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('AgriLumina'), findsWidgets);
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
      find.textContaining('Showing distances from sample listings'),
      findsOneWidget,
    );

    await tester.tap(find.text('Jean-Pierre M.'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unlock for 1 credit'), findsOneWidget);
    await tester.tap(find.textContaining('Unlock for 1 credit'));
    await tester.pumpAndSettle();

    expect(find.text('+243 970 111 201'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Nearby buyers'), findsOneWidget);
    expect(find.text('4 credits'), findsWidgets);
  });

  testWidgets('App bar brand icon switches shell tab to Home', (tester) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby buyers'), findsOneWidget);

    await tester.tap(find.byKey(BrandHomeLeading.buttonKey));
    await tester.pumpAndSettle();

    expect(find.text('I am a…'), findsOneWidget);
    expect(find.text('Nearby buyers'), findsNothing);
  });

  testWidgets('App bar brand icon from listing detail returns to Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jean-Pierre M.'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unlock for 1 credit'), findsOneWidget);
    // Pushed detail keeps BackButton beside the brand home control.
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byKey(BrandHomeLeading.buttonKey), findsOneWidget);

    await tester.tap(find.byKey(BrandHomeLeading.buttonKey));
    await tester.pumpAndSettle();

    expect(find.text('I am a…'), findsOneWidget);
    expect(find.text('Nearby buyers'), findsNothing);
    expect(find.textContaining('Unlock for 1 credit'), findsNothing);
  });

  testWidgets('Discover soft-filters by selling interests by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    // Seed sellingInterests = [Maize] soft-filters counterparts.
    expect(find.text('Showing crops you sell'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsOneWidget);
    expect(find.text('Grace Trading'), findsOneWidget);
    expect(find.text('Amina K.'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Showing crops you sell'), findsNothing);
    expect(find.text('Jean-Pierre M.'), findsOneWidget);
    expect(find.text('Amina K.'), findsOneWidget);
  });

  testWidgets('Discover crop filter narrows list and shows empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Jean-Pierre M.'), findsOneWidget);
    expect(find.text('Amina K.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Cassava'));
    await tester.pumpAndSettle();

    expect(find.text('Amina K.'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Rice'));
    await tester.pumpAndSettle();

    expect(find.text('No Rice buyers nearby.'), findsOneWidget);
    expect(find.text('Amina K.'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Jean-Pierre M.'), findsOneWidget);
    expect(find.text('Amina K.'), findsOneWidget);
  });

  testWidgets('Role change clears chip and applies buying interests', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Cassava'));
    await tester.pumpAndSettle();
    expect(find.text('Amina K.'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Add Beans to buying interests, then switch role to Buyer.
    await tester.tap(find.widgetWithText(FilterChip, 'Beans').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buyer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.text('Showing crops you buy'), findsOneWidget);
    expect(find.text('Find Sellers'), findsOneWidget);
    // Soft-filter to Beans sellers; Cassava chip override was cleared.
    expect(find.text('Esther W.'), findsOneWidget);
    expect(find.text('Marie L.'), findsNothing);
    expect(find.text('Joseph Farm'), findsNothing);
  });

  testWidgets('Profile shows buying and selling interest sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Buying interests'), findsOneWidget);
    expect(find.text('Selling interests'), findsOneWidget);
    expect(
      find.text('None yet — add crops you want to buy'),
      findsOneWidget,
    );
    expect(find.text('Crop interest'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Maize'), findsWidgets);

    await tester.tap(find.text('Buyer'));
    await tester.pumpAndSettle();
    // Both sections remain editable regardless of role.
    expect(find.text('Buying interests'), findsOneWidget);
    expect(find.text('Selling interests'), findsOneWidget);

    // First Beans chip is under Buying interests.
    await tester.tap(find.widgetWithText(FilterChip, 'Beans').first);
    await tester.pumpAndSettle();
    expect(find.text('None yet — add crops you want to buy'), findsNothing);
  });

  testWidgets('Unlocked contact Call and WhatsApp use launcher', (tester) async {
    final launcher = FakeContactLauncher();
    final state = AppState(locationService: FakeLocationService());
    expect(state.unlockContact('b1'), isTrue);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: ListingDetailScreen(
            listingId: 'b1',
            contactLauncher: launcher,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call'));
    await tester.pumpAndSettle();
    expect(launcher.lastCallPhone, '+243 970 111 201');

    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(launcher.lastWhatsAppPhone, '+243 970 111 201');
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

    expect(find.textContaining('Near you · Near sample area'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsOneWidget);
  });

  testWidgets('Discover search narrows list and clears to restore', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('discover_search_field')), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsOneWidget);
    expect(find.text('Grace Trading'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('discover_search_field')),
      'Kabare',
    );
    await tester.pumpAndSettle();

    expect(find.text('Grace Trading'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Jean-Pierre M.'), findsOneWidget);
    expect(find.text('Grace Trading'), findsOneWidget);
  });

  testWidgets('Discover search composes with crop chip and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Maize'));
    await tester.pumpAndSettle();

    expect(find.text('Jean-Pierre M.'), findsOneWidget);
    expect(find.text('Grace Trading'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('discover_search_field')),
      'Kabare',
    );
    await tester.pumpAndSettle();

    expect(find.text('Grace Trading'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('discover_search_field')),
      'zzzz-no-match',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No matches for "zzzz-no-match" among Maize buyers.'),
      findsOneWidget,
    );
  });

  testWidgets('Discover search works for buyer role (Find Sellers)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buyer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    // Empty buyingInterests → all counterpart sellers (no soft crop filter).
    expect(find.text('Find Sellers'), findsOneWidget);
    expect(find.text('Marie L.'), findsOneWidget);
    expect(find.text('Samuel Growers'), findsOneWidget);
    expect(find.text('Showing crops you buy'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('discover_search_field')),
      'Kabare',
    );
    await tester.pumpAndSettle();

    expect(find.text('Samuel Growers'), findsOneWidget);
    expect(find.text('Marie L.'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('discover_search_field')),
      'nope',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No matches for "nope" among sellers.'),
      findsOneWidget,
    );
  });
}


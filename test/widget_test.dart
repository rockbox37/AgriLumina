import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/app_state.dart';
import 'package:agrilumina/l10n/app_localizations.dart';
import 'package:agrilumina/main.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/screens/app_shell.dart';
import 'package:agrilumina/screens/discover_screen.dart';
import 'package:agrilumina/screens/listing_detail_screen.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:agrilumina/utils/geo.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

import 'fake_contact_launcher.dart';
import 'fake_location_service.dart';

void main() {
  testWidgets('Home shows shared credits without looking-for control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('AgriLumina'), findsWidgets);
    expect(find.text('5 credits'), findsWidgets);
    expect(find.text('Looking for…'), findsNothing);
    expect(find.text('5 nearby buyers'), findsOneWidget);
  });

  testWidgets('Discover lists buyers and unlock spends a credit', (tester) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.text('Find Buyers'), findsOneWidget);
    expect(find.text('Looking for…'), findsOneWidget);
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

    expect(find.text('Find Buyers'), findsOneWidget);
    expect(find.text('4 credits'), findsWidgets);
  });

  testWidgets('App bar brand icon switches shell tab to Home', (tester) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Find Buyers'), findsOneWidget);
    expect(find.text('Looking for…'), findsOneWidget);

    await tester.tap(find.byKey(BrandHomeLeading.buttonKey));
    await tester.pumpAndSettle();

    expect(find.text('5 nearby buyers'), findsOneWidget);
    expect(find.text('Looking for…'), findsNothing);
    expect(find.text('Find Buyers'), findsNothing);
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

    expect(find.text('5 nearby buyers'), findsOneWidget);
    expect(find.text('Looking for…'), findsNothing);
    expect(find.text('Find Buyers'), findsNothing);
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

  testWidgets('Looking-for change clears chip and applies buying interests', (
    tester,
  ) async {
    final state = AppState(locationService: FakeLocationService());
    state.toggleBuyingInterest('Beans');

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Cassava'));
    await tester.pumpAndSettle();
    expect(find.text('Amina K.'), findsOneWidget);

    expect(find.byKey(const Key('discover_looking_for')), findsOneWidget);
    await tester.tap(find.text('Sellers'));
    await tester.pumpAndSettle();
    expect(state.activeRole, UserRole.buyer);

    expect(find.text('Showing crops you buy'), findsOneWidget);
    expect(find.text('Find Sellers'), findsOneWidget);
    // Soft-filter to Beans sellers; Cassava chip override was cleared.
    expect(find.text('Esther W.'), findsOneWidget);
    expect(find.text('Marie L.'), findsNothing);
    expect(find.text('Joseph Farm'), findsNothing);
  });

  testWidgets('Profile enables dual roles; looking-for lives on Discover', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('I can…'), findsOneWidget);
    expect(find.text('Looking for…'), findsNothing);
    expect(find.byKey(const Key('profile_role_seller')), findsOneWidget);
    expect(find.byKey(const Key('profile_role_buyer')), findsOneWidget);
    expect(find.text('Public tagline'), findsOneWidget);

    // Disable buyer capability → Discover looking-for hides; active follows seller.
    await tester.tap(find.byKey(const Key('profile_role_buyer')));
    await tester.pumpAndSettle();
    expect(find.text('rolesRequired'), findsNothing);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Looking for…'), findsNothing);
    expect(find.text('Find Buyers'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    // Re-enable buyer.
    await tester.tap(find.byKey(const Key('profile_role_buyer')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Looking for…'), findsOneWidget);
  });

  testWidgets('Unlocked contact Call and WhatsApp use launcher', (tester) async {
    final launcher = FakeContactLauncher();
    final state = AppState(locationService: FakeLocationService());
    expect((await state.unlockListingContact('b1')).ok, isTrue);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sellers'));
    await tester.pumpAndSettle();

    // Empty buyingInterests → all counterpart sellers (no soft crop filter).
    expect(find.text('Find Sellers'), findsOneWidget);
    expect(find.text('Marie L.'), findsOneWidget);
    expect(
      find.text('Samuel Growers', skipOffstage: false),
      findsOneWidget,
    );
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

  testWidgets('Discover cards show listing taglines', (tester) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.text('Fair prices for village maize'), findsOneWidget);
    expect(find.text('Jean-Pierre M.'), findsOneWidget);

    await tester.tap(find.text('Jean-Pierre M.'));
    await tester.pumpAndSettle();
    expect(find.text('Fair prices for village maize'), findsOneWidget);
  });

  testWidgets('Looking-for switcher hides when only one role enabled', (
    tester,
  ) async {
    final state = AppState(
      enabledRoles: {UserRole.seller},
      activeRole: UserRole.seller,
      locationService: FakeLocationService(),
    );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DiscoverScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Looking for…'), findsNothing);
    expect(find.byKey(const Key('discover_looking_for')), findsNothing);
    expect(find.text('I am a…'), findsNothing);
    expect(find.text('Find Buyers'), findsOneWidget);
  });
}

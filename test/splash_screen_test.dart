import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/main.dart';
import 'package:agrilumina/screens/splash_screen.dart';
import 'package:agrilumina/widgets/brand_mark.dart';

import 'fake_location_service.dart';

void main() {
  testWidgets('Splash shows AgriLumina logo then lands on Home', (tester) async {
    await tester.pumpWidget(
      MyApp(
        locationService: FakeLocationService(),
        showSplash: true,
      ),
    );

    // First frame: branded splash (native splash already removed in tests).
    await tester.pump();
    expect(find.byKey(SplashScreen.logoKey), findsOneWidget);
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.text('5 nearby buyers'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.byKey(SplashScreen.logoKey), findsNothing);
    expect(find.text('5 nearby buyers'), findsOneWidget);
    expect(find.bySemanticsLabel('AgriLumina'), findsWidgets);
  });

  testWidgets('Skipping splash opens Home immediately', (tester) async {
    await tester.pumpWidget(
      MyApp(locationService: FakeLocationService()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SplashScreen.logoKey), findsNothing);
    expect(find.text('5 nearby buyers'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:volex_terminal/main.dart' as app;
import 'package:volex_terminal/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Core App Flow Integration Test', (WidgetTester tester) async {
    // 1. App Launch
    await app.main();
    await tester.pumpAndSettle();

    // 2. Verify we are on the expected screen (Login or Terminal)
    // Since this is a fresh launch, likely Onboarding or Login.
    // For now, checking if the App widget is present.
    expect(find.byType(VolexTerminalApp), findsOneWidget);

    // Additional steps would go here:
    // - Tap Login
    // - Enter credentials
    // - Verify Home
  });
}

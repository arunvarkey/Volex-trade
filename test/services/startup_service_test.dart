import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/core/auth_guard.dart';
import 'package:volex_terminal/services/startup_service.dart';

/// The risk disclosure screen existed in the codebase for a long time with
/// nothing routing to it, so a user could reach the trading simulator without
/// ever seeing it. These tests pin the gate in place.
///
/// Firebase is not configured in the test environment, so `Firebase.apps` is
/// empty and the service treats the session as a guest — the sign-up step is
/// skipped, exactly as it is on a build without google-services.json.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = StartupService();

  test('fresh install goes to onboarding first', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await service.determineStartupRoute(),
        StartupDestination.onboarding);
  });

  test('after onboarding, the risk disclosure comes before anything else',
      () async {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      'has_selected_mode': true,
    });
    expect(await service.determineStartupRoute(),
        StartupDestination.riskDisclosure);
  });

  test('accepting the disclosure lets the user continue to mode selection',
      () async {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      StartupService.keyRiskDisclosureAccepted: true,
    });
    expect(await service.determineStartupRoute(),
        StartupDestination.modeSelection);
  });

  test('fully set up user goes straight home', () async {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      StartupService.keyRiskDisclosureAccepted: true,
      'has_selected_mode': true,
    });
    expect(await service.determineStartupRoute(), StartupDestination.home);
  });

  test('an existing user who never saw the disclosure is sent back to it',
      () async {
    // The upgrade case: someone already through onboarding and mode selection
    // on an older build. They must still acknowledge before trading.
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      'has_selected_mode': true,
      StartupService.keyRiskDisclosureAccepted: false,
    });
    expect(await service.determineStartupRoute(),
        StartupDestination.riskDisclosure);
  });

  test('the accepted-disclosure pref key matches what the screen writes', () {
    expect(StartupService.keyRiskDisclosureAccepted,
        'accepted_risk_disclosure');
  });

  test('the disclosure route is public so the auth guard cannot bounce it', () {
    expect(AuthGuard.publicRoutes, contains('/risk-disclosure'));
  });
}

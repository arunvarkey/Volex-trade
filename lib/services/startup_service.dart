import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:volex_terminal/core/app_logger.dart';

enum StartupDestination {
  onboarding, // New user, show slides
  signup, // Saw onboarding, needs account
  modeSelection, // Has account, needs to choose mode
  home, // All setup, go to app
}

class StartupService {
  static const _keyOnboardingComplete = 'has_completed_onboarding';
  static const _keyModeSelected = 'has_selected_mode';
  static const _keySignalViewCount = 'signal_view_count';
  static const _keyHasShownUpgradePrompt = 'has_shown_upgrade_prompt';

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Determine where user should start
  Future<StartupDestination> determineStartupRoute() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user is signed in
    final user = _auth.currentUser;
    final isAuthenticated = user != null;

    // Check if user completed onboarding
    final hasCompletedOnboarding =
        prefs.getBool(_keyOnboardingComplete) ?? false;

    // Check if user selected mode
    final hasSelectedMode = prefs.getBool(_keyModeSelected) ?? false;

    AppLogger.info('🚀 Startup Check:');
    AppLogger.info('  - Authenticated: $isAuthenticated');
    AppLogger.info('  - Onboarding: $hasCompletedOnboarding');
    AppLogger.info('  - Mode Selected: $hasSelectedMode');

    // Decision tree
    if (!hasCompletedOnboarding) {
      return StartupDestination.onboarding;
    }

    if (!isAuthenticated) {
      return StartupDestination.signup;
    }

    if (!hasSelectedMode) {
      return StartupDestination.modeSelection;
    }

    return StartupDestination.home;
  }

  /// Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
    AppLogger.info('✅ Onboarding marked complete');
  }

  /// Mark mode selection as complete
  Future<void> markModeSelected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyModeSelected, true);
    AppLogger.info('✅ Mode marked selected');
  }

  /// Track signal view (for upgrade prompt)
  Future<void> trackSignalView() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keySignalViewCount) ?? 0;
    await prefs.setInt(_keySignalViewCount, count + 1);
    AppLogger.info('📊 Signal view count: ${count + 1}');
  }

  /// Check if should show upgrade prompt
  Future<bool> shouldShowUpgradePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keySignalViewCount) ?? 0;
    final hasShown = prefs.getBool(_keyHasShownUpgradePrompt) ?? false;

    // Show after 5 signals, but only once
    return count >= 5 && !hasShown;
  }

  /// Mark upgrade prompt as shown
  Future<void> markUpgradePromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasShownUpgradePrompt, true);
    AppLogger.info('✅ Upgrade prompt shown');
  }

  /// Get signal view count
  Future<int> getSignalViewCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySignalViewCount) ?? 0;
  }

  /// Reset everything (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
    AppLogger.info('🔄 Reset complete - app will restart as fresh install');
  }
}

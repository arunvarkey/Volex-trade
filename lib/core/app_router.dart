import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/core/auth_guard.dart';
import 'package:volex_terminal/ui/screens/home/home_screen_v2.dart';
import 'package:volex_terminal/ui/screens/auth/login_screen.dart';
import 'package:volex_terminal/ui/screens/auth/signup_screen.dart';
import 'package:volex_terminal/ui/screens/splash/splash_screen.dart';
import 'package:volex_terminal/ui/navigation/main_navigator.dart';
import 'package:volex_terminal/ui/screens/auth/email_verification_screen.dart';
import 'package:volex_terminal/ui/screens/onboarding/onboarding_screen.dart';
import 'package:volex_terminal/ui/screens/onboarding/mode_selection_screen.dart';
import 'package:volex_terminal/ui/screens/chart/chart_screen_v2.dart';
import 'package:volex_terminal/features/signals/ui/signal_feed_screen.dart';
import 'package:volex_terminal/ui/screens/portfolio/portfolio_screen.dart';
import 'package:volex_terminal/ui/screens/activity_screen.dart';
import 'package:volex_terminal/ui/screens/more_screen.dart';
import 'package:volex_terminal/ui/screens/auth/pin_entry_screen.dart';
import 'package:volex_terminal/ui/screens/auth/biometric_screen.dart';
import 'package:volex_terminal/ui/screens/subscriptions/subscription_screen.dart';

// Real Screen Imports
import 'package:volex_terminal/ui/screens/strategies/optimizer_screen.dart';
import 'package:volex_terminal/ui/screens/strategies/scanner_screen.dart'; // MarketScannerScreen
import 'package:volex_terminal/ui/screens/strategies/ai_strategy_generator_screen.dart';
import 'package:volex_terminal/ui/screens/lab/lab_screen.dart';
import 'package:volex_terminal/ui/screens/marketplace/marketplace_screen.dart';
import 'package:volex_terminal/ui/screens/marketplace/leaderboard_screen.dart';
import 'package:volex_terminal/ui/screens/script_editor_screen.dart';
import 'package:volex_terminal/ui/screens/settings/settings_screen.dart';
import 'package:volex_terminal/ui/screens/settings/risk_settings_screen.dart';
import 'package:volex_terminal/ui/screens/settings/security_settings_screen.dart';
import 'package:volex_terminal/ui/screens/settings/api_key_setup_screen.dart';
import 'package:volex_terminal/ui/screens/profile/profile_screen.dart';

import 'package:volex_terminal/ui/screens/notifications/notifications_screen.dart';
import 'package:volex_terminal/features/simulator/backtest/screens/backtest_config_screen.dart';
import 'package:volex_terminal/features/simulator/backtest/screens/backtest_results_screen.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';
import 'package:volex_terminal/features/academy/ui/academy_screen.dart';
import 'package:volex_terminal/features/academy/ui/lesson_screen.dart';
import 'package:volex_terminal/features/academy/ui/quiz_screen.dart';
import 'package:volex_terminal/features/academy/models/academy_models.dart';
import 'package:volex_terminal/features/predictions/ui/predictions_screen.dart';
import 'package:volex_terminal/features/predictions/ui/event_market_detail_screen.dart';
import 'package:volex_terminal/features/predictions/models/prediction_models.dart';
import 'package:volex_terminal/features/daily/ui/daily_screen.dart';

// Debug

// Placeholders (Fallback)
// import 'package:volex_terminal/ui/screens/placeholders.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  redirect: AuthGuard.handleRedirect,
  routes: [
    // Splash
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/mode-selection',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: '/pin-entry',
      builder: (context, state) =>
          const PinEntryScreen(mode: PinEntryMode.verify),
    ),
    GoRoute(
      path: '/biometric',
      builder: (context, state) => const BiometricScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const SubscriptionScreen(),
    ),

    // Main App Shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainNavigator(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const HomeScreenV2(),
        ),
        GoRoute(
            path: '/chart',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) {
              final symbol = state.uri.queryParameters['symbol'];
              return ChartScreenV2(symbol: symbol);
            }),
        GoRoute(
          path: '/portfolio',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const PortfolioScreen(),
        ),
        GoRoute(
          path: '/more',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const MoreScreen(),
        ),
        GoRoute(
          path: '/signals',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const SignalFeedScreen(),
        ),
        // Buzz & Predictions (Kalshi-style event markets, simulated) —
        // a first-class tab inside the shell.
        GoRoute(
          path: '/predictions',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const PredictionsScreen(),
        ),
      ],
    ),

    // Features (Pushed on top of shell)
    GoRoute(
      path: '/activity',
      builder: (context, state) => const ActivityScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/ai-strategy',
      builder: (context, state) => const AIStrategyGeneratorScreen(),
    ),

    // Volex Daily (daily challenge ritual)
    GoRoute(
      path: '/daily',
      builder: (context, state) => const DailyScreen(),
    ),

    // Trading Academy (guided learning)
    GoRoute(
      path: '/learn',
      builder: (context, state) => const AcademyScreen(),
      routes: [
        GoRoute(
          path: 'lesson',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! Lesson) return const AcademyScreen();
            return LessonScreen(lesson: extra);
          },
        ),
        GoRoute(
          path: 'quiz',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! Lesson) return const AcademyScreen();
            return QuizScreen(lesson: extra);
          },
        ),
      ],
    ),

    // Buzz & Predictions market detail (pushed above the shell)
    GoRoute(
      path: '/predictions/market',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! EventMarket) return const PredictionsScreen();
        return EventMarketDetailScreen(market: extra);
      },
    ),
    GoRoute(
      path: '/lab',
      builder: (context, state) => const LabScreen(),
      routes: [
        GoRoute(
          path: 'backtest/config',
          builder: (context, state) {
            // Can pass a strategy to pre-fill, or null to select one
            final strategy = state.extra as GeneratedStrategy?;
            return BacktestConfigScreen(strategy: strategy);
          },
        ),
        GoRoute(
            path: 'backtest/results',
            builder: (context, state) {
              final result = state.extra as BacktestResult;
              return BacktestResultsScreen(result: result);
            }),
      ],
    ),
    GoRoute(
      path: '/optimizer',
      builder: (context, state) => const OptimizerScreen(),
    ),
    GoRoute(
      path: '/script-editor',
      builder: (context, state) => const ScriptEditorScreen(),
    ),
    GoRoute(
      path: '/market-scanner',
      builder: (context, state) => const MarketScannerScreen(),
    ),
    GoRoute(
      path: '/marketplace',
      builder: (context, state) => const MarketplaceScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),

    // Settings & Profile
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/risk-settings',
      builder: (context, state) => const RiskSettingsScreen(),
    ),
    GoRoute(
      path: '/security-settings',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: '/api-key-setup',
      builder: (context, state) => const ApiKeySetupScreen(),
    ),
  ],
);

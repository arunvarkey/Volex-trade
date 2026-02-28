import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'service_locator.dart'; // Access to getIt

// Imports for the provided services
import 'services/auth/auth_service.dart';
import '../features/subscriptions/services/subscription_service.dart';
import '../services/profile_service.dart';
import '../engine/execution_manager.dart';
import '../engine/strategy/strategy_engine.dart';
import '../providers/execution_mode_provider.dart';
import '../ui/design_system/theme_service.dart';
import '../engine/risk_manager.dart';
import 'services/auth/security_service.dart';
import '../ui/providers/dashboard_provider.dart';
import '../engine/scanner/scanner_engine.dart';
import '../engine/terminal_settings_provider.dart';
import '../features/simulator/ai_strategy/providers/strategy_provider.dart';

/// Returns the list of providers for the application root
List<SingleChildWidget> getApplicationProviders() {
  return [
    Provider<AuthService>.value(
      value: getIt<AuthService>(),
    ),
    if (getIt.isRegistered<SubscriptionService>())
      ChangeNotifierProvider<SubscriptionService>.value(
        value: getIt<SubscriptionService>(),
      ),
    ChangeNotifierProvider<SecurityService>.value(
      value: getIt<SecurityService>(),
    ),
    ChangeNotifierProvider<ProfileService>.value(
      value: getIt<ProfileService>(),
    ),
    ChangeNotifierProvider<ExecutionManager>.value(
      value: getIt<ExecutionManager>(),
    ),
    ChangeNotifierProvider<StrategyEngine>.value(
      value: getIt<StrategyEngine>(),
    ),
    ChangeNotifierProvider<ExecutionModeProvider>.value(
      value: getIt<ExecutionModeProvider>(),
    ),
    ChangeNotifierProvider<ThemeService>.value(
      value: getIt<ThemeService>(),
    ),
    ChangeNotifierProvider<ScannerEngine>.value(
      value: getIt<ScannerEngine>(),
    ),
    ChangeNotifierProvider<TerminalSettingsProvider>.value(
      value: getIt<TerminalSettingsProvider>(),
    ),
    Provider<RiskManager>.value(
      value: getIt<RiskManager>(),
    ),
    // DashboardProvider is app-wide and depends on StratEngine (which is also here)
    // DashboardProvider instantiated directly (ViewModel pattern)
    ChangeNotifierProvider<DashboardProvider>(
      create: (_) => DashboardProvider(),
    ),
    ChangeNotifierProvider<StrategyProvider>(
      create: (_) => StrategyProvider(),
    ),
  ];
}

import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports aligned with actual project structure
import 'package:volex_terminal/core/services/auth/auth_service.dart';
import 'package:volex_terminal/core/services/auth/security_service.dart';
import 'package:volex_terminal/services/analytics_service.dart';
// import 'package:volex_terminal/services/subscription_service.dart'; // Removed to avoid conflict
import 'package:volex_terminal/services/profile_service.dart';
import 'package:volex_terminal/core/security/secure_storage_service.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';
import 'package:volex_terminal/features/trading/services/secure_trading_service.dart';
import 'package:volex_terminal/data/market_data_repository.dart';
import 'package:volex_terminal/data/i_market_data_repository.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/ui/design_system/theme_service.dart';
import 'package:volex_terminal/engine/risk_manager.dart';
import 'package:volex_terminal/engine/persistence/persistence_service.dart';
import 'package:volex_terminal/core/config/app_mode_service.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/services/strategy_repository.dart';
import 'package:volex_terminal/engine/notifications/notification_bus.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/engine/strategy/strategy_runner.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'package:volex_terminal/providers/execution_mode_provider.dart';
// import 'package:volex_terminal/services/secure_auth_service.dart'; // REMOVED
import 'package:volex_terminal/engine/terminal_settings_provider.dart';
import 'package:volex_terminal/features/simulator/backtest/backtest_engine.dart';
import 'package:volex_terminal/core/app_logger.dart';
// import 'package:volex_terminal/core/app_config.dart';

// Exchange Services
import 'package:volex_terminal/engine/exchange/exchange_service.dart';
import 'package:volex_terminal/data/binance/binance_api_service.dart';
import 'package:volex_terminal/data/binance/binance_exchange_service.dart';
import 'package:volex_terminal/engine/exchange/paper_exchange_client.dart';
import 'package:volex_terminal/engine/sandbox/python_sandbox_service.dart';
import 'package:volex_terminal/services/alert_service.dart';
import 'package:volex_terminal/services/crash_reporting_service.dart';
import 'package:volex_terminal/services/feature_flag_service.dart';
import 'package:volex_terminal/services/data_privacy_service.dart';
import 'package:volex_terminal/engine/marketplace/marketplace_service.dart';
import 'package:volex_terminal/features/ai_guardian/services/ai_guardian_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:volex_terminal/engine/scanner/scanner_engine.dart';
import 'package:volex_terminal/data/historical_repository.dart';
import 'package:volex_terminal/services/user_mode_service.dart';
import 'package:volex_terminal/features/signals/services/signal_engine.dart';

final getIt = GetIt.instance;

class InitializationResult {
  final bool success;
  final String? errorMessage;
  final Duration initTime;

  InitializationResult({
    required this.success,
    this.errorMessage,
    this.initTime = Duration.zero,
  });
}

class ServiceLocator {
  static bool _initialized = false;
  static final List<String> initLog = [];

  /// Setup all core services
  static Future<InitializationResult> setupServices({
    Function(String message, double progress)? onProgress,
  }) async {
    if (_initialized) {
      return InitializationResult(success: true);
    }

    final stopwatch = Stopwatch()..start();

    try {
      _log('Boot sequence initiated.');

      _log('MONITOR: SKIP (Isolation).');
      onProgress?.call('Initializing crash reporter...', 0.02);
      final crashReporter = CrashReportingService();
      await crashReporter.initialize();
      getIt.registerSingleton<CrashReportingService>(crashReporter);
      _log('MONITOR: OK.');

      onProgress?.call('Initializing feature flags...', 0.03);
      final featureFlags = FeatureFlagService();
      await featureFlags.initialize();
      getIt.registerSingleton<FeatureFlagService>(featureFlags);
      _log('FLAGS: OK.');

      // DataPrivacy moved to ensure SecureAuthService is ready

      onProgress?.call('Initializing shared preferences...', 0.05);
      _log('SHPREFS: Loading...');
      final prefs = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(prefs);
      _log('SHPREFS: OK.');

      // App mode (paper/testnet/live) — read by the Strategy Studio hub.
      getIt.registerSingleton<AppModeService>(AppModeService(prefs));
      _log('APP_MODE: OK.');

      onProgress?.call('Initializing secure storage...', 0.1);
      _log('SECURE: Vault check...');
      final secureStorage = SecureStorageService();
      await secureStorage.initialize();
      getIt.registerSingleton<SecureStorageService>(secureStorage);
      _log('SECURE: OK.');

      onProgress?.call('Initializing subscription service...', 0.12);
      final subscriptionService = SubscriptionService();
      await subscriptionService.initialize();
      getIt.registerSingleton<SubscriptionService>(subscriptionService);
      _log('SUBSCRIPTION: OK.');

      onProgress?.call('Initializing secure trading...', 0.14);
      getIt.registerLazySingleton(() => SecureTradingService());
      _log('SECURE_TRADING: OK.');

      onProgress?.call('Initializing persistence...', 0.15);
      _log('HIVE: DB setup...');
      final persistence = PersistenceService.inject(prefs: prefs);
      await persistence.initialize();
      getIt.registerSingleton<PersistenceService>(persistence);
      _log('HIVE: OK.');

      // Strategy Studio persistence (Hive box 'strategies'). Guarded so a box
      // failure can't abort boot — the studio simply has no saved strategies.
      final strategyRepository = StrategyRepository();
      try {
        await strategyRepository.initialize();
      } catch (e) {
        _log('STRATEGY_REPO: init failed ($e) — continuing.');
      }
      getIt.registerSingleton<StrategyRepository>(strategyRepository);
      _log('STRATEGY_REPO: OK.');

      onProgress?.call('Initializing terminal settings...', 0.16);
      final terminalSettings = TerminalSettingsProvider.inject(persistence);
      getIt.registerSingleton<TerminalSettingsProvider>(terminalSettings);
      _log('SETTINGS: OK.');

      onProgress?.call('Initializing notification bus...', 0.18);
      _log('BUS: Event layer...');
      final notificationBus = NotificationBus.inject(persistence);
      getIt.registerSingleton<NotificationBus>(notificationBus);
      _log('BUS: OK.');

      onProgress?.call('Initializing authentication...', 0.2);
      _log('AUTH: Layer up...');
      final authService = AuthService();
      // await authService.initialize(); // AuthService (Firebase) might not need async init
      getIt.registerSingleton<AuthService>(authService);
      _log('AUTH: OK.');

      onProgress?.call('Initializing security...', 0.22);
      _log('SECURE: Check...');
      final securityService = SecurityService();
      await securityService.initialize();
      getIt.registerSingleton<SecurityService>(securityService);
      _log('SECURE: OK.');

      onProgress?.call('Initializing data privacy...', 0.23);
      final dataPrivacy = DataPrivacyService(); // Now safe
      getIt.registerSingleton<DataPrivacyService>(dataPrivacy);
      _log('DATAPRIVACY: OK.');

      onProgress?.call('Initializing risk manager...', 0.25);
      _log('RISK: Circuit check...');
      final riskManager = RiskManager.inject(persistence: persistence);
      await riskManager.initialize();
      getIt.registerSingleton<RiskManager>(riskManager);
      _log('RISK: OK.');

      onProgress?.call('Initializing market data...', 0.3);
      _log('DATA: Socket check...');
      final marketData = MarketDataRepository.inject();
      await marketData.initialize();
      getIt.registerSingleton<MarketDataRepository>(marketData);
      getIt.registerSingleton<IMarketDataRepository>(
          marketData); // Interface registration

      // Backtest Engine
      getIt.registerLazySingleton<BacktestEngine>(
          () => BacktestEngine(marketData));

      _log('DATA & BACKTEST: OK.');

      onProgress?.call('Initializing chart controller...', 0.4);
      final chartController = ChartController();
      getIt.registerSingleton<ChartController>(chartController);

      // --- USER MODE INIT ---
      onProgress?.call('Initializing user mode...', 0.05);
      getIt.registerLazySingleton(() => UserModeService());
      final userModeService = getIt<UserModeService>();
      final userMode = await userModeService.getCurrentMode();
      _log('MODE: ${userMode.toString()}');

      // --- EXCHANGE INIT ---
      // CRITICAL: For V1 Release, we force Paper Trading for all users.
      // Live Binance API service is disabled for safety during initial launch.
      _log('SAFETY: Forcing Paper Exchange for V1 release.');
      onProgress?.call('Initializing paper exchange...', 0.45);
      ExchangeService exchangeService = PaperExchangeClient();

      /* 
      // Live Trading Logic (Disabled for V1)
      if (userMode == UserMode.pro && SecureConfig.enableLiveTrading) {
        onProgress?.call('Initializing exchange (PRO)...', 0.45);
        final apiKey = await secureStorage.getApiKey();
        final apiSecret = await secureStorage.getApiSecret();

        if (apiKey != null &&
            apiKey.isNotEmpty &&
            apiSecret != null &&
            apiSecret.isNotEmpty) {
          _log('EXEC: Keys found. Using LIVE Binance connection.');
          exchangeService =
              BinanceApiService(apiKey: apiKey, apiSecret: apiSecret);
        } else {
          _log('EXEC: No keys. Using Paper Exchange.');
          exchangeService = PaperExchangeClient();
        }
      } else {
        if (userMode == UserMode.pro && !SecureConfig.enableLiveTrading) {
          _log(
              'SAFETY: Live Trading disabled in Config. Using Paper Exchange.');
        }
        onProgress?.call('Skipping exchange (EXPLORER)...', 0.45);
        _log('EXEC: Explorer Mode. Using Paper Exchange for signals.');
        exchangeService = PaperExchangeClient();
      }
      */

      onProgress?.call('Initializing execution manager...', 0.5);
      _log('EXEC: Manager ready...');
      final executionManager = ExecutionManager.provide(
        marketData: marketData,
        riskManager: riskManager,
        persistence: persistence,
        exchange: exchangeService,
      );
      getIt.registerSingleton<ExecutionManager>(executionManager);
      _log('EXEC: OK.');

      onProgress?.call('Initializing alert service...', 0.55);
      _log('ALERTS: Loading...');
      final alertService = AlertService();
      getIt.registerSingleton<AlertService>(alertService);
      _log('ALERTS: OK.');

      onProgress?.call('Initializing strategy engine...', 0.65);
      _log('STRAT: Logic up...');
      final strategyEngine = StrategyEngine(
        executionManager: executionManager,
        chartController: chartController,
        riskManager: riskManager,
      );
      await strategyEngine.initialize();
      getIt.registerSingleton<StrategyEngine>(strategyEngine);
      _log('STRAT: OK.');

      final executionMode = ExecutionModeProvider(executionManager);
      getIt.registerSingleton<ExecutionModeProvider>(executionMode);

      onProgress?.call('Initializing analytics...', 0.7);
      _log('TELEMETRY: Start...');
      final analytics = AnalyticsService.instance;
      try {
        await analytics.initialize();
        _log('TELEMETRY: OK.');
      } catch (e) {
        _log('TELEMETRY: FAILED (Non-fatal) - $e');
      }
      getIt.registerSingleton<AnalyticsService>(analytics);

      // SubscriptionService moved to top of initialization to ensure availability
      // onProgress?.call('Initializing subscriptions...', 0.8);
      // _log('IAP: Billing engine...');
      // final subscription = getIt<SubscriptionService>();
      // _log('IAP: Ready.');

      onProgress?.call('Initializing profile...', 0.85);
      _log('PROFILE: Cache load...');
      final profile = ProfileService();
      getIt.registerSingleton<ProfileService>(profile);
      _log('PROFILE: OK.');

      onProgress?.call('Initializing marketplace...', 0.88);
      _log('MARKET: Opening doors...');
      final marketplace = MarketplaceService();
      getIt.registerSingleton<MarketplaceService>(marketplace);
      _log('MARKET: OK.');

      // Register AI Guardian
      onProgress?.call('Setting up AI Guardian...', 0.885);
      String userId = 'anonymous';
      try {
        userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      } catch (_) {
        // Firebase may be unavailable (e.g. web preview); default to anonymous.
      }
      getIt.registerLazySingleton(() => AIGuardianService(userId));
      _log('GUARDIAN: OK.');

      // A CopyTradingEngine was constructed and started here on every launch.
      // Its only signal source was MarketplaceService's simulation timer,
      // which invented prices, so starting it meant standing ready to place
      // paper orders from fabricated fills. Both are removed.

      onProgress?.call('Initializing theme...', 0.9);
      _log('THEME: UI refresh...');
      final theme = ThemeService(prefs);
      getIt.registerSingleton<ThemeService>(theme);
      _log('THEME: OK.');

      // --- SCANNER INIT ---
      _log('SCANNER: Core init...');
      // Real market data via Binance's PUBLIC klines endpoint (no API key or
      // secret needed — read-only). HistoricalRepository transparently falls
      // back to synthetic candles if the network/region blocks the request, so
      // the simulator is never empty.
      final publicMarketData = BinanceExchangeService(
        BinanceApiService(apiKey: '', apiSecret: ''),
      );
      final historicalRepo =
          HistoricalRepository(exchange: publicMarketData);
      getIt.registerSingleton<HistoricalRepository>(historicalRepo);

      final scannerEngine = ScannerEngine(historicalRepo);
      getIt.registerSingleton<ScannerEngine>(scannerEngine);
      _log('SCANNER: OK.');

      // --- STRATEGY RUNNER (live paper-trading loop) ---
      // Turns activated strategies into real paper trades. Listens to the
      // ExecutionManager and runs only while strategies are active.
      final strategyRunner = StrategyRunner(
        getIt<ExecutionManager>(),
        strategyEngine,
        historicalRepo,
      );
      getIt.registerSingleton<StrategyRunner>(strategyRunner);
      _log('RUNNER: OK.');

      _log('ALGO: Hyper-Thread init...');
      getIt.registerLazySingleton(() => PythonSandboxService());
      _log('ALGO: OK.');

      // --- SIGNAL ENGINE (V2) ---
      onProgress?.call('Initializing signal engine...', 0.95);
      _log('SIGNALS: Booting AI...');
      final signalEngine = SignalEngine(
        strategyEngine: strategyEngine,
        aiGuardian: getIt<AIGuardianService>(),
        marketData: getIt<IMarketDataRepository>(),
      );
      getIt.registerSingleton<SignalEngine>(signalEngine);

      // FIRE AND FORGET: Don't block startup on signal generation
      unawaited(signalEngine.startGenerating().catchError((e) {
        AppLogger.error('Failed to start signal engine in background', e);
      }));
      _log('SIGNALS: OK.');

      onProgress?.call('Complete!', 1.0);
      _log('BOOT: SUCCESS.');

      _initialized = true;
      stopwatch.stop();
      return InitializationResult(
        success: true,
        initTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _log('BOOT: FAILED - $e');
      AppLogger.error(
          'ServiceLocator initialization failed: $e', e, stackTrace);
      return InitializationResult(
        success: false,
        errorMessage: e.toString(),
        initTime: stopwatch.elapsed,
      );
    }
  }

  static void _log(String msg) {
    final timestamp =
        DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    initLog.add('[$timestamp] $msg');
  }

  /// Cleanup on app termination
  static void cleanup() {
    if (!_initialized) return;

    try {
      // Sentry cleans itself up, but we can log specific shutdown if needed
      // getIt<CrashReportingService>().dispose();
      getIt<IMarketDataRepository>().dispose();
      if (getIt.isRegistered<StrategyRunner>()) {
        getIt<StrategyRunner>().dispose();
      }
      getIt<ExecutionManager>().dispose();
      getIt<RiskManager>().dispose();
      getIt<NotificationBus>().dispose();
      getIt<StrategyEngine>().dispose();
      getIt<ChartController>().dispose();
    } catch (e) {
      AppLogger.error('Cleanup error: $e');
    }
  }
}

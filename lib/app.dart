import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:volex_terminal/l10n/app_localizations.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/core/app_router.dart';
import 'package:volex_terminal/services/analytics_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/theme_service.dart';
import 'package:volex_terminal/ui/components/privacy_shield.dart';
import 'package:volex_terminal/core/services/auth/security_service.dart';
import 'package:volex_terminal/ui/screens/auth/pin_entry_screen.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/data/market_data_repository.dart';
import 'package:volex_terminal/services/market_ticker_service.dart';
import 'package:volex_terminal/core/providers_setup.dart';
import 'package:volex_terminal/services/feature_flag_service.dart';
import 'package:volex_terminal/features/compliance/age_gate_screen.dart';

/// Error fallback app
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: VxColors.deepBlack,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: VxColors.neonRed,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    // SystemNavigator.pop() isn't directly available unless imported via services.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VxColors.neonCyan,
                    foregroundColor: VxColors.deepBlack,
                  ),
                  child: const Text('EXIT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main app
class VolexTerminalApp extends StatefulWidget {
  const VolexTerminalApp({super.key});

  @override
  State<VolexTerminalApp> createState() => _VolexTerminalAppState();
}

class _VolexTerminalAppState extends State<VolexTerminalApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Track app open
    AnalyticsService.instance.logEvent('app_opened');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.detached:
        _onAppTerminating();
        break;
      default:
        break;
    }
  }

  void _onAppPaused() {
    AppLogger.debug('📱 App paused');
    AnalyticsService.instance.logEvent('app_paused');
    // Backgrounding used to change nothing: the websocket stayed open, the
    // REST fallback kept polling Binance every 2 seconds and the synthetic
    // tick timer kept firing, for as long as the process lived.
    _withMarketData((repo) => repo.pauseLiveFeeds());
    MarketTickerService.instance.stop();
  }

  void _onAppResumed() {
    AppLogger.debug('📱 App resumed');
    AnalyticsService.instance.logEvent('app_resumed');
    getIt<SecurityService>().recordActivity();
    _withMarketData((repo) => repo.resumeLiveFeeds());
    // Only restarts if the tape is actually on screen — the widget calls
    // start() itself, and start() is idempotent.
    if (MarketTickerService.instance.hasData) {
      MarketTickerService.instance.start();
    }
  }

  /// The repository is registered during boot; a lifecycle callback can fire
  /// before that finishes (or in a test with no service locator), so never let
  /// a missing registration take down the app.
  void _withMarketData(void Function(MarketDataRepository) action) {
    if (!getIt.isRegistered<MarketDataRepository>()) return;
    try {
      action(getIt<MarketDataRepository>());
    } catch (e) {
      AppLogger.warning('Market data lifecycle hook failed: $e');
    }
  }

  void _onAppTerminating() {
    AppLogger.debug('📱 App terminating');
    ServiceLocator.cleanup();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: getApplicationProviders(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp.router(
            title: 'Volex Terminal',
            debugShowCheckedModeBanner: false,
            theme: themeService.buildThemeData(),
            routerConfig: appRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              // Only override ErrorWidget in non-test environments to avoid flutter_test assertion.
              // Platform.environment is unsupported on web, so guard with kIsWeb.
              if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
                ErrorWidget.builder = (errorDetails) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 64,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Something went wrong',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorDetails.exceptionAsString(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                };
              }

              return MaintenanceMonitor(
                child: PrivacyShield(
                  child: AuthActivityListener(
                    child: AgeGate(
                      child: AuthGate(child: child),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Global listener to reset auto-lock timer on interaction
class AuthActivityListener extends StatelessWidget {
  final Widget? child;
  const AuthActivityListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => getIt<SecurityService>().recordActivity(),
      onPointerMove: (_) => getIt<SecurityService>().recordActivity(),
      child: child,
    );
  }
}

/// Gate that shows PIN screen if not authenticated
class AuthGate extends StatefulWidget {
  final Widget? child;
  const AuthGate({super.key, this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SecurityService _auth = getIt<SecurityService>();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // If not authenticated, show PIN screen
    if (!_auth.isAuthenticated) {
      final mode = _auth.hasSetupPin ? PinEntryMode.verify : PinEntryMode.setup;

      // Use a local Navigator to handle the PinEntryScreen's internal pop() calls
      return Navigator(
        onDidRemovePage: (page) {
          // Standard replacement for onPopPage in declarative navigation
        },
        pages: [
          MaterialPage(
            child: PinEntryScreen(mode: mode),
          ),
        ],
      );
    }

    // Otherwise show app
    return widget.child ?? const SizedBox.shrink();
  }
}

/// Blocks access if maintenance mode is enabled via Feature Flags
class MaintenanceMonitor extends StatefulWidget {
  final Widget child;
  const MaintenanceMonitor({super.key, required this.child});

  @override
  State<MaintenanceMonitor> createState() => _MaintenanceMonitorState();
}

class _MaintenanceMonitorState extends State<MaintenanceMonitor> {
  // Simple periodic check or Stream if service supported streams (RemoteConfig is usually fetch-based)
  // For now, we check on build/startup. Real apps might use a Timer.
  bool get _isMaintenance => getIt<FeatureFlagService>().isMaintenanceMode;

  @override
  Widget build(BuildContext context) {
    if (_isMaintenance) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: VxColors.deepBlack,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_circle, size: 80, color: VxColors.neonRed),
                  SizedBox(height: 24),
                  Text(
                    'System Maintenance',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Volex Terminal is currently undergoing scheduled maintenance. Please try again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

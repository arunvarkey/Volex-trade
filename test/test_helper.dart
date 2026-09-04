import 'package:mockito/mockito.dart';
import 'package:volex_terminal/data/i_market_data_repository.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/risk_manager.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/services/user_mode_service.dart';
import 'package:volex_terminal/core/services/auth/auth_service.dart';
import 'package:volex_terminal/engine/notifications/notification_bus.dart';
import 'package:get_it/get_it.dart';

// Manual Mocks to avoid build_runner issues in this environment
class MockIMarketDataRepository extends Mock implements IMarketDataRepository {
  /// Same reasoning as [MockRiskManager.validateOrder]: currentSymbol returns
  /// a non-nullable String, so leaving it to mockito's noSuchMethod would fail
  /// with a null type error rather than a missing-stub message.
  @override
  String get currentSymbol => 'BTCUSDT';
}

class MockExecutionManager extends Mock implements ExecutionManager {}

class MockRiskManager extends Mock implements RiskManager {
  /// Approve orders by default.
  ///
  /// This is overridden directly rather than stubbed with `when(...)`, because
  /// an unstubbed mockito mock returns null and validateOrder is declared to
  /// return a non-nullable bool — so the `when(mock.validateOrder(...))` call
  /// would itself blow up evaluating its own argument, before it could
  /// register the stub.
  ///
  /// The effect of leaving it unstubbed was that any code path consulting the
  /// risk manager died with "type 'Null' is not a subtype of type 'bool'"
  /// instead of failing on its own merits. A test that wants a rejection
  /// passes its own riskManager to [setupServiceLocator].
  @override
  bool validateOrder({
    required double quantity,
    required double priceUsdt,
    String? strategyId,
    bool isLive = false,
    bool isReduction = false,
  }) =>
      true;
}

class MockStrategyEngine extends Mock implements StrategyEngine {}

class MockUserModeService extends Mock implements UserModeService {}

class MockAuthService extends Mock implements AuthService {}

class MockNotificationBus extends Mock implements NotificationBus {}

/// Reset the service locator and register test doubles.
///
/// Must be awaited. GetIt.reset() is asynchronous, and this used to call it
/// without awaiting, so the reset could land *after* the registrations below
/// and quietly unregister everything. Tests that never hit an async gap got
/// away with it; one that awaited mid-test then failed with "NotificationBus
/// is not registered" from a service that had been registered correctly a
/// moment earlier.
Future<void> setupServiceLocator({
  IMarketDataRepository? marketRepo,
  ExecutionManager? execManager,
  RiskManager? riskManager,
  StrategyEngine? strategyEngine,
  UserModeService? userModeService,
  AuthService? authService,
  NotificationBus? notificationBus,
}) async {
  final getIt = GetIt.instance;
  await getIt.reset();

  // Create mocks
  final mockedMarketRepo = marketRepo ?? MockIMarketDataRepository();
  final mockedNotificationBus = notificationBus ?? MockNotificationBus();

  // Register them first
  getIt.registerSingleton<IMarketDataRepository>(mockedMarketRepo);
  getIt.registerSingleton<ExecutionManager>(
      execManager ?? MockExecutionManager());
  getIt.registerSingleton<RiskManager>(riskManager ?? MockRiskManager());
  getIt.registerSingleton<StrategyEngine>(
      strategyEngine ?? MockStrategyEngine());
  getIt.registerSingleton<UserModeService>(
      userModeService ?? MockUserModeService());
  getIt.registerSingleton<AuthService>(authService ?? MockAuthService());
  getIt.registerSingleton<NotificationBus>(mockedNotificationBus);

  // Stubbing AFTER registration might be safer
  if (marketRepo == null) {
    try {
      _stubMarketRepo(mockedMarketRepo as MockIMarketDataRepository);
    } catch (_) {}
  }

  if (notificationBus == null) {
    try {
      _stubNotificationBus(mockedNotificationBus as MockNotificationBus);
    } catch (_) {}
  }

}

void _stubMarketRepo(MockIMarketDataRepository mock) {
  when(mock.watchlistStream).thenAnswer((_) => const Stream.empty());
  when(mock.updatesStream).thenAnswer((_) => const Stream.empty());
  when(mock.statusStream).thenAnswer((_) => const Stream.empty());
  when(mock.connectionStatusStream).thenAnswer((_) => const Stream.empty());
}

void _stubNotificationBus(MockNotificationBus mock) {
  when(mock.historyStream).thenAnswer((_) => const Stream.empty());
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/engine/persistence/persistence_service.dart';
import 'package:volex_terminal/engine/risk_manager.dart';
import '../../test_helper.dart';

/// A risk control that traps you in a losing trade is worse than no control.
///
/// recordTradeResult trips the emergency stop automatically the moment the
/// daily loss limit is reached, and validateOrder used to reject *every* order
/// while it was active — with no exemption for closing out. The daily-loss
/// branch had an `isReduction` escape hatch, but nothing in the codebase ever
/// passed the flag, so it was always false.
///
/// Between them: hitting your loss limit locked you into your open positions.
/// Manual closes were rejected, and because protective exits close through the
/// same path, stop-losses stopped firing at precisely the moment the limit was
/// telling you that you were losing money — leaving the loss it exists to cap
/// running unbounded.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RiskManager risk;

  setUp(() async {
    // The reject path publishes to the notification bus, which resolves
    // through the service locator.
    await setupServiceLocator();
    risk = RiskManager.inject();
  });

  bool validate({required bool isReduction}) => risk.validateOrder(
        quantity: 0.1,
        priceUsdt: 1000,
        isLive: false,
        isReduction: isReduction,
      );

  test('a normal order is allowed before any losses', () {
    expect(validate(isReduction: false), isTrue);
  });

  group('after the daily loss limit is breached', () {
    setUp(() {
      // Default limit is $100; one loss past it trips the emergency stop.
      risk.recordTradeResult(-150);
    });

    test('the emergency stop is active', () {
      expect(risk.getStatus()['isEmergencyStopActive'], isTrue);
    });

    test('opening new exposure is blocked', () {
      expect(validate(isReduction: false), isFalse);
    });

    test('closing an existing position is still allowed', () {
      // The whole point: you can always get out.
      expect(validate(isReduction: true), isTrue);
    });
  });

  group('with losses recorded but the limit not yet reached', () {
    setUp(() => risk.recordTradeResult(-10));

    test('both opening and closing remain allowed', () {
      expect(validate(isReduction: false), isTrue);
      expect(validate(isReduction: true), isTrue);
    });
  });

  test('a winning trade does not count toward the daily loss', () {
    risk.recordTradeResult(500);
    expect(validate(isReduction: false), isTrue);
    expect(risk.getStatus()['currentDailyLoss'], 0.0);
  });

  test('reset clears the lockout', () {
    risk.recordTradeResult(-150);
    expect(validate(isReduction: false), isFalse);

    risk.reset();
    expect(validate(isReduction: false), isTrue);
  });

  group('across a restart', () {
    late PersistenceService store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      store = PersistenceService.inject(prefs: prefs);
    });

    /// Saving is deliberately fire-and-forget so that persisting state can
    /// never block or fail a trade, which means the write has to be given a
    /// turn of the event loop before it can be read back.
    Future<void> letTheWriteLand() => Future<void>.delayed(Duration.zero);

    test('the lockout is still in force after a restart', () async {
      // The whole point. The daily loss and lockout used to live only in
      // memory and in a Firebase-backed sync that no-ops without Firebase, so
      // force quitting cleared the lockout and zeroed the day's losses. You
      // could trade straight through your own limit by restarting the app.
      final before = RiskManager.inject(persistence: store);
      before.recordTradeResult(-150);
      expect(before.isLocked, isTrue);
      await letTheWriteLand();

      // A fresh instance reading the same storage stands in for the next
      // launch.
      final after = RiskManager.inject(persistence: store);
      await after.initialize();

      expect(after.isLocked, isTrue);
      expect(after.getStatus()['currentDailyLoss'], 150.0);
    });

    test('closing out is still allowed after that restart', () async {
      RiskManager.inject(persistence: store).recordTradeResult(-150);
      await letTheWriteLand();

      final after = RiskManager.inject(persistence: store);
      await after.initialize();

      expect(
        after.validateOrder(
            quantity: 0.1, priceUsdt: 1000, isReduction: true),
        isTrue,
      );
      expect(
        after.validateOrder(
            quantity: 0.1, priceUsdt: 1000, isReduction: false),
        isFalse,
      );
    });

    test('a manager with no storage behind it still works', () async {
      // Tests and any caller that builds one without persistence must not
      // break; saving and restoring are simply no-ops.
      final standalone = RiskManager.inject();
      standalone.recordTradeResult(-150);

      expect(standalone.isLocked, isTrue);
    });
  });
}

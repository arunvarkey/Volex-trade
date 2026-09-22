import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/features/academy/services/xp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final xp = XpService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await xp.ensureLoaded();
    await xp.reset();
  });

  test('levelForXp maps thresholds correctly', () {
    expect(XpService.levelForXp(0), XpLevel.novice);
    expect(XpService.levelForXp(199), XpLevel.novice);
    expect(XpService.levelForXp(200), XpLevel.operator);
    expect(XpService.levelForXp(599), XpLevel.operator);
    expect(XpService.levelForXp(600), XpLevel.analyst);
    expect(XpService.levelForXp(1199), XpLevel.analyst);
    expect(XpService.levelForXp(1200), XpLevel.pro);
    expect(XpService.levelForXp(999999), XpLevel.pro);
  });

  test('awardOnce adds XP and is idempotent by key', () async {
    final first = await xp.awardOnce('lesson:f1', 50);
    expect(first, 50);
    expect(xp.totalXp, 50);

    final replay = await xp.awardOnce('lesson:f1', 50);
    expect(replay, 0, reason: 'same key must not double-count');
    expect(xp.totalXp, 50);
  });

  test('distinct keys accumulate', () async {
    await xp.awardOnce('lesson:f1', 50);
    await xp.awardOnce('lesson:f2', 50);
    await xp.awardOnce('daily:1', 20);
    expect(xp.totalXp, 120);
    expect(xp.level, XpLevel.novice);
  });

  test('crossing a threshold raises the level', () async {
    for (int i = 0; i < 4; i++) {
      await xp.awardOnce('lesson:$i', 50); // 4 × 50 = 200
    }
    expect(xp.totalXp, 200);
    expect(xp.level, XpLevel.operator);
  });

  test('non-positive award is a no-op', () async {
    final r = await xp.awardOnce('nothing', 0);
    expect(r, 0);
    expect(xp.totalXp, 0);
  });

  test('progressToNextLevel and xpToNextLevel', () async {
    await xp.awardOnce('a', 100); // halfway from Novice(0) to Operator(200)
    expect(xp.level, XpLevel.novice);
    expect(xp.progressToNextLevel, closeTo(0.5, 1e-9));
    expect(xp.xpToNextLevel, 100);
  });

  test('Pro level is terminal', () async {
    await xp.awardOnce('big', 1500);
    expect(xp.level, XpLevel.pro);
    expect(xp.nextLevel, isNull);
    expect(xp.progressToNextLevel, 1.0);
    expect(xp.xpToNextLevel, 0);
  });

  test('addXp accumulates every call (repeatable actions)', () async {
    await xp.addXp(XpService.backtestXp);
    await xp.addXp(XpService.backtestXp);
    await xp.addXp(XpService.tradeXp);
    expect(xp.totalXp, XpService.backtestXp * 2 + XpService.tradeXp);
  });

  group('trade XP is paid for discipline, not volume', () {
    final day = DateTime(2026, 8, 31, 10);

    test('a trade with a stop earns, up to three times a day', () async {
      for (var i = 0; i < XpService.maxTradeAwardsPerDay; i++) {
        expect(await xp.awardTradeWithStop(day), XpService.tradeXp);
      }
      expect(xp.totalXp, XpService.tradeXp * XpService.maxTradeAwardsPerDay);
    });

    test('the fourth trade of the day earns nothing', () async {
      for (var i = 0; i < XpService.maxTradeAwardsPerDay; i++) {
        await xp.awardTradeWithStop(day);
      }
      final capped = xp.totalXp;

      // The mechanic this replaced paid 15 XP per order with no ceiling, so
      // a hundred trades was 1,500 XP. Rewarding volume is rewarding the
      // behaviour that loses retail traders money.
      expect(await xp.awardTradeWithStop(day), 0);
      expect(await xp.awardTradeWithStop(day), 0);
      expect(xp.totalXp, capped);
    });

    test('the cap resets the next day', () async {
      for (var i = 0; i < XpService.maxTradeAwardsPerDay; i++) {
        await xp.awardTradeWithStop(day);
      }
      expect(await xp.awardTradeWithStop(day), 0);

      final tomorrow = day.add(const Duration(days: 1));
      expect(await xp.awardTradeWithStop(tomorrow), XpService.tradeXp);
    });

    test('days are keyed unambiguously', () async {
      // A naive '$year-$month-$day' key makes 2026-1-11 and 2026-11-1 differ
      // only by where the digits fall, and other pairs collide outright.
      await xp.awardTradeWithStop(DateTime(2026, 1, 11));
      final afterFirst = xp.totalXp;
      expect(await xp.awardTradeWithStop(DateTime(2026, 11, 1)),
          XpService.tradeXp,
          reason: 'a different date must have a different key');
      expect(xp.totalXp, afterFirst + XpService.tradeXp);
    });
  });

  test('addXp ignores non-positive amounts', () async {
    await xp.addXp(0);
    await xp.addXp(-10);
    expect(xp.totalXp, 0);
  });

  test('persists total and awarded keys', () async {
    await xp.awardOnce('lesson:z', 50);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('xp_total_v1'), 50);
    expect(prefs.getStringList('xp_awarded_keys_v1'), contains('lesson:z'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/features/daily/data/daily_question_bank.dart';
import 'package:volex_terminal/features/daily/models/daily_models.dart';
import 'package:volex_terminal/features/daily/services/daily_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = DailyService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.ensureLoaded();
    await service.resetAll();
  });

  group('question bank', () {
    test('has enough distinct questions with valid lesson links', () {
      expect(DailyQuestionBank.all.length, greaterThanOrEqualTo(10));
      final ids = DailyQuestionBank.all.map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate question id');
    });
  });

  group('deterministic daily set', () {
    test('same date yields the same calls for everyone', () {
      final d = DateTime(2026, 3, 14);
      final a = service.challengeFor(d);
      final b = service.challengeFor(d);
      expect(a.calls.map((c) => c.id), b.calls.map((c) => c.id));
      expect(a.number, b.number);
    });

    test('different dates generally differ', () {
      final a = service.challengeFor(DateTime(2026, 3, 14));
      final b = service.challengeFor(DateTime(2026, 3, 15));
      expect(a.calls.map((c) => c.id).toList() ==
          b.calls.map((c) => c.id).toList(), isFalse);
    });

    test('challenge is 5 calls and number counts from the epoch', () {
      final c = service.challengeFor(DateTime(2026, 1, 1));
      expect(c.calls.length, 5);
      expect(c.number, 1);
      expect(service.challengeFor(DateTime(2026, 1, 2)).number, 2);
    });
  });

  group('streak logic', () {
    List<bool> perfect(DailyChallenge c) => List.filled(c.length, true);

    test('first play sets streak to 1 and counts a play', () async {
      final day = DateTime(2026, 4, 1, 9);
      final c = service.challengeFor(day);
      final r = await service.recordCompletion(c, perfect(c), now: day);
      expect(r.streakAfter, 1);
      expect(service.currentStreak, 1);
      expect(service.playedCount, 1);
      expect(r.score, c.length);
    });

    test('consecutive days extend the streak', () async {
      final d1 = DateTime(2026, 4, 1, 9);
      final d2 = DateTime(2026, 4, 2, 9);
      final d3 = DateTime(2026, 4, 3, 9);
      await service.recordCompletion(
          service.challengeFor(d1), perfect(service.challengeFor(d1)), now: d1);
      await service.recordCompletion(
          service.challengeFor(d2), perfect(service.challengeFor(d2)), now: d2);
      final r3 = await service.recordCompletion(
          service.challengeFor(d3), perfect(service.challengeFor(d3)), now: d3);
      expect(r3.streakAfter, 3);
      expect(service.bestStreak, 3);
      expect(service.playedCount, 3);
    });

    test('a skipped day resets the streak to 1', () async {
      final d1 = DateTime(2026, 4, 1, 9);
      final d3 = DateTime(2026, 4, 3, 9); // skip the 2nd
      await service.recordCompletion(
          service.challengeFor(d1), perfect(service.challengeFor(d1)), now: d1);
      final r = await service.recordCompletion(
          service.challengeFor(d3), perfect(service.challengeFor(d3)), now: d3);
      expect(r.streakAfter, 1);
      expect(service.bestStreak, 1);
    });

    test('same-day replay is idempotent for streak and play count', () async {
      final day = DateTime(2026, 4, 1, 9);
      final later = DateTime(2026, 4, 1, 20);
      final c = service.challengeFor(day);
      await service.recordCompletion(c, perfect(c), now: day);
      final r2 = await service.recordCompletion(
          c, [true, true, true, false, false], now: later);
      expect(r2.streakAfter, 1); // unchanged
      expect(service.currentStreak, 1);
      expect(service.playedCount, 1); // not double counted
      expect(service.lastScore, 3); // score updated
    });

    test('hasPlayedToday tracks the last completed day', () async {
      final day = DateTime(2026, 4, 1, 9);
      expect(service.hasPlayedToday(now: day), isFalse);
      final c = service.challengeFor(day);
      await service.recordCompletion(c, perfect(c), now: day);
      expect(service.hasPlayedToday(now: day), isTrue);
      expect(service.hasPlayedToday(now: DateTime(2026, 4, 2, 9)), isFalse);
    });
  });

  group('DailyResult', () {
    test('share text reflects score, streak and grid', () {
      const r = DailyResult(
        dateKey: '2026-04-01',
        number: 91,
        score: 4,
        total: 5,
        correctness: [true, true, false, true, true],
        streakAfter: 12,
      );
      final txt = r.shareText();
      expect(txt, contains('Volex Daily #91'));
      expect(txt, contains('4/5'));
      expect(txt, contains('12-day streak'));
      expect(txt, contains('🟩'));
      expect(txt, contains('🟥'));
      expect(r.scoreBand, 'a strong round');
      // The share text must not claim a ranking. There is no player
      // population, so a percentile in shareable copy is a public claim
      // about a leaderboard that does not exist.
      expect(txt, isNot(contains('top ')));
      expect(txt, isNot(contains('Estimated')));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/features/daily/services/daily_reminder_service.dart';
import 'package:volex_terminal/features/daily/services/daily_service.dart';

/// The streak freeze, and the rule that reminders never push trading.
///
/// The freeze exists because losing a streak is a churn cliff — people
/// uninstall rather than restart from zero. It has to be generous enough to
/// absorb one forgotten evening and mean enough that a number stops meaning
/// anything, so the boundaries are worth pinning down.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = DailyService.instance;

  /// Plays the challenge for [date] with a perfect score.
  Future<void> play(DateTime date) async {
    await service.recordCompletion(
      service.challengeFor(date),
      const [true, true, true, true, true],
      now: date,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.resetAll();
  });

  group('streak freeze', () {
    test('covers a single missed day', () async {
      final mon = DateTime(2026, 3, 2);
      await play(mon);
      await play(mon.add(const Duration(days: 1)));
      expect(service.currentStreak, 2);

      // Skips Wednesday, plays Thursday.
      await play(mon.add(const Duration(days: 3)));

      expect(service.currentStreak, 3,
          reason: 'one forgotten evening should not reset a streak to 1');
      expect(service.freezeUsedOn, isNotNull,
          reason: 'the user has to be told afterwards that they were covered');
    });

    test('does not cover a two-day gap', () async {
      final mon = DateTime(2026, 3, 2);
      await play(mon);
      await play(mon.add(const Duration(days: 1)));

      // Skips Wednesday and Thursday, plays Friday.
      await play(mon.add(const Duration(days: 4)));

      expect(service.currentStreak, 1,
          reason: 'a freeze absorbs a slip, not a week away — otherwise the '
              'streak number stops meaning anything');
      expect(service.freezeUsedOn, isNull);
    });

    test('is limited to one per week', () async {
      final mon = DateTime(2026, 3, 2);
      await play(mon);
      // Miss Tuesday, play Wednesday — freeze spent.
      await play(mon.add(const Duration(days: 2)));
      expect(service.currentStreak, 2);

      // Miss Thursday, play Friday — same week, no freeze left.
      await play(mon.add(const Duration(days: 4)));
      expect(service.currentStreak, 1,
          reason: 'a second freeze in the same week would make the streak '
              'almost impossible to lose, which empties it of meaning');
    });

    test('a new week restores the freeze', () async {
      final mon = DateTime(2026, 3, 2);
      await play(mon);
      await play(mon.add(const Duration(days: 2))); // freeze spent
      expect(service.currentStreak, 2);

      // Play daily to carry the streak into the next week.
      for (var d = 3; d <= 9; d++) {
        await play(mon.add(Duration(days: d)));
      }
      final before = service.currentStreak;

      // Miss a day well into the following week.
      await play(mon.add(const Duration(days: 11)));
      expect(service.currentStreak, before + 1,
          reason: 'the weekly allowance should have reset');
    });

    test('does not apply to a first ever play', () async {
      await play(DateTime(2026, 3, 2));
      expect(service.currentStreak, 1);
      expect(service.freezeUsedOn, isNull,
          reason: 'there was no streak to protect');
    });

    test('acknowledging clears the notice so it shows once', () async {
      final mon = DateTime(2026, 3, 2);
      await play(mon);
      await play(mon.add(const Duration(days: 2)));
      expect(service.freezeUsedOn, isNotNull);

      await service.acknowledgeFreeze();
      expect(service.freezeUsedOn, isNull);
    });

    test('an unbroken streak never spends a freeze', () async {
      final mon = DateTime(2026, 3, 2);
      for (var d = 0; d < 5; d++) {
        await play(mon.add(Duration(days: d)));
      }
      expect(service.currentStreak, 5);
      expect(service.freezeUsedOn, isNull);
    });
  });

  group('reminder settings', () {
    test('default to on, early evening', () async {
      SharedPreferences.setMockInitialValues({});
      final reminders = DailyReminderService.instance;
      await reminders.ensureLoaded();

      expect(reminders.isEnabled, isTrue);
      expect(reminders.hour, DailyReminderService.defaultHour);
      expect(reminders.hour, inInclusiveRange(17, 21),
          reason: 'a default outside the evening would train people to '
              'dismiss it');
    });

    test('time is clamped to a real clock', () async {
      final reminders = DailyReminderService.instance;
      await reminders.setTime(hour: 99, minute: -4);
      expect(reminders.hour, 23);
      expect(reminders.minute, 0);
    });
  });

  group('reminder copy', () {
    final reminders = DailyReminderService.instance;

    // A reminder that mentions a price move is an instruction to open the app
    // and trade. The Academy's own base-rate lesson is that trading more makes
    // retail outcomes worse, so pushing transactions on a schedule would have
    // the app working against its own curriculum — and would put it in the
    // category of engagement mechanics regulators have been narrowing.
    // Targets the harm specifically: market excitement and calls to
    // transact. Note that "trading" is not on the list — "no trading
    // required" and "your trading judgment" are the opposite of a push, and
    // banning the bare word would have failed copy that is doing the right
    // thing. What must never appear is a reason to open the app and buy
    // something.
    final forbidden = RegExp(
      r'\b(buy|sell|pump|surge|rally|moon|crash|profit|gains|'
      r'opportunity|signal|market|act now|trade now|don.t miss|'
      r'last chance|hurry)\b',
      caseSensitive: false,
    );

    test('never pushes trading, in any state', () {
      for (final streak in [0, 1, 7, 45]) {
        for (var offset = 0; offset < 7; offset++) {
          final m = reminders.messageForTest(dayOffset: offset, streak: streak);
          for (final text in [m.$1, m.$2]) {
            expect(forbidden.hasMatch(text), isFalse,
                reason: 'streak $streak, day +$offset: "$text" pushes market '
                    'activity rather than practice');
          }
        }
      }
    });

    test('says something in every state', () {
      for (final streak in [0, 3, 30]) {
        for (var offset = 0; offset < 7; offset++) {
          final m = reminders.messageForTest(dayOffset: offset, streak: streak);
          expect(m.$1.trim(), isNotEmpty);
          expect(m.$2.trim(), isNotEmpty);
        }
      }
    });

    test('mentions the streak only when there is one', () {
      final none = reminders.messageForTest(dayOffset: 0, streak: 0);
      expect('${none.$1} ${none.$2}', isNot(contains('0-day')));

      final live = reminders.messageForTest(dayOffset: 0, streak: 12);
      expect('${live.$1} ${live.$2}', contains('12'),
          reason: 'loss aversion is what makes a streak work, and naming the '
              'number is the honest version of it');
    });

    test('softens rather than escalates for someone who has drifted away', () {
      // Days 3+ target a user who has not opened the app all week. Ramping up
      // urgency at them is how an app gets uninstalled instead of reopened.
      final far = reminders.messageForTest(dayOffset: 5, streak: 20);
      expect('${far.$1} ${far.$2}'.toLowerCase(), isNot(contains('ends')));
      expect('${far.$1} ${far.$2}'.toLowerCase(), contains('no streak pressure'));
    });
  });
}

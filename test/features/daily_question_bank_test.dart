import 'package:flutter_test/flutter_test.dart';

import 'package:volex_terminal/features/daily/data/daily_question_bank.dart';
import 'package:volex_terminal/features/daily/services/daily_service.dart';

/// Guards the Daily question bank and the way days are drawn from it.
///
/// Both halves matter. The content is what users are asked to trust, and a
/// duplicate id or an empty explanation ships as a broken lesson. The draw is
/// the retention mechanic: the bank was previously 16 questions taken 5 at a
/// time, so the pool was exhausted in under a week and the streak became a
/// streak of re-answering the same questions. These tests exist so neither
/// failure can return quietly.
void main() {
  final pool = DailyQuestionBank.all;

  group('the bank', () {
    test('is deep enough for a habit to form', () {
      // 5 a day. Below ~150 the loop dies inside a month, which is inside the
      // window where a daily habit is still forming.
      expect(pool.length, greaterThanOrEqualTo(300),
          reason: 'at 5 calls a day this is ${pool.length ~/ 5} days before '
              'anything repeats');
    });

    test('every id is unique', () {
      final ids = pool.map((c) => c.id).toList();
      final seen = <String>{};
      final duplicates = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) duplicates.add(id);
      }
      expect(duplicates, isEmpty,
          reason: 'duplicate ids collide in the XP ledger and make two '
              'different questions indistinguishable in analytics');
    });

    test('every call is answerable and explained', () {
      for (final c in pool) {
        expect(c.prompt.trim(), isNotEmpty, reason: '${c.id} has no prompt');
        expect(c.optionA.trim(), isNotEmpty, reason: '${c.id} has no option A');
        expect(c.optionB.trim(), isNotEmpty, reason: '${c.id} has no option B');
        expect(c.optionA, isNot(equals(c.optionB)),
            reason: '${c.id} offers the same answer twice');
        // The explanation is the entire teaching payload. A question without
        // one is a quiz, not a lesson.
        expect(c.explanation.trim().length, greaterThan(40),
            reason: '${c.id} has a thin explanation');
      }
    });

    test('links only to lessons that exist', () {
      // Module prefixes in the Academy curriculum.
      final valid = RegExp(r'^[ftrp]\d+$');
      for (final c in pool) {
        final id = c.lessonId;
        if (id == null) continue;
        expect(valid.hasMatch(id), isTrue,
            reason: '${c.id} points at lesson "$id", which is not a lesson id');
      }
    });

    test('is not lopsided toward one answer', () {
      // If most answers were A, guessing A would beat thinking. Anything
      // near even is fine; this catches a bank written on autopilot.
      final a = pool.where((c) => c.correctIsA).length;
      final share = a / pool.length;
      expect(share, greaterThan(0.35));
      expect(share, lessThan(0.65));
    });
  });

  group('the daily draw', () {
    final service = DailyService.instance;
    final epoch = DateTime(2026, 1, 1);

    test('gives everyone the same challenge on the same day', () {
      final a = service.challengeFor(DateTime(2026, 6, 15));
      final b = service.challengeFor(DateTime(2026, 6, 15));
      expect(a.calls.map((c) => c.id), b.calls.map((c) => c.id),
          reason: 'a shared result is only comparable if the challenge is');
    });

    test('never repeats a question within one day', () {
      for (var day = 0; day < 120; day++) {
        final challenge = service.challengeFor(epoch.add(Duration(days: day)));
        final ids = challenge.calls.map((c) => c.id).toSet();
        expect(ids.length, challenge.calls.length,
            reason: 'day $day asked the same question twice');
      }
    });

    test('exhausts the pool before repeating anything', () {
      // The regression this whole change exists to prevent. With a per-day
      // shuffle, repeats appeared within the first week.
      final days = pool.length ~/ 5;
      final seen = <String>{};
      for (var day = 0; day < days; day++) {
        for (final call in service.challengeFor(epoch.add(Duration(days: day))).calls) {
          expect(seen.add(call.id), isTrue,
              reason: 'question ${call.id} came back on day $day, only '
                  '$days days into a $days-day cycle');
        }
      }
      expect(seen.length, days * 5);
    });

    test('spans more than one topic on a typical day', () {
      // The banks are interleaved so a contiguous slice crosses topics. If
      // someone concatenates them instead, this fails: every day would be
      // five questions from one subject.
      //
      // Ids are prefixed per bank (m_, r_, ps_, tb_, i_, mg_, c_/pr_, fo_),
      // so the prefix is a usable proxy for topic.
      var multiTopicDays = 0;
      for (var day = 0; day < 40; day++) {
        final prefixes = service
            .challengeFor(epoch.add(Duration(days: day)))
            .calls
            .map((c) => c.id.split('_').first)
            .toSet();
        if (prefixes.length > 1) multiTopicDays++;
      }
      expect(multiTopicDays, greaterThan(35),
          reason: 'days should mix topics, not serve one subject at a time');
    });

    test('day one is challenge number one', () {
      expect(service.challengeFor(epoch).number, 1);
      expect(service.challengeFor(epoch.add(const Duration(days: 9))).number, 10);
    });

    test('keeps working past the end of the pool', () {
      // Two years out, well beyond one cycle.
      final late = service.challengeFor(epoch.add(const Duration(days: 730)));
      expect(late.calls, hasLength(5));
      expect(late.calls.map((c) => c.id).toSet(), hasLength(5));
    });
  });
}

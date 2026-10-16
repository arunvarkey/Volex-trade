import 'package:flutter_test/flutter_test.dart';

import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/domain/position.dart';
import 'package:volex_terminal/features/insights/models/behaviour_insight.dart';
import 'package:volex_terminal/features/insights/services/behaviour_analysis_service.dart';
import 'package:volex_terminal/features/journal/models/journal_entry.dart';

/// Tests for the honest mirror.
///
/// Most of these assert that the analysis says *nothing*. That is the point:
/// this app teaches that a handful of results is noise, so telling a user
/// "you revenge trade" from six trades would contradict its own curriculum
/// while sounding authoritative. The suppression rules are the feature; the
/// findings are the easy part.
void main() {
  const service = BehaviourAnalysisService();
  final epoch = DateTime(2026, 5, 1, 9);

  /// A closed position. Defaults describe an ordinary small winner.
  Position closed({
    required int index,
    double pnl = 100,
    double? stop,
    double quantity = 1,
    double entry = 50000,
    Duration? held,
    DateTime? openedAt,
  }) {
    final opened = openedAt ?? epoch.add(Duration(days: index));
    final p = Position(
      id: 'p$index',
      symbol: 'BTCUSDT',
      side: OrderSide.buy,
      quantity: quantity,
      entryPrice: entry,
      openedAt: opened,
      isOpen: false,
      stopLoss: stop,
    );
    p.closedAt = opened.add(held ?? const Duration(hours: 1));
    p.realizedPnL = pnl;
    return p;
  }

  List<Position> many(int count, {Position Function(int)? build}) =>
      List.generate(count, (i) => build?.call(i) ?? closed(index: i));

  group('when the record is too short', () {
    test('says nothing at all from five trades', () {
      final report = service.analyse(positions: many(5));
      expect(report.insights, isEmpty,
          reason: 'five trades cannot support any claim about a habit');
      expect(report.tradesAnalysed, 5);
    });

    test('tells the user how many more trades it needs', () {
      final report = service.analyse(positions: many(8));
      expect(report.tradesUntilFirstInsight,
          BehaviourAnalysisService.minTradesForRate - 8);
      expect(report.hasInsights, isFalse);
    });

    test('nineteen trades is still not enough for a rate', () {
      final report = service.analyse(
        positions: many(19, build: (i) => closed(index: i, stop: null)),
      );
      expect(report.insights.where((i) => i.id.startsWith('stop_discipline')),
          isEmpty);
    });

    test('open positions are not counted', () {
      final open = Position(
        id: 'open',
        symbol: 'BTCUSDT',
        side: OrderSide.buy,
        quantity: 1,
        entryPrice: 50000,
        openedAt: epoch,
      );
      final report = service.analyse(positions: [...many(5), open]);
      expect(report.tradesAnalysed, 5);
    });
  });

  group('stop discipline', () {
    test('flags a majority of trades with no stop', () {
      // 20 trades, only 4 with a stop.
      final positions = many(20,
          build: (i) => closed(index: i, stop: i < 4 ? 49000 : null));
      final report = service.analyse(positions: positions);

      final insight = report.insights.firstWhere(
          (i) => i.id == 'stop_discipline_weak');
      expect(insight.tone, InsightTone.warning);
      expect(insight.sampleSize, 20);
      expect(insight.evidence, contains('4 of 20'));
    });

    test('credits consistent stop use rather than only scolding', () {
      final positions =
          many(20, build: (i) => closed(index: i, stop: 49000));
      final report = service.analyse(positions: positions);

      final insight = report.insights
          .firstWhere((i) => i.id == 'stop_discipline_strong');
      expect(insight.tone, InsightTone.good,
          reason: 'a mirror that only reports faults is discouraging, not '
              'honest');
    });
  });

  group('size after a loss', () {
    /// A record where every trade following a loss is much larger.
    List<Position> escalating() {
      final out = <Position>[];
      var when = epoch;
      for (var i = 0; i < 12; i++) {
        // A loss, closed at `when`.
        final loss = closed(
          index: i * 2,
          pnl: -200,
          openedAt: when,
          held: const Duration(minutes: 30),
        );
        out.add(loss);
        // A much larger trade opened ten minutes later.
        out.add(closed(
          index: i * 2 + 1,
          pnl: 50,
          quantity: 5,
          openedAt: loss.closedAt!.add(const Duration(minutes: 10)),
          held: const Duration(minutes: 30),
        ));
        when = when.add(const Duration(days: 1));
      }
      return out;
    }

    test('reports a clear escalation', () {
      final report = service.analyse(positions: escalating());
      final insight =
          report.insights.firstWhere((i) => i.id == 'size_up_after_loss');
      expect(insight.tone, InsightTone.warning);
      expect(insight.headline, contains('larger'));
      expect(insight.evidence, contains('within an hour'));
    });

    test('stays silent when sizing is steady', () {
      // Same shape, but the follow-up trade is the same size.
      final out = <Position>[];
      var when = epoch;
      for (var i = 0; i < 12; i++) {
        final loss = closed(
            index: i * 2,
            pnl: -200,
            openedAt: when,
            held: const Duration(minutes: 30));
        out.add(loss);
        out.add(closed(
          index: i * 2 + 1,
          pnl: 50,
          openedAt: loss.closedAt!.add(const Duration(minutes: 10)),
          held: const Duration(minutes: 30),
        ));
        when = when.add(const Duration(days: 1));
      }

      final report = service.analyse(positions: out);
      expect(report.insights.where((i) => i.id == 'size_up_after_loss'),
          isEmpty);
    });

    test('stays silent on a small difference', () {
      // 1.2x is inside what noise produces at this sample size.
      final out = <Position>[];
      var when = epoch;
      for (var i = 0; i < 12; i++) {
        final loss = closed(
            index: i * 2,
            pnl: -200,
            openedAt: when,
            held: const Duration(minutes: 30));
        out.add(loss);
        out.add(closed(
          index: i * 2 + 1,
          pnl: 50,
          quantity: 1.2,
          openedAt: loss.closedAt!.add(const Duration(minutes: 10)),
          held: const Duration(minutes: 30),
        ));
        when = when.add(const Duration(days: 1));
      }

      final report = service.analyse(positions: out);
      expect(report.insights.where((i) => i.id == 'size_up_after_loss'),
          isEmpty,
          reason: 'a 1.2x difference over 24 trades is not a finding');
    });
  });

  group('disposition effect', () {
    test('reports holding losers far longer than winners', () {
      final positions = many(24, build: (i) {
        final isWinner = i.isEven;
        return closed(
          index: i,
          pnl: isWinner ? 100 : -100,
          held: isWinner
              ? const Duration(minutes: 30)
              : const Duration(hours: 10),
        );
      });

      final insight = service
          .analyse(positions: positions)
          .insights
          .firstWhere((i) => i.id == 'disposition_effect');
      expect(insight.tone, InsightTone.warning);
      expect(insight.headline, contains('longer than'));
    });

    test('credits the harder discipline when it is present', () {
      final positions = many(24, build: (i) {
        final isWinner = i.isEven;
        return closed(
          index: i,
          pnl: isWinner ? 100 : -100,
          held: isWinner
              ? const Duration(hours: 10)
              : const Duration(minutes: 30),
        );
      });

      final insight = service
          .analyse(positions: positions)
          .insights
          .firstWhere((i) => i.id == 'disposition_healthy');
      expect(insight.tone, InsightTone.good);
    });

    test('needs enough of both winners and losers', () {
      // 22 winners, 3 losers — not enough losers to compare.
      final positions = many(25,
          build: (i) => closed(index: i, pnl: i < 3 ? -100 : 100));
      final report = service.analyse(positions: positions);
      expect(report.insights.where((i) => i.id.startsWith('disposition')),
          isEmpty);
    });
  });

  group('expectancy', () {
    test('calls a losing edge a losing edge even with a high win rate', () {
      // 70% win rate, but losses are four times the wins.
      final positions = many(30,
          build: (i) => closed(index: i, pnl: i < 21 ? 50 : -400));

      final insight = service
          .analyse(positions: positions)
          .insights
          .firstWhere((i) => i.id == 'expectancy');

      expect(insight.tone, InsightTone.warning);
      expect(insight.headline, contains('loses'));
      expect(insight.evidence, contains('70%'),
          reason: 'the flattering number is shown alongside, not hidden');
      expect(insight.suggestion, isNotNull);
    });

    test('recognises a positive edge on a low win rate', () {
      // 30% win rate, wins five times the losses.
      final positions = many(30,
          build: (i) => closed(index: i, pnl: i < 9 ? 500 : -100));

      final insight = service
          .analyse(positions: positions)
          .insights
          .firstWhere((i) => i.id == 'expectancy');

      expect(insight.tone, InsightTone.good);
      expect(insight.headline, contains('makes'));
    });
  });

  group('mood', () {
    JournalEntry entry(DateTime at, JournalMood mood) => JournalEntry(
          id: '${at.millisecondsSinceEpoch}-${mood.name}',
          note: 'n',
          mood: mood,
          createdAt: at,
        );

    test('says nothing without a journal', () {
      final report = service.analyse(positions: many(40));
      expect(report.insights.where((i) => i.id == 'mood_outcome_gap'), isEmpty);
    });

    test('needs enough trades on both kinds of day', () {
      // Only two risky days logged.
      final positions = many(40);
      final journal = [
        entry(epoch, JournalMood.revenge),
        entry(epoch.add(const Duration(days: 1)), JournalMood.greedy),
        for (var i = 2; i < 30; i++)
          entry(epoch.add(Duration(days: i)), JournalMood.calm),
      ];

      final report =
          service.analyse(positions: positions, journal: journal);
      expect(report.insights.where((i) => i.id == 'mood_outcome_gap'), isEmpty,
          reason: 'two risky days cannot support a claim about mood');
    });

    test('reports a large gap and hedges the causal claim', () {
      final positions = many(30, build: (i) {
        // First 14 days logged risky and lose; the rest are calm and win.
        return closed(index: i, pnl: i < 14 ? -300 : 200);
      });
      final journal = [
        for (var i = 0; i < 14; i++)
          entry(epoch.add(Duration(days: i)), JournalMood.anxious),
        for (var i = 14; i < 30; i++)
          entry(epoch.add(Duration(days: i)), JournalMood.calm),
      ];

      final insight = service
          .analyse(positions: positions, journal: journal)
          .insights
          .firstWhere((i) => i.id == 'mood_outcome_gap');

      expect(insight.tone, InsightTone.warning);
      expect(insight.suggestion, contains('rather than a proven cause'),
          reason: 'a once-a-day mood against many trades is an association, '
              'and the wording has to say so');
    });
  });

  group('the report as a whole', () {
    test('puts warnings before good news', () {
      // A record with both: no stops anywhere, but a positive edge.
      final positions = many(30,
          build: (i) =>
              closed(index: i, stop: null, pnl: i < 20 ? 300 : -100));

      final report = service.analyse(positions: positions);
      final tones = report.insights.map((i) => i.tone).toList();
      final firstGood = tones.indexOf(InsightTone.good);
      final lastWarning = tones.lastIndexOf(InsightTone.warning);

      if (firstGood != -1 && lastWarning != -1) {
        expect(lastWarning, lessThan(firstGood),
            reason: 'someone opening this once should see what is costing '
                'them before what is going well');
      }
    });

    test('every insight carries its sample size and it is honest', () {
      final positions = many(30,
          build: (i) => closed(index: i, stop: null, pnl: i.isEven ? 100 : -100));
      final report = service.analyse(positions: positions);

      expect(report.insights, isNotEmpty);
      for (final insight in report.insights) {
        expect(insight.sampleSize, greaterThan(0),
            reason: '${insight.id} claims something from no data');
        expect(insight.sampleSize, lessThanOrEqualTo(30),
            reason: '${insight.id} claims a larger sample than exists');
        expect(insight.evidence.trim(), isNotEmpty,
            reason: '${insight.id} has no numbers behind it');
      }
    });

    test('insight ids are unique within a report', () {
      final positions = many(40,
          build: (i) => closed(index: i, pnl: i.isEven ? 100 : -100));
      final report = service.analyse(positions: positions);
      final ids = report.insights.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}

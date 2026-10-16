import 'package:volex_terminal/domain/position.dart';
import 'package:volex_terminal/features/insights/models/behaviour_insight.dart';
import 'package:volex_terminal/features/journal/models/journal_entry.dart';

/// Reads a trader's own record back to them.
///
/// ## Why this is the app's most valuable feature, and its most dangerous
///
/// Every broker holds this data and uses it to increase your trading. Nobody
/// uses it to tell you that you size up after a loss. That asymmetry is the
/// whole opportunity — and it only holds if what we say is true.
///
/// The risk is obvious: with enough slicing, any record yields a pattern.
/// "You lose on Tuesdays" from nine trades is astrology with a progress bar,
/// and this app spends two Academy lessons teaching why. Telling a user
/// something we taught them to disbelieve would be worse than saying nothing.
///
/// So every check here obeys three rules:
///
/// 1. **A minimum sample, per check.** A rate over all trades needs fewer
///    observations than a comparison between two groups, which needs a
///    minimum in *each* group. The thresholds are stated as constants below
///    rather than buried in conditions.
/// 2. **A minimum effect.** Two groups always differ by something. A
///    difference is only reported when it is large enough that noise is an
///    implausible explanation on its own — a 52/48 split is not a finding.
/// 3. **The sample travels with the claim.** Every insight carries the number
///    of trades it rests on, and the UI shows it. A user who knows a finding
///    came from 23 trades can discount it correctly.
///
/// The analysis is a pure function of its inputs so it can be tested
/// exhaustively against hand-built records, which is the only way to be sure
/// a claim about someone's behaviour is arithmetic rather than vibes.
class BehaviourAnalysisService {
  const BehaviourAnalysisService();

  /// Enough closed trades for a simple rate (what fraction did X) to mean
  /// anything. At 20 the margin of error on a proportion is still roughly
  /// ±20 points, which is why rate findings are worded as habits rather than
  /// precise percentages.
  static const int minTradesForRate = 20;

  /// Comparisons between two groups need this many in *each* side. Ten is
  /// not a lot; it is paired with a large required effect size below.
  static const int minPerGroup = 10;

  /// How much bigger one group has to be before a difference is reported.
  /// 1.5x is deliberately coarse: at these sample sizes anything subtler is
  /// indistinguishable from chance.
  static const double minRatio = 1.5;

  /// A trade opened within this window of closing a loser is treated as a
  /// potential reaction to it rather than an independent decision.
  static const Duration reactionWindow = Duration(hours: 1);

  BehaviourReport analyse({
    required List<Position> positions,
    List<JournalEntry> journal = const [],
  }) {
    final closed = positions
        .where((p) => !p.isOpen && p.closedAt != null && p.realizedPnL != null)
        .toList()
      ..sort((a, b) => a.closedAt!.compareTo(b.closedAt!));

    final insights = <BehaviourInsight>[
      ..._stopDiscipline(closed),
      ..._didStopsHelp(closed),
      ..._sizeAfterLoss(closed),
      ..._reactionTrading(closed),
      ..._disposition(closed),
      ..._expectancy(closed),
      ..._moodOutcome(closed, journal),
    ];

    // Warnings first — someone opening this screen once should see the thing
    // that is costing them before the thing they are doing well.
    insights.sort((a, b) => _rank(a.tone).compareTo(_rank(b.tone)));

    return BehaviourReport(
      insights: insights,
      tradesAnalysed: closed.length,
      tradesUntilFirstInsight:
          closed.length >= minTradesForRate ? 0 : minTradesForRate - closed.length,
    );
  }

  static int _rank(InsightTone tone) => switch (tone) {
        InsightTone.warning => 0,
        InsightTone.neutral => 1,
        InsightTone.good => 2,
      };

  // ── Checks ────────────────────────────────────────────────────────

  /// How often a trade carried a stop at all.
  ///
  /// The app's central teaching claim, so it is the first thing measured.
  List<BehaviourInsight> _stopDiscipline(List<Position> closed) {
    if (closed.length < minTradesForRate) return const [];

    final withStop = closed.where((p) => p.stopLoss != null).length;
    final pct = withStop / closed.length;

    if (pct >= 0.9) {
      return [
        BehaviourInsight(
          id: 'stop_discipline_strong',
          headline: 'You set a stop on almost every trade.',
          evidence: '$withStop of ${closed.length} closed trades had a stop '
              'loss when you opened them.',
          sampleSize: closed.length,
          tone: InsightTone.good,
          lessonId: 't2',
        ),
      ];
    }

    if (pct < 0.5) {
      return [
        BehaviourInsight(
          id: 'stop_discipline_weak',
          headline: 'More than half your trades had no stop.',
          evidence: 'Only $withStop of ${closed.length} closed trades had a '
              'stop loss. A position without one has no defined maximum loss '
              '— the exit ends up being decided by how much pain you can '
              'stand.',
          suggestion: 'Set the stop in the same action as the entry, before '
              'the position exists.',
          sampleSize: closed.length,
          tone: InsightTone.warning,
          lessonId: 't2',
        ),
      ];
    }

    return [
      BehaviourInsight(
        id: 'stop_discipline_mixed',
        headline: 'You use stops on some trades but not others.',
        evidence: '$withStop of ${closed.length} closed trades had a stop.',
        suggestion: 'Worth checking which ones you skip. It is usually the '
            'trades you feel most certain about, which is where the habit '
            'matters most.',
        sampleSize: closed.length,
        tone: InsightTone.neutral,
        lessonId: 't2',
      ),
    ];
  }

  /// Did the trades with stops actually do better?
  ///
  /// The honest version of the app's own claim, tested against this user's
  /// record rather than asserted. If their stopped trades did worse, that is
  /// what this says — a mirror that only confirms the curriculum is a
  /// brochure.
  List<BehaviourInsight> _didStopsHelp(List<Position> closed) {
    final withStop = closed.where((p) => p.stopLoss != null).toList();
    final without = closed.where((p) => p.stopLoss == null).toList();
    if (withStop.length < minPerGroup || without.length < minPerGroup) {
      return const [];
    }

    final avgWith = _mean(withStop.map((p) => p.realizedPnL!));
    final avgWithout = _mean(without.map((p) => p.realizedPnL!));

    // Compare worst-case behaviour, which is what a stop is actually for.
    final worstWith = withStop.map((p) => p.realizedPnL!).reduce(_min);
    final worstWithout = without.map((p) => p.realizedPnL!).reduce(_min);

    if (worstWithout < worstWith * minRatio && worstWithout < 0) {
      return [
        BehaviourInsight(
          id: 'stops_limited_damage',
          headline: 'Your worst losses came from trades without a stop.',
          evidence: 'Worst loss with a stop: ${_money(worstWith)}. Worst '
              'without: ${_money(worstWithout)}. Across '
              '${withStop.length} stopped and ${without.length} unstopped '
              'trades.',
          sampleSize: closed.length,
          tone: InsightTone.warning,
          suggestion: 'This is your own record making the argument the '
              'Academy makes.',
          lessonId: 't2',
        ),
      ];
    }

    return [
      BehaviourInsight(
        id: 'stops_outcome_neutral',
        headline: 'Stops have not changed your average outcome much yet.',
        evidence: 'Average with a stop: ${_money(avgWith)}. Without: '
            '${_money(avgWithout)}. From ${withStop.length} and '
            '${without.length} trades.',
        suggestion: 'Stops limit the worst case rather than lift the average, '
            'and the worst case is rare — so this comparison needs a lot more '
            'trades before it says much.',
        sampleSize: closed.length,
        tone: InsightTone.neutral,
        lessonId: 'p6',
      ),
    ];
  }

  /// Position size on trades opened shortly after a loss, against baseline.
  ///
  /// The clearest measurable signature of revenge trading, and the one most
  /// people deny until they see it.
  List<BehaviourInsight> _sizeAfterLoss(List<Position> closed) {
    final losses = closed.where((p) => p.realizedPnL! < 0).toList();
    if (losses.isEmpty) return const [];

    final reactive = <Position>[];
    final baseline = <Position>[];

    for (final p in closed) {
      final followsLoss = losses.any((l) =>
          l.closedAt!.isBefore(p.openedAt) &&
          p.openedAt.difference(l.closedAt!) <= reactionWindow);
      (followsLoss ? reactive : baseline).add(p);
    }

    if (reactive.length < minPerGroup || baseline.length < minPerGroup) {
      return const [];
    }

    final avgReactive = _mean(reactive.map((p) => p.quantity * p.entryPrice));
    final avgBaseline = _mean(baseline.map((p) => p.quantity * p.entryPrice));
    if (avgBaseline <= 0) return const [];

    final ratio = avgReactive / avgBaseline;
    if (ratio < minRatio) return const [];

    return [
      BehaviourInsight(
        id: 'size_up_after_loss',
        headline:
            'You trade ${ratio.toStringAsFixed(1)}× larger right after a loss.',
        evidence: 'Average position within an hour of closing a loser: '
            '${_money(avgReactive)}. Otherwise: ${_money(avgBaseline)}. '
            'From ${reactive.length} reactive and ${baseline.length} other '
            'trades.',
        suggestion: 'The trade after a loss is where accounts are lost. A '
            'fixed size rule removes the decision while you are least able to '
            'make it.',
        sampleSize: closed.length,
        tone: InsightTone.warning,
        lessonId: 'p3',
      ),
    ];
  }

  /// How often a new trade follows a loss at all, regardless of size.
  List<BehaviourInsight> _reactionTrading(List<Position> closed) {
    if (closed.length < minTradesForRate) return const [];

    final losses = closed.where((p) => p.realizedPnL! < 0).toList();
    if (losses.length < minPerGroup) return const [];

    final quickFollowUps = closed.where((p) {
      return losses.any((l) =>
          l.closedAt!.isBefore(p.openedAt) &&
          p.openedAt.difference(l.closedAt!) <= reactionWindow);
    }).length;

    final share = quickFollowUps / closed.length;
    if (share < 0.3) return const [];

    return [
      BehaviourInsight(
        id: 'fast_reentry_after_loss',
        headline: 'You often re-enter within an hour of a loss.',
        evidence: '$quickFollowUps of ${closed.length} trades were opened '
            'within an hour of closing a losing one.',
        suggestion: 'Not automatically wrong — but worth checking whether '
            'those trades met your criteria or just arrived quickly.',
        sampleSize: closed.length,
        tone: InsightTone.neutral,
        lessonId: 'p3',
      ),
    ];
  }

  /// Cutting winners and running losers — the disposition effect, measured
  /// as the asymmetry between how long each is held.
  List<BehaviourInsight> _disposition(List<Position> closed) {
    final winners = closed.where((p) => p.realizedPnL! > 0).toList();
    final losers = closed.where((p) => p.realizedPnL! < 0).toList();
    if (winners.length < minPerGroup || losers.length < minPerGroup) {
      return const [];
    }

    final holdWin = _mean(winners.map(_holdMinutes));
    final holdLoss = _mean(losers.map(_holdMinutes));
    if (holdWin <= 0) return const [];

    final ratio = holdLoss / holdWin;
    if (ratio < minRatio) {
      // Holding winners at least as long as losers is the harder discipline
      // and deserves saying so.
      if (holdWin >= holdLoss * minRatio) {
        return [
          BehaviourInsight(
            id: 'disposition_healthy',
            headline: 'You hold winners longer than losers.',
            evidence: 'Average hold: ${_duration(holdWin)} on winners, '
                '${_duration(holdLoss)} on losers, across ${winners.length} '
                'and ${losers.length} trades.',
            sampleSize: winners.length + losers.length,
            tone: InsightTone.good,
            lessonId: 'p3',
          ),
        ];
      }
      return const [];
    }

    return [
      BehaviourInsight(
        id: 'disposition_effect',
        headline: 'You hold losers ${ratio.toStringAsFixed(1)}× longer than '
            'winners.',
        evidence: 'Average hold: ${_duration(holdLoss)} on losers against '
            '${_duration(holdWin)} on winners, across ${losers.length} and '
            '${winners.length} trades.',
        suggestion: 'Selling a winner confirms you were right and selling a '
            'loser confirms you were wrong, so the comfortable choice is '
            'backwards from the profitable one.',
        sampleSize: winners.length + losers.length,
        tone: InsightTone.warning,
        lessonId: 'p3',
      ),
    ];
  }

  /// Win rate, average win, average loss and expectancy — stated together,
  /// because any one of them alone misleads.
  List<BehaviourInsight> _expectancy(List<Position> closed) {
    if (closed.length < minTradesForRate) return const [];

    final winners = closed.where((p) => p.realizedPnL! > 0).toList();
    final losers = closed.where((p) => p.realizedPnL! < 0).toList();
    if (winners.isEmpty || losers.isEmpty) return const [];

    final winRate = winners.length / closed.length;
    final avgWin = _mean(winners.map((p) => p.realizedPnL!));
    final avgLoss = _mean(losers.map((p) => p.realizedPnL!)).abs();
    final expectancy = (winRate * avgWin) - ((1 - winRate) * avgLoss);

    final pct = (winRate * 100).round();
    final positive = expectancy > 0;

    return [
      BehaviourInsight(
        id: 'expectancy',
        headline: positive
            ? 'Your average trade makes ${_money(expectancy)}.'
            : 'Your average trade loses ${_money(expectancy.abs())}.',
        evidence: 'Win rate $pct% (${winners.length} of ${closed.length}), '
            'average win ${_money(avgWin)}, average loss ${_money(avgLoss)}. '
            'Expectancy is win rate × average win, minus loss rate × average '
            'loss.',
        suggestion: positive
            ? null
            : 'A high win rate does not rescue this if the losses are larger '
                'than the wins. The lever is usually the size of the average '
                'loss, not the frequency of winning.',
        sampleSize: closed.length,
        tone: positive ? InsightTone.good : InsightTone.warning,
        lessonId: 'p5',
      ),
    ];
  }

  /// Journal mood against the outcome of trades opened the same day.
  ///
  /// The loosest link in here — a mood logged at some point in a day is only
  /// roughly associated with the trades in it — so it needs both groups well
  /// populated and a large gap before it says anything, and it is worded as a
  /// prompt to look rather than a conclusion.
  List<BehaviourInsight> _moodOutcome(
    List<Position> closed,
    List<JournalEntry> journal,
  ) {
    if (journal.isEmpty) return const [];

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final riskyDays = journal
        .where((e) => e.mood.isRisky)
        .map((e) => e.createdAt)
        .toList();
    final calmDays = journal
        .where((e) => !e.mood.isRisky)
        .map((e) => e.createdAt)
        .toList();

    final risky = closed
        .where((p) => riskyDays.any((d) => sameDay(d, p.openedAt)))
        .toList();
    final calm = closed
        .where((p) => calmDays.any((d) => sameDay(d, p.openedAt)))
        .toList();

    if (risky.length < minPerGroup || calm.length < minPerGroup) {
      return const [];
    }

    final avgRisky = _mean(risky.map((p) => p.realizedPnL!));
    final avgCalm = _mean(calm.map((p) => p.realizedPnL!));
    if (avgCalm <= 0 || avgRisky >= avgCalm) return const [];

    final gap = (avgCalm - avgRisky) / avgCalm;
    if (gap < 0.5) return const [];

    return [
      BehaviourInsight(
        id: 'mood_outcome_gap',
        headline: 'Trades on days you logged anxious, greedy or revenge did '
            'worse.',
        evidence: 'Average ${_money(avgRisky)} on those days against '
            '${_money(avgCalm)} on calmer ones, across ${risky.length} and '
            '${calm.length} trades.',
        suggestion: 'A mood is logged once a day and trades are not, so treat '
            'this as somewhere to look rather than a proven cause.',
        sampleSize: risky.length + calm.length,
        tone: InsightTone.warning,
        lessonId: 'p1',
      ),
    ];
  }

  // ── Helpers ───────────────────────────────────────────────────────

  static double _mean(Iterable<double> values) {
    if (values.isEmpty) return 0;
    var total = 0.0;
    var count = 0;
    for (final v in values) {
      total += v;
      count++;
    }
    return total / count;
  }

  static double _min(double a, double b) => a < b ? a : b;

  static double _holdMinutes(Position p) =>
      p.closedAt!.difference(p.openedAt).inSeconds / 60.0;

  static String _money(double v) {
    final abs = v.abs();
    final sign = v < 0 ? '-' : '';
    if (abs >= 1000) return '$sign\$${abs.toStringAsFixed(0)}';
    return '$sign\$${abs.toStringAsFixed(2)}';
  }

  static String _duration(double minutes) {
    if (minutes < 60) return '${minutes.round()} min';
    if (minutes < 60 * 24) return '${(minutes / 60).toStringAsFixed(1)} hours';
    return '${(minutes / (60 * 24)).toStringAsFixed(1)} days';
  }
}

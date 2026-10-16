/// A single finding about how someone actually trades.
///
/// Every field exists to stop this feature becoming a horoscope. A finding
/// carries the numbers it was computed from and the sample it rests on, so a
/// user can check it rather than believe it — and so we cannot quietly ship a
/// claim we could not defend.
class BehaviourInsight {
  /// Stable key, for analytics and for the "don't show me this again" case.
  final String id;

  /// The claim, in one line, in the second person. "You set a stop on 8 out
  /// of 10 trades."
  final String headline;

  /// The numbers behind the headline, stated plainly enough that a user could
  /// recompute them from their own trade list.
  final String evidence;

  /// What to do about it, or null when the finding is already good news and
  /// the advice would be padding.
  final String? suggestion;

  /// How many trades (or journal entries) the finding rests on. Shown, always
  /// — a user who knows this is from 23 trades can weigh it correctly, and a
  /// user who is not told cannot.
  final int sampleSize;

  final InsightTone tone;

  /// Academy lesson that teaches the concept, for the "learn this" link.
  final String? lessonId;

  const BehaviourInsight({
    required this.id,
    required this.headline,
    required this.evidence,
    required this.sampleSize,
    required this.tone,
    this.suggestion,
    this.lessonId,
  });
}

/// Whether a finding is something to keep doing, something neutral, or
/// something to change.
///
/// [good] exists deliberately. A mirror that only ever reports faults is not
/// honest, it is just discouraging — and a learner who is told what is working
/// knows what to protect when they change something else.
enum InsightTone { good, neutral, warning }

/// What the analysis produced, including the case where it produced nothing.
class BehaviourReport {
  final List<BehaviourInsight> insights;

  /// Closed trades the analysis had to work with.
  final int tradesAnalysed;

  /// How many more closed trades until the thinnest useful check can run.
  /// Zero once there is enough. This is shown instead of findings when the
  /// record is too short, because "come back after 12 more trades" is a
  /// useful instruction and a made-up insight is not.
  final int tradesUntilFirstInsight;

  const BehaviourReport({
    required this.insights,
    required this.tradesAnalysed,
    required this.tradesUntilFirstInsight,
  });

  bool get hasInsights => insights.isNotEmpty;

  /// Findings worth acting on, most important first.
  List<BehaviourInsight> get warnings =>
      insights.where((i) => i.tone == InsightTone.warning).toList();
}

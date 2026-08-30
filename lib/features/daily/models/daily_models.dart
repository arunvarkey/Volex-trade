/// A single call in the daily challenge: a binary trading-judgment question
/// with one correct answer, an explanation, and an optional linked lesson.
class DailyCall {
  final String id;
  final String prompt;
  final String context;
  final String optionA;
  final String optionB;

  /// True if [optionA] is the correct answer, false if [optionB] is.
  final bool correctIsA;

  final String explanation;

  /// Academy lesson id that teaches this concept (for "learn this" after a
  /// wrong answer), or null.
  final String? lessonId;

  const DailyCall({
    required this.id,
    required this.prompt,
    required this.context,
    required this.optionA,
    required this.optionB,
    required this.correctIsA,
    required this.explanation,
    this.lessonId,
  });

  /// Whether [choseA] matches the correct answer.
  bool isCorrect(bool choseA) => choseA == correctIsA;
}

/// The set of calls for a given day, plus its Wordle-style number.
class DailyChallenge {
  final String dateKey; // yyyy-mm-dd
  final int number; // "Volex Daily #N"
  final List<DailyCall> calls;

  const DailyChallenge({
    required this.dateKey,
    required this.number,
    required this.calls,
  });

  int get length => calls.length;
}

/// The outcome of playing a day's challenge.
class DailyResult {
  final String dateKey;
  final int number;
  final int score; // correct answers
  final int total;

  /// Per-call correctness in order (for the shareable emoji grid).
  final List<bool> correctness;

  final int streakAfter;

  const DailyResult({
    required this.dateKey,
    required this.number,
    required this.score,
    required this.total,
    required this.correctness,
    required this.streakAfter,
  });

  /// A plain description of how the round went.
  ///
  /// This used to return percentile bands -- "top 5%", "top 20%" -- computed
  /// purely from the user's own score against nobody. There is no player
  /// population to be in the top 5% of; the number was a relabelling of
  /// score/total dressed as a ranking. It also went into the shareable text,
  /// so a user posted a percentile claim about a leaderboard that does not
  /// exist. If real global ranking arrives later it can be added as an
  /// actual rank; until then the score describes itself.
  String get scoreBand {
    if (total == 0) return '—';
    final pct = score / total;
    if (pct >= 1.0) return 'a perfect round';
    if (pct >= 0.8) return 'a strong round';
    if (pct >= 0.6) return 'a solid round';
    if (pct >= 0.4) return 'a mixed round';
    return 'a round to learn from';
  }

  /// Wordle-style shareable text (copied to clipboard).
  String shareText() {
    final grid = correctness.map((c) => c ? '🟩' : '🟥').join();
    final buf = StringBuffer()
      ..writeln('Volex Daily #$number')
      ..writeln('$grid  $score/$total')
      ..writeln('🔥 $streakAfter-day streak')
      ..write('The flight simulator for traders');
    return buf.toString();
  }
}

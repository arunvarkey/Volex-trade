
/// Emotional states that AI Guardian detects
enum EmotionalState {
  calm,
  fomo,
  panic,
  revenge,
  overconfident,
}

extension EmotionalStateExt on EmotionalState {
  String get name {
    switch (this) {
      case EmotionalState.calm:
        return 'Calm & Rational';
      case EmotionalState.fomo:
        return 'FOMO Detected';
      case EmotionalState.panic:
        return 'Panic Selling';
      case EmotionalState.revenge:
        return 'Revenge Trading';
      case EmotionalState.overconfident:
        return 'Overconfident';
    }
  }

  String get description {
    switch (this) {
      case EmotionalState.calm:
        return 'Your trading mindset appears balanced';
      case EmotionalState.fomo:
        return 'You\'re entering during rapid price movement';
      case EmotionalState.panic:
        return 'You\'re exiting a losing position hastily';
      case EmotionalState.revenge:
        return 'You just lost money and are trading again immediately';
      case EmotionalState.overconfident:
        return 'Position size is unusually large after winning streak';
    }
  }
}

/// Dangerous trading patterns
class PatternWarning {
  final String name;
  final String description;

  /// The user's own win rate over [sampleSize] recent trades, as a
  /// percentage, or null when there is not enough history to say.
  ///
  /// This replaces a `historicalWinRate` field that carried a hardcoded 5.0
  /// or 15.0 depending on the pattern. The warning dialog printed it as
  /// "Historical win rate: 5%" — an invented population statistic presented
  /// as fact to someone in the middle of placing a trade. The guardian
  /// already holds the user's real trade history, so it reports what that
  /// history actually says instead.
  final double? yourWinRate;

  /// How many of the user's trades [yourWinRate] was computed over, so the
  /// number is never shown without the sample behind it.
  final int sampleSize;

  PatternWarning({
    required this.name,
    required this.description,
    this.yourWinRate,
    this.sampleSize = 0,
  });
}

/// Complete analysis from AI Guardian
class TradeAnalysis {
  final EmotionalState emotionalState;
  final List<PatternWarning> patterns;
  final double riskScore; // 0-100
  final bool shouldWarn;
  final String recommendation;

  TradeAnalysis({
    required this.emotionalState,
    required this.patterns,
    required this.riskScore,
    required this.shouldWarn,
    required this.recommendation,
  });
}

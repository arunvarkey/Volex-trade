
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
  final double historicalWinRate;

  PatternWarning({
    required this.name,
    required this.description,
    required this.historicalWinRate,
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

/// A single trading-journal entry.
///
/// The Academy teaches: "Journal every trade with why you entered and how you
/// felt. Patterns in your behaviour become obvious — and fixable." This is the
/// data behind that habit: what you did, why, and the mood you were in.
class JournalEntry {
  final String id;

  /// Optional market the note is about, e.g. 'BTCUSDT'. Free-form reflections
  /// (a daily review, a rule you broke) don't need one.
  final String? symbol;

  /// Why you entered / what happened. The substance of the entry.
  final String note;

  /// How you felt. Naming the emotion is the point of the exercise — it's what
  /// makes behavioural patterns visible later.
  final JournalMood mood;

  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.note,
    required this.mood,
    required this.createdAt,
    this.symbol,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'note': note,
        'mood': mood.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final moodName = json['mood'] as String?;
    return JournalEntry(
      id: json['id'] as String,
      symbol: json['symbol'] as String?,
      note: json['note'] as String? ?? '',
      mood: JournalMood.values.firstWhere(
        (m) => m.name == moodName,
        orElse: () => JournalMood.neutral,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// The emotional states that most often drive trading mistakes, plus a neutral
/// baseline. Deliberately small — a long list discourages honest tagging.
enum JournalMood {
  calm,
  confident,
  neutral,
  anxious,
  greedy,
  revenge;

  String get label {
    switch (this) {
      case JournalMood.calm:
        return 'Calm';
      case JournalMood.confident:
        return 'Confident';
      case JournalMood.neutral:
        return 'Neutral';
      case JournalMood.anxious:
        return 'Anxious';
      case JournalMood.greedy:
        return 'Greedy';
      case JournalMood.revenge:
        return 'Revenge';
    }
  }

  /// True for the states the Academy flags as danger signs — surfaced so a
  /// learner can see how often they trade from them.
  bool get isRisky =>
      this == JournalMood.anxious ||
      this == JournalMood.greedy ||
      this == JournalMood.revenge;
}

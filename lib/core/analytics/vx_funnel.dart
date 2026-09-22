import 'package:volex_terminal/services/analytics_service.dart';

/// The funnel: the handful of events that answer whether Volex works.
///
/// Before this existed there were ten event names, six of which measured
/// trading — orders placed, strategies started, trades executed. Nothing
/// measured learning, retention, or whether anyone finished onboarding. We
/// could ship any change and be unable to tell whether it helped, which is
/// the difference between engineering and guessing.
///
/// Why typed methods instead of [AnalyticsService.logEvent] directly: a
/// mistyped event name does not fail, it silently creates a second, empty
/// series. Funnels are built from names matching exactly, so the names live
/// here once and call sites cannot spell them differently.
///
/// **Firebase must be configured for any of this to record.** Without
/// `android/app/google-services.json` the app runs Firebase-free by design
/// and every call here is a no-op. That is the correct behaviour, but it does
/// mean shipping without Firebase means shipping blind.
///
/// Event and parameter names follow Firebase's rules: 40 characters or fewer,
/// letters, digits and underscores, no `firebase_`/`google_`/`ga_` prefix.
class VxFunnel {
  VxFunnel._();

  static AnalyticsService get _a => AnalyticsService.instance;

  // ── Activation ────────────────────────────────────────────────────
  //
  // The steepest drop in almost every app is before the user reaches the
  // thing the app is for. We currently cannot see any of it.

  /// A slide of the onboarding pager became visible.
  ///
  /// [index] is what matters: the step where the count collapses is the step
  /// to rewrite.
  static void onboardingStep(int index, String name) => _a.logEvent(
        'onboarding_step',
        parameters: {'step_index': index, 'step_name': name},
      );

  static void onboardingFinished() => _a.logEvent('onboarding_finished');

  /// The 18+ and risk acknowledgement. Anyone who quits here never sees the
  /// app, and we are required to keep the gate, so it is worth knowing its
  /// cost.
  static void riskDisclosureAccepted() =>
      _a.logEvent('risk_disclosure_accepted');

  /// The first trade this install has ever placed — the activation moment.
  ///
  /// [withStop] separates users who adopted the habit the app teaches from
  /// those who ignored it. If the two cohorts retain differently, that is the
  /// strongest argument the product makes.
  static void firstTrade({required bool withStop}) => _a.logEvent(
        'activation_first_trade',
        parameters: {'with_stop': withStop ? 1 : 0},
      );

  /// The first position closed. Opening a trade is curiosity; closing one is
  /// the first complete loop.
  static void firstClose({required bool profitable}) => _a.logEvent(
        'activation_first_close',
        parameters: {'profitable': profitable ? 1 : 0},
      );

  // ── The learning loop ─────────────────────────────────────────────

  static void lessonStarted(String lessonId) => _a.logEvent(
        'lesson_started',
        parameters: {'lesson_id': lessonId},
      );

  /// [seconds] catches the lesson people open and abandon, which reads as a
  /// completion in a naive funnel.
  static void lessonCompleted(String lessonId, int seconds) => _a.logEvent(
        'lesson_completed',
        parameters: {'lesson_id': lessonId, 'seconds': seconds},
      );

  static void quizAnswered(String lessonId, {required bool correct}) =>
      _a.logEvent(
        'quiz_answered',
        parameters: {'lesson_id': lessonId, 'correct': correct ? 1 : 0},
      );

  /// A glossary search, and whether we had the term.
  ///
  /// The misses are the point: they are a list, written by users, of the
  /// vocabulary the app is missing. The query is lowercased, stripped to
  /// letters and spaces and capped at 40 characters before it is sent — a
  /// glossary box is not somewhere people type secrets, but it is a free-text
  /// field and it should not be able to carry anything else out.
  static void glossarySearched(String query, {required bool found}) {
    final cleaned = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z ]'), '')
        .trim();
    if (cleaned.isEmpty) return;
    _a.logEvent('glossary_searched', parameters: {
      'term': cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned,
      'found': found ? 1 : 0,
    });
  }

  // ── The daily habit ───────────────────────────────────────────────

  static void dailyStarted(int challengeNumber) => _a.logEvent(
        'daily_started',
        parameters: {'challenge_number': challengeNumber},
      );

  static void dailyCompleted({
    required int score,
    required int outOf,
    required int streakDays,
  }) =>
      _a.logEvent('daily_completed', parameters: {
        'score': score,
        'out_of': outOf,
        'streak_days': streakDays,
      });

  /// A streak broke. Losing one is a churn cliff — people abandon rather than
  /// restart from zero — so the distribution of [previousStreak] tells us
  /// where a streak freeze would pay for itself.
  static void dailyStreakLost(int previousStreak) => _a.logEvent(
        'daily_streak_lost',
        parameters: {'previous_streak': previousStreak},
      );

  // ── Money ─────────────────────────────────────────────────────────

  /// A free user reached a limit Premium lifts.
  ///
  /// This is the most important monetisation event in the app, and the one
  /// whose absence is most likely to be the answer. Premium lifts exactly two
  /// things: signals shown per day (10) and saved strategies (3). If nobody
  /// hits either, nobody has a reason to pay, and no amount of paywall
  /// rewriting changes that — the offer does not match a felt need.
  ///
  /// Counting this before optimising the paywall is the difference between
  /// fixing the funnel and redecorating it.
  static void limitHit(String limit) => _a.logEvent(
        'limit_hit',
        parameters: {'limit': limit},
      );

  static void paywallViewed(String source) => _a.logEvent(
        'paywall_viewed',
        parameters: {'source': source},
      );

  static void purchaseStarted(String plan) => _a.logEvent(
        'purchase_started',
        parameters: {'plan': plan},
      );

  static void purchaseSucceeded(String plan) => _a.logEvent(
        'purchase_succeeded',
        parameters: {'plan': plan},
      );

  /// [reason] is the field that would have surfaced the dead Upgrade button:
  /// with no products configured in the Play Console the purchase call caught
  /// its own exception and returned false, and nothing anywhere recorded it.
  static void purchaseFailed(String plan, String reason) => _a.logEvent(
        'purchase_failed',
        parameters: {'plan': plan, 'reason': reason},
      );

  // ── Cohorts ───────────────────────────────────────────────────────

  /// User properties let Firebase split retention by behaviour, which is what
  /// turns "13% came back on day 7" into "38% of users with a streak came
  /// back and 4% of the rest did".
  ///
  /// Values are bucketed rather than exact: Firebase caps a property at 25
  /// distinct values before it stops being useful for segmentation, and an
  /// exact streak count would blow through that in a month.
  static void setStreakBucket(int streakDays) => _a.setUserProperty(
        'streak_bucket',
        _bucket(streakDays, const [1, 4, 8, 31]),
      );

  static void setLessonsBucket(int lessonsDone) => _a.setUserProperty(
        'lessons_bucket',
        _bucket(lessonsDone, const [1, 4, 11, 21]),
      );

  static void setIsPremium({required bool isPremium}) =>
      _a.setUserProperty('is_premium', isPremium ? 'yes' : 'no');

  /// Labels [value] by which half-open range it falls in, so 0 reads as "0"
  /// and the rest read as "4_7", "31_plus" and so on.
  static String _bucket(int value, List<int> edges) {
    if (value < edges.first) return '0';
    for (var i = 0; i < edges.length - 1; i++) {
      if (value < edges[i + 1]) return '${edges[i]}_${edges[i + 1] - 1}';
    }
    return '${edges.last}_plus';
  }
}

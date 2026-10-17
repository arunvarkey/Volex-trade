import '../models/academy_models.dart';

/// Checkpoint quizzes for the Academy curriculum.
///
/// Three questions per lesson, written straight from the lesson's own content.
/// A learner must answer at least [passThreshold] of them correctly for the
/// lesson to count as complete — reading alone no longer marks it done. Kept in
/// a separate bank (keyed by lesson id) so the `const` curriculum stays
/// untouched and questions are easy to unit-test.
class AcademyQuizzes {
  AcademyQuizzes._();

  /// Correct answers required (out of 3) to pass a lesson quiz.
  static const int passThreshold = 2;

  /// Total questions in every lesson quiz.
  static const int questionsPerQuiz = 3;

  static List<QuizQuestion> forLesson(String lessonId) =>
      _byLesson[lessonId] ?? const <QuizQuestion>[];

  static bool hasQuiz(String lessonId) =>
      (_byLesson[lessonId]?.isNotEmpty ?? false);

  /// True if [correct] out of the quiz is a passing score.
  static bool isPass(int correct) => correct >= passThreshold;

  static const Map<String, List<QuizQuestion>> _byLesson = {
    // ── Foundations ────────────────────────────────────────────────
    'f1': [
      QuizQuestion(
        prompt: 'What really separates trading from gambling?',
        options: [
          'A trader never loses a single trade',
          'A trader follows a plan with defined risk and controls losses over many trades',
          'Gamblers use charts and traders never do',
          'Trading is guaranteed to be profitable',
        ],
        correctIndex: 1,
        explanation:
            "It isn't one win or loss — it's having an edge and controlling "
            'your losses across many trades.',
      ),
      QuizQuestion(
        prompt: 'How do investors typically differ from traders?',
        options: [
          'Investors hold for years; traders profit from shorter moves',
          'Investors always make more money',
          'Traders never sell anything',
          'There is no real difference',
        ],
        correctIndex: 0,
        explanation:
            'Investing and trading are different jobs with different skills and '
            'time horizons — neither is inherently "better".',
      ),
      QuizQuestion(
        prompt: 'Why practise with virtual money in Volex?',
        options: [
          'Because virtual profits can be withdrawn as cash',
          'To build real skill with \$0 at risk',
          'Because real trading is illegal',
          'It makes prices move faster',
        ],
        correctIndex: 1,
        explanation:
            'The whole point is to build the habit and skill risk-free — treat '
            'every paper trade as if it were real.',
      ),
    ],
    'f2': [
      QuizQuestion(
        prompt: 'What is the "bid"?',
        options: [
          'The highest price a buyer will pay right now',
          'The lowest price a seller will accept',
          'The last traded price',
          "The day's highest price",
        ],
        correctIndex: 0,
        explanation:
            'Bid = best buyer price, ask = best seller price, and the gap '
            'between them is the spread.',
      ),
      QuizQuestion(
        prompt: 'Price rises when…',
        options: [
          'More people want to sell than buy',
          'More people want to buy than sell',
          'Volume drops to zero',
          'The spread widens',
        ],
        correctIndex: 1,
        explanation:
            'Price is a live tug-of-war: more buyers than sellers pushes it up, '
            'and vice versa.',
      ),
      QuizQuestion(
        prompt: 'A green candle means…',
        options: [
          'Buyers won the tug-of-war for that moment',
          'Guaranteed future gains',
          'Sellers were in control',
          'There was no liquidity',
        ],
        correctIndex: 0,
        explanation:
            'Every green candle is buyers winning for a moment; every red one '
            'is sellers winning.',
      ),
    ],
    'f3': [
      QuizQuestion(
        prompt: 'Which four prices does a single candlestick show?',
        options: [
          'Bid, ask, spread, volume',
          'Open, high, low, close',
          'Support, resistance, trend, range',
          'RSI, MA, volume, price',
        ],
        correctIndex: 1,
        explanation:
            'One candle packs open, high, low and close into a single shape for '
            'its slice of time.',
      ),
      QuizQuestion(
        prompt: 'What is the candle "body"?',
        options: [
          'The open-to-close range',
          'The highest price reached',
          'The thin wick lines',
          'The total volume traded',
        ],
        correctIndex: 0,
        explanation:
            'The thick body is open-to-close; the thin wicks mark the high and '
            'low extremes.',
      ),
      QuizQuestion(
        prompt: 'A long lower wick often signals…',
        options: [
          'Buyers stepped in hard at the lows (possible support)',
          'Sellers took complete control',
          'The candle is invalid',
          'Nothing at all',
        ],
        correctIndex: 0,
        explanation:
            'A long wick shows price tried to go somewhere and got rejected — a '
            'long lower wick means buyers defended the lows.',
      ),
    ],
    'f4': [
      QuizQuestion(
        prompt: 'How often are even great traders wrong?',
        options: [
          'Almost never',
          '40–60% of the time',
          'Exactly 50%, always',
          'Only in bear markets',
        ],
        correctIndex: 1,
        explanation:
            'They still profit because they lose small and win bigger — not '
            'because they are always right.',
      ),
      QuizQuestion(
        prompt: 'What does the 1% rule say?',
        options: [
          'Aim for 1% profit every day',
          'Risk no more than about 1% of your account on a single trade',
          'Keep 1% of your trades open at all times',
          'Trade for only 1% of the day',
        ],
        correctIndex: 1,
        explanation:
            'Risking ~1% per trade means no single loss — or even ten in a row '
            '— can wipe you out.',
      ),
      QuizQuestion(
        prompt: 'The fastest way to blow up an account is…',
        options: [
          'Bad analysis',
          'Risking too much on one trade and being unable to recover',
          'Using limit orders',
          'Reading too many charts',
        ],
        correctIndex: 1,
        explanation:
            'Protecting capital comes first — you can\'t trade tomorrow if you '
            'blow up today.',
      ),
    ],

    // ── Your First Trades ──────────────────────────────────────────
    't1': [
      QuizQuestion(
        prompt: 'A market order…',
        options: [
          'Fills right now at the best available price',
          'Only fills at the exact price you choose',
          'Never pays the spread',
          'Guarantees a profit',
        ],
        correctIndex: 0,
        explanation:
            'Market = speed: you fill immediately but accept whatever price is '
            'available.',
      ),
      QuizQuestion(
        prompt: 'A limit order…',
        options: [
          'Always fills instantly',
          'Fills only at your price or better, but may never fill',
          'Ignores the price you set',
          'Can only be used to sell',
        ],
        correctIndex: 1,
        explanation:
            'Limit = price control: you name the price, but the market may never '
            'reach it.',
      ),
      QuizQuestion(
        prompt: 'A downside of over-using market orders is…',
        options: [
          'You pay the spread every time',
          'They are illegal',
          'They can never be cancelled',
          'They always fill at the worst price',
        ],
        correctIndex: 0,
        explanation:
            'Leaning on limit orders builds patience and better entries instead '
            'of paying the spread repeatedly.',
      ),
    ],
    't2': [
      QuizQuestion(
        prompt: 'A stop-loss…',
        options: [
          'Closes your trade if price moves against you past a set point',
          'Locks in a guaranteed profit',
          'Doubles your position size',
          'Is set only after you exit',
        ],
        correctIndex: 0,
        explanation:
            'A stop-loss caps the downside; a take-profit closes you at your '
            'target. Together they turn a hope into a plan.',
      ),
      QuizQuestion(
        prompt: 'When should you set your stop-loss?',
        options: [
          'Before you enter the trade',
          "Only once you're already losing",
          "Never, if you're confident",
          'At the very end of the day',
        ],
        correctIndex: 0,
        explanation:
            'Decide where you\'re wrong before you\'re in and emotional — once '
            'losing, your brain will invent reasons to move it.',
      ),
      QuizQuestion(
        prompt: 'A trade with no stop-loss is really…',
        options: [
          'The safest kind of trade',
          'An open-ended bet on your ego',
          'A limit order',
          'Guaranteed to win',
        ],
        correctIndex: 1,
        explanation:
            'Without a pre-planned exit, a small loss can quietly become an '
            'account-killing one.',
      ),
    ],
    't3': [
      QuizQuestion(
        prompt: 'Your position size should be driven by…',
        options: [
          'Your risk, not your excitement',
          'How much you hope to make',
          'The current RSI reading',
          "Your account's age",
        ],
        correctIndex: 0,
        explanation:
            'Start from "how much can I lose?" and size backwards — that '
            'reversal separates survivors from gamblers.',
      ),
      QuizQuestion(
        prompt:
            'You risk \$100 and your stop is \$50 away. What is your position size?',
        options: ['0.5 units', '2 units', '50 units', '100 units'],
        correctIndex: 1,
        explanation: 'Position size = risk ÷ stop distance = \$100 ÷ \$50 = 2 units.',
      ),
      QuizQuestion(
        prompt: 'The key mindset reversal in sizing is…',
        options: [
          'Always use maximum leverage',
          "Start from 'how much can I lose?' rather than 'how much do I want?'",
          'Size up after every win',
          'Ignore the stop distance',
        ],
        correctIndex: 1,
        explanation:
            'You never start from the reward — you start from the risk and let '
            'the stop decide the size.',
      ),
    ],
    't4': [
      QuizQuestion(
        prompt: 'A complete trade includes…',
        options: [
          'Just a direction and hope',
          'Direction + reason + stop + target + correct size',
          'Only an entry price',
          'A market order and nothing else',
        ],
        correctIndex: 1,
        explanation: 'Do all five, every time — that is a structured trade.',
      ),
      QuizQuestion(
        prompt: 'Your entry should be based on…',
        options: [
          'A reason, not just a feeling',
          'How bored you are',
          'The largest size you can take',
          'Avoiding a stop-loss',
        ],
        correctIndex: 0,
        explanation:
            'Pick a direction and a reason — trading on a feeling is closer to '
            'gambling.',
      ),
      QuizQuestion(
        prompt: 'Placing a paper trade in Volex risks…',
        options: [
          'Your whole account',
          'No real money',
          '10% per trade',
          'Real capital immediately',
        ],
        correctIndex: 1,
        explanation:
            'Paper trading is your practice range — nothing here touches real '
            'money.',
      ),
    ],

    // ── Reading the Market ─────────────────────────────────────────
    'r1': [
      QuizQuestion(
        prompt: 'Support is…',
        options: [
          'A level where buyers repeatedly step in — a floor',
          'A ceiling that sellers defend',
          "The day's volume",
          'A type of order',
        ],
        correctIndex: 0,
        explanation:
            'Support is a floor of buying; resistance is a ceiling of selling. '
            'Price tends to bounce between them.',
      ),
      QuizQuestion(
        prompt: 'Why do support and resistance levels matter?',
        options: [
          "They're where other traders place orders — crowd memory",
          "They're magic numbers set by the exchange",
          'They guarantee a reversal',
          'They control the spread',
        ],
        correctIndex: 0,
        explanation:
            "A level isn't magic; it's memory. Lots of traders act around it, "
            'which makes it self-reinforcing.',
      ),
      QuizQuestion(
        prompt: 'When support finally breaks, it often…',
        options: [
          'Becomes resistance',
          'Disappears forever',
          'Guarantees a crash',
          'Becomes stronger support',
        ],
        correctIndex: 0,
        explanation: 'Old floors tend to become new ceilings (and vice versa).',
      ),
    ],
    'r2': [
      QuizQuestion(
        prompt: 'An uptrend is a series of…',
        options: [
          'Higher highs and higher lows',
          'Lower highs and lower lows',
          'A flat, sideways range',
          'Purely random noise',
        ],
        correctIndex: 0,
        explanation:
            'Uptrend = higher highs and higher lows; downtrend = lower highs and '
            'lower lows; neither = a range.',
      ),
      QuizQuestion(
        prompt: 'Trading with the trend…',
        options: [
          'Puts the odds on your side',
          'Guarantees a win',
          'Is only for beginners',
          'Means you never use stops',
        ],
        correctIndex: 0,
        explanation:
            'The trend is your friend until it bends — fighting a strong one is '
            'where beginners lose most.',
      ),
      QuizQuestion(
        prompt: '"Catching a falling knife" means…',
        options: [
          'Fighting a strong downtrend',
          'A safe scalping method',
          'Buying exactly at support',
          'Using a limit order',
        ],
        correctIndex: 0,
        explanation:
            'Trying to buy a sharply falling market against the trend is a fast '
            'way to lose.',
      ),
    ],
    'r3': [
      QuizQuestion(
        prompt: 'A moving average…',
        options: [
          'Smooths price into the average of the last N candles',
          "Predicts tomorrow's price",
          'Measures traded volume',
          'Is always a flat line',
        ],
        correctIndex: 0,
        explanation:
            'An MA helps you see the forest instead of every tree — price above '
            'a rising MA usually means an uptrend.',
      ),
      QuizQuestion(
        prompt: 'An RSI reading above ~70 is often called…',
        options: ['Oversold', 'Overbought', 'A guaranteed sell', 'Neutral'],
        correctIndex: 1,
        explanation:
            'Above ~70 is "overbought", below ~30 "oversold" — but in a strong '
            'trend RSI can stay stretched for a long time.',
      ),
      QuizQuestion(
        prompt: 'The honest truth about indicators is…',
        options: [
          "They summarise the past; they don't predict the future",
          'They always predict reversals',
          'They replace a trading plan',
          'Higher RSI always means buy',
        ],
        correctIndex: 0,
        explanation:
            'No indicator is a crystal ball — use them to confirm an idea, not '
            'to make the decision for you.',
      ),
    ],
    'r4': [
      QuizQuestion(
        prompt: 'Volume measures…',
        options: [
          'How much was traded in a period',
          'The size of the price change',
          'The bid-ask spread',
          'The number of indicators on screen',
        ],
        correctIndex: 0,
        explanation:
            'Volume is the fuel gauge — it tells you how much conviction is '
            'behind a move.',
      ),
      QuizQuestion(
        prompt: 'A price move on high volume…',
        options: [
          'Is backed by real conviction',
          'Is always a fake-out',
          'Should be ignored',
          'Means low liquidity',
        ],
        correctIndex: 0,
        explanation:
            'The same move on low volume is often a fake-out that reverses.',
      ),
      QuizQuestion(
        prompt: 'A breakout is more trustworthy when…',
        options: [
          'Volume spikes',
          'Volume is very low',
          'RSI is exactly 50',
          'There is no news',
        ],
        correctIndex: 0,
        explanation:
            'Low-volume breakouts often fail; a volume spike shows real '
            'participation behind the move.',
      ),
    ],

    // ── Thinking Like a Pro ────────────────────────────────────────
    'p1': [
      QuizQuestion(
        prompt: "A trading plan's main job is to…",
        options: [
          'Move decisions from your emotional brain to your rational one',
          'Guarantee profits',
          'Pick the hottest coin',
          'Replace stop-losses',
        ],
        correctIndex: 0,
        explanation:
            'Decide everything in advance so the calm you — not the panicked you '
            '— makes the calls.',
      ),
      QuizQuestion(
        prompt: 'Which belongs in a trading plan?',
        options: [
          'How much you risk per trade and per day',
          'Your favourite colour',
          "The exchange's logo",
          "Other traders' opinions",
        ],
        correctIndex: 0,
        explanation:
            'Markets, timeframes, entry rules, stop/target, risk limits and a '
            'daily stop all belong in the plan.',
      ),
      QuizQuestion(
        prompt: 'A written plan turns trading from…',
        options: [
          'Reacting into executing',
          'Executing into reacting',
          'Winning into losing',
          'Investing into gambling',
        ],
        correctIndex: 0,
        explanation:
            'With rules written once, you execute a plan instead of reacting in '
            'the moment.',
      ),
    ],
    'p2': [
      QuizQuestion(
        prompt: 'Most traders lose mainly because…',
        options: [
          "They can't follow their own rules",
          'Their analysis is always wrong',
          'Markets are rigged against them',
          'They use stop-losses',
        ],
        correctIndex: 0,
        explanation:
            'Discipline beats intelligence — an edge is useless if you can\'t '
            'follow it.',
      ),
      QuizQuestion(
        prompt: 'Fear typically makes traders…',
        options: [
          'Cut winning trades too early',
          'Hold winners forever',
          'Size down sensibly',
          'Follow the plan perfectly',
        ],
        correctIndex: 0,
        explanation:
            'Fear cuts winners short; greed holds losers too long and over-sizes.',
      ),
      QuizQuestion(
        prompt: '"Revenge trading" is…',
        options: [
          'The urge to win back a loss immediately',
          'A disciplined, planned strategy',
          'A type of limit order',
          'Closing a trade at your target',
        ],
        correctIndex: 0,
        explanation:
            'The urge to instantly win it back is powerful and destructive — a '
            'hard daily stop is the fix.',
      ),
    ],
    'p3': [
      QuizQuestion(
        prompt: 'A strategy is…',
        options: [
          'A trading idea written as precise, repeatable rules',
          'A vague hunch',
          'A single indicator',
          'A guaranteed win',
        ],
        correctIndex: 0,
        explanation:
            'Vague ideas can\'t be tested; rules can. That\'s what makes it a '
            'strategy.',
      ),
      QuizQuestion(
        prompt: 'Why must an idea become rules?',
        options: [
          "Vague ideas can't be tested; rules can",
          "It's required by law",
          'It makes trading slower',
          'To impress other traders',
        ],
        correctIndex: 0,
        explanation:
            "If you can't write it as rules, you can't test it — and untested "
            "means you're guessing.",
      ),
      QuizQuestion(
        prompt: "If you can't write your idea as rules, you're…",
        options: ['Guessing', 'Ready to go live', 'A professional', 'Backtesting'],
        correctIndex: 0,
        explanation:
            'Rules are the bridge from a hunch to something you can actually '
            'prove.',
      ),
    ],
    'p4': [
      QuizQuestion(
        prompt: 'Backtesting means…',
        options: [
          "Running your rules against historical data to see how they'd have performed",
          'Trading with real money as fast as possible',
          'Copying another trader',
          'Ignoring the past entirely',
        ],
        correctIndex: 0,
        explanation:
            'It answers "does this edge actually exist?" before you risk a cent.',
      ),
      QuizQuestion(
        prompt: '"Max drawdown" tells you…',
        options: [
          'The worst peak-to-valley drop',
          'The total number of trades',
          'The win rate',
          'The average winning trade',
        ],
        correctIndex: 0,
        explanation:
            'Max drawdown is the deepest fall from a high — the real question is '
            'whether you could stomach it.',
      ),
      QuizQuestion(
        prompt: '"Curve-fitting" is…',
        options: [
          'Tweaking rules until they look perfect on past data',
          'A reliable, durable edge',
          'A type of candlestick chart',
          'Proper risk management',
        ],
        correctIndex: 0,
        explanation:
            "A strategy tuned to history you've already seen is worthless on "
            'tomorrow.',
      ),
    ],

    // ── Added lessons ──────────────────────────────────────────────
    'f5': [
      QuizQuestion(
        prompt: 'What do studies of retail traders consistently find?',
        options: [
          'Most active retail traders make money',
          'Most active retail traders lose money, largely to costs, size and behaviour',
          'Results are evenly split between winners and losers',
          'Only people without charts lose money',
        ],
        correctIndex: 1,
        explanation:
            'Barber and Odean found the most active traders underperformed the '
            'least active, and a study of Brazilian day traders who persisted '
            '300+ days found almost all lost money.',
      ),
      QuizQuestion(
        prompt: 'In that Brazilian day-trading study, what did persistence achieve?',
        options: [
          'It turned most losers into winners over time',
          'It made no meaningful difference — almost all still lost',
          'It guaranteed profitability after one year',
          'It was never measured',
        ],
        correctIndex: 1,
        explanation:
            'Trading for longer did not fix the outcome. Method and discipline '
            'have to change, not just the number of hours.',
      ),
      QuizQuestion(
        prompt: 'Of the four main reasons traders lose, how many are about market knowledge?',
        options: [
          'All four',
          'Three of the four',
          'Only one — the rest are costs, size and behaviour',
          'None of them',
        ],
        correctIndex: 2,
        explanation:
            'Costs, position size and behaviour account for three of the four. '
            'That is why this Academy spends more time on them than on patterns.',
      ),
    ],
    't5': [
      QuizQuestion(
        prompt: 'When is a trading fee charged?',
        options: [
          'Only when you make a profit',
          'Only when you open a position',
          'On the way in and again on the way out, win or lose',
          'Once a month, as a subscription',
        ],
        correctIndex: 2,
        explanation:
            'Both the opening and the closing fill are charged, regardless of '
            'whether the trade made money.',
      ),
      QuizQuestion(
        prompt: 'At 0.075% a side, roughly what does one round trip cost?',
        options: [
          'About 0.015%',
          'About 0.15%',
          'About 1.5%',
          'Nothing, if the trade wins',
        ],
        correctIndex: 1,
        explanation:
            'Two fills at 0.075% is about 0.15% of the position, before spread '
            'and slippage are counted.',
      ),
      QuizQuestion(
        prompt: 'Why is frequent trading especially expensive?',
        options: [
          'Exchanges raise the fee rate for active traders',
          'Cost is charged per trade, so trading more multiplies it',
          'Frequent traders always pick worse assets',
          'It is not — costs depend only on profit',
        ],
        correctIndex: 1,
        explanation:
            'The cost is per trade, not per pound of profit. Ten round trips a '
            'day is roughly 1.5% of traded value a day in costs alone.',
      ),
    ],
    'r5': [
      QuizQuestion(
        prompt: 'You hold five long crypto positions, each risking 1%. What is your real risk?',
        options: [
          'Five separate, independent 1% risks',
          'Closer to a single 5% risk, because they move together',
          'Exactly 1%, because that is what you set per trade',
          'Zero, because holding several assets is diversification',
        ],
        correctIndex: 1,
        explanation:
            'Correlated assets fall together. The event that stops out one '
            'position stops out all five, on the same day.',
      ),
      QuizQuestion(
        prompt: 'What tends to happen to correlations during a market panic?',
        options: [
          'They break down, so assets move independently',
          'They rise — assets move as one, exactly when you need diversification',
          'They stay fixed, since correlation never changes',
          'They reverse, so assets move in opposite directions',
        ],
        correctIndex: 1,
        explanation:
            'Pairs that drift apart in calm markets tend to move together in a '
            'panic, which is when the diversification was supposed to help.',
      ),
      QuizQuestion(
        prompt: 'What does genuine diversification require?',
        options: [
          'Holding as many positions as possible',
          'Holding things that do not move together',
          'Holding five versions of the same trade',
          'Opening positions on different days',
        ],
        correctIndex: 1,
        explanation:
            'Holding five of the same thing is concentration with extra fees. '
            'Count risk by what moves together.',
      ),
    ],
    'p5': [
      QuizQuestion(
        prompt: 'What is expectancy?',
        options: [
          'The percentage of trades that win',
          '(win rate x average win) minus (loss rate x average loss)',
          'The largest winning trade you have had',
          'How confident you feel about a trade',
        ],
        correctIndex: 1,
        explanation:
            'It combines how often you win with how much you win and lose, '
            'giving what one trade is worth on average.',
      ),
      QuizQuestion(
        prompt: 'A strategy wins 70% of the time but winners are a third the size of losers. Is it profitable?',
        options: [
          'Yes — a 70% win rate is always profitable',
          'No — (0.70 x 0.33) - (0.30 x 1) is negative',
          'Yes, but only with leverage',
          'It cannot be calculated',
        ],
        correctIndex: 1,
        explanation:
            'It loses money while winning most of its trades. Win rate on its '
            'own is a vanity metric.',
      ),
      QuizQuestion(
        prompt: 'Can a strategy that is wrong 60% of the time make money?',
        options: [
          'No, never',
          'Yes, if its winners are large enough relative to its losers',
          'Only if it uses more indicators',
          'Only over a single trade',
        ],
        correctIndex: 1,
        explanation:
            'Wins 40% of the time with winners twice the size of losers gives '
            '(0.40 x 2) - (0.60 x 1) = +0.2. Profitable while mostly wrong.',
      ),
    ],
    'p6': [
      QuizQuestion(
        prompt: 'Roughly how many trades before you should believe an edge is real?',
        options: [
          'About 5',
          'About 10',
          '100 or more, and treat under 30 as a story rather than evidence',
          'Sample size does not matter if the win rate is high',
        ],
        correctIndex: 2,
        explanation:
            'Even at 100 trades a measured 55% win rate is consistent with a '
            'true rate from the mid-forties to the mid-sixties.',
      ),
      QuizQuestion(
        prompt: 'With a genuine 45% win rate, how unusual is a run of six losses?',
        options: [
          'It should never happen',
          'It is normal — roughly once every sixty trades',
          'It proves the strategy has stopped working',
          'It only happens with a losing strategy',
        ],
        correctIndex: 1,
        explanation:
            'That is what a 45% win rate looks like from the inside. Abandoning '
            'a working strategy during one is a common, expensive mistake.',
      ),
      QuizQuestion(
        prompt: 'Why do small samples make curve-fitting easy to miss?',
        options: [
          'They contain too many trades to review',
          'Tuning rules to fit 20 historical trades memorises coincidences, not an edge',
          'They always show losses',
          'They cannot be backtested',
        ],
        correctIndex: 1,
        explanation:
            'A strategy tuned until it looks perfect over a handful of trades '
            'has learned that stretch of history, not the market.',
      ),
    ],
  };
}

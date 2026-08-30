import '../models/academy_models.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';

/// The Volex Trading Academy curriculum.
///
/// Written to take a complete beginner from "I don't know what a candle is" to
/// "I can build and test a strategy on paper" — in plain language, with the
/// risk-first mindset that keeps real traders alive. No hype, no get-rich
/// promises. Everything here is educational and practised risk-free.
class AcademyCurriculum {
  AcademyCurriculum._();

  /// Flat, ordered list of every lesson across all modules — used to compute
  /// "next lesson" and overall progress.
  static List<Lesson> get allLessons =>
      modules.expand((m) => m.lessons).toList();

  static int get totalLessons => allLessons.length;

  static const List<AcademyModule> modules = [
    // ────────────────────────────────────────────────────────────────
    AcademyModule(
      id: 'foundations',
      title: 'Trading Foundations',
      subtitle: 'Start here. The words and ideas everything else builds on.',
      emoji: '🌱',
      level: 'Beginner',
      accent: VxColors.neonGreen,
      lessons: [
        Lesson(
          id: 'f1',
          title: 'What trading actually is',
          summary: 'Trading vs investing vs gambling — and where you fit.',
          minutes: 3,
          blocks: [
            LessonBlock.paragraph(
                'Trading is buying something with the goal of selling it later at a '
                'different price. That\'s it. If you buy Bitcoin at \$60,000 hoping '
                'to sell it at \$62,000, you\'re trading.'),
            LessonBlock.heading('Trading vs investing'),
            LessonBlock.paragraph(
                'Investors buy and hold for years, betting on long-term growth. '
                'Traders act over minutes, hours, or days, trying to profit from '
                'shorter price moves. Neither is "better" — they\'re different jobs '
                'with different skills.'),
            LessonBlock.heading('The line between trading and gambling'),
            LessonBlock.paragraph(
                'A gambler bets on a feeling and hopes. A trader follows a plan with '
                'defined risk, and accepts that any single trade can lose. The '
                'difference isn\'t whether you win or lose one trade — it\'s whether '
                'you have an edge and control your losses over many trades.'),
            LessonBlock.tip(
                'This app exists so you can build that skill with \$0 at risk. Treat '
                'every paper trade as if it were real money — that\'s how the habit '
                'forms.'),
            LessonBlock.keyTakeaway(
                'Trading is a skill of managing probabilities and risk — not a '
                'lottery ticket.'),
          ],
        ),
        Lesson(
          id: 'f2',
          title: 'How prices move',
          summary: 'Buyers, sellers, and the tug-of-war that sets price.',
          minutes: 3,
          blocks: [
            LessonBlock.paragraph(
                'A price is simply the point where a buyer and a seller agree to '
                'trade right now. When more people want to buy than sell, price '
                'rises. When more want to sell, it falls.'),
            LessonBlock.bullets([
              'Bid = the highest price a buyer will pay right now.',
              'Ask = the lowest price a seller will accept right now.',
              'Spread = the small gap between them.',
              'Liquidity = how easily you can trade without moving the price.',
            ]),
            LessonBlock.paragraph(
                'Every green candle you\'ll ever see is buyers winning that '
                'tug-of-war for a moment. Every red candle is sellers winning. '
                'Trading is reading which side is stronger and for how long.'),
            LessonBlock.keyTakeaway(
                'Price is a live vote between buyers and sellers — nothing more '
                'mystical than that.'),
          ],
        ),
        Lesson(
          id: 'f3',
          title: 'Reading a candlestick',
          summary: 'The single most important chart skill.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'A candlestick packs four prices into one shape for a slice of time '
                '(a minute, an hour, a day):'),
            LessonBlock.bullets([
              'Open — the price when the period started.',
              'Close — the price when it ended.',
              'High — the highest price reached.',
              'Low — the lowest price reached.',
            ]),
            LessonBlock.paragraph(
                'The thick part is the "body" (open-to-close). The thin lines are '
                '"wicks" (the extremes). Green usually means close was higher than '
                'open; red means it closed lower.'),
            LessonBlock.heading('Why wicks matter'),
            LessonBlock.paragraph(
                'A long wick shows price tried to go somewhere and got rejected. A '
                'long lower wick means buyers stepped in hard at the lows — often a '
                'sign of support. Learning to read wicks is half of chart reading.'),
            LessonBlock.tryIt(
                text:
                    'Open a live chart and watch a single candle form in real time. '
                    'It clicks much faster when you see it move.',
                label: 'Open a live chart',
                route: '/chart?symbol=BTCUSDT'),
            LessonBlock.keyTakeaway(
                'One candle = four prices (open, high, low, close) telling a tiny '
                'story of a fight between buyers and sellers.'),
          ],
        ),
        Lesson(
          id: 'f4',
          title: 'The rule that keeps you alive',
          summary: 'Risk management, before anything else.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'Here is the uncomfortable truth every professional learned the hard '
                'way: you will be wrong, a lot. Great traders are wrong 40-60% of the '
                'time. They still make money because they lose small and win bigger.'),
            LessonBlock.heading('The 1% rule'),
            LessonBlock.paragraph(
                'Never risk more than about 1% of your account on a single trade. On '
                'a \$10,000 account, that\'s \$100 of risk per trade. Do that and no '
                'single loss — or even ten in a row — can wipe you out.'),
            LessonBlock.warning(
                'The fastest way to blow up an account is not "bad analysis". It\'s '
                'risking too much on one trade and being unable to recover.'),
            LessonBlock.keyTakeaway(
                'Protect your capital first. You can\'t trade tomorrow if you blow '
                'up today.'),
          ],
        ),
      ],
    ),

    // ────────────────────────────────────────────────────────────────
    AcademyModule(
      id: 'first-trades',
      title: 'Your First Trades',
      subtitle: 'Place real orders — with virtual money.',
      emoji: '🎮',
      level: 'Beginner',
      accent: VxColors.neonCyan,
      lessons: [
        Lesson(
          id: 't1',
          title: 'Market vs limit orders',
          summary: 'The two ways to get into a trade.',
          minutes: 3,
          blocks: [
            LessonBlock.paragraph(
                'When you decide to buy or sell, you choose HOW your order fills:'),
            LessonBlock.bullets([
              'Market order — fill me right now at the best available price. '
                  'Fast, but you accept whatever price you get.',
              'Limit order — only fill me at this price or better. You control '
                  'the price, but it may never fill.',
            ]),
            LessonBlock.tip(
                'Beginners often over-use market orders and pay the spread every '
                'time. Practising limit orders builds patience and better entries.'),
            LessonBlock.keyTakeaway(
                'Market = speed. Limit = price control. Choose based on what '
                'matters more for that trade.'),
          ],
        ),
        Lesson(
          id: 't2',
          title: 'Stop-loss & take-profit',
          summary: 'Decide where you\'re wrong before you enter.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'A stop-loss automatically closes your trade if price moves against '
                'you past a set point. A take-profit closes it when you reach your '
                'target. Together they turn a trade into a plan instead of a hope.'),
            LessonBlock.heading('Set them BEFORE you enter'),
            LessonBlock.paragraph(
                'The moment to decide "where am I wrong?" is before you\'re in the '
                'trade and emotional. Once you\'re in and losing, your brain will '
                'invent reasons to move the stop. Don\'t. That\'s how small losses '
                'become account-killing ones.'),
            LessonBlock.warning(
                'A trade without a stop-loss is not a trade — it\'s an open-ended '
                'bet on your ego.'),
            LessonBlock.tryIt(
                text:
                    'Open the trade ticket and set one. Stop loss and take '
                    'profit are on by default: you\'ll see the price levels, '
                    'what you risk in dollars, and your reward-to-risk ratio '
                    'before you commit — and the simulator closes the position '
                    'for you when either level is reached.',
                label: 'Set a stop on a paper trade',
                route: '/chart?symbol=BTCUSDT'),
            LessonBlock.keyTakeaway(
                'Every trade needs a pre-planned exit for both being wrong (stop) '
                'and being right (target).'),
          ],
        ),
        Lesson(
          id: 't3',
          title: 'How much should you risk?',
          summary: 'Position sizing made simple.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'Position size is how many units you buy. It should come from your '
                'risk, not your excitement. Here\'s the simple formula:'),
            LessonBlock.bullets([
              'Decide your risk per trade (e.g. 1% = \$100 on a \$10k account).',
              'Measure the distance to your stop-loss (e.g. \$50 below entry).',
              'Position size = risk ÷ stop distance. Here: \$100 ÷ \$50 = 2 units.',
            ]),
            LessonBlock.paragraph(
                'Notice you never asked "how much do I want to make?" You start from '
                '"how much can I lose?" and size backwards. That one reversal in '
                'thinking separates survivors from gamblers.'),
            LessonBlock.tryIt(
                text:
                    'The trade ticket does this arithmetic for you. Set a stop, '
                    'then tap "Risk 1%" — it sizes the position with exactly '
                    'this formula, so you can watch the number change as you '
                    'move the stop.',
                label: 'Try risk-based sizing',
                route: '/chart?symbol=BTCUSDT'),
            LessonBlock.keyTakeaway(
                'Let your stop-loss decide your position size — not your hopes.'),
          ],
        ),
        Lesson(
          id: 't4',
          title: 'Place your first paper trade',
          summary: 'Put it all together, risk-free.',
          minutes: 3,
          blocks: [
            LessonBlock.paragraph(
                'You now know enough to place a real, structured trade with virtual '
                'money. Here\'s your checklist:'),
            LessonBlock.bullets([
              'Pick a direction and a reason (not just a feeling).',
              'Set a stop-loss where your idea would be proven wrong.',
              'Set a take-profit at a sensible target.',
              'Size the position so you only risk ~1%.',
            ]),
            LessonBlock.tryIt(
                text:
                    'Open the chart and place a paper trade with a stop and target. '
                    'Nothing here risks real money — this is your practice range.',
                label: 'Place a paper trade',
                route: '/chart?symbol=BTCUSDT'),
            LessonBlock.keyTakeaway(
                'A complete trade = direction + reason + stop + target + correct '
                'size. Do all five, every time.'),
          ],
        ),
      ],
    ),

    // ────────────────────────────────────────────────────────────────
    AcademyModule(
      id: 'reading-markets',
      title: 'Reading the Market',
      subtitle: 'Turn a chart from noise into information.',
      emoji: '📈',
      level: 'Intermediate',
      accent: VxColors.neonPurple,
      lessons: [
        Lesson(
          id: 'r1',
          title: 'Support & resistance',
          summary: 'The floors and ceilings price respects.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'Support is a price level where buyers have repeatedly stepped in — '
                'a "floor". Resistance is where sellers keep showing up — a '
                '"ceiling". Price tends to bounce between them until one breaks.'),
            LessonBlock.paragraph(
                'They matter because they\'re where other traders place orders. A '
                'level isn\'t magic; it\'s memory. Lots of people remember that '
                'price and act around it, which makes it self-reinforcing.'),
            LessonBlock.tip(
                'When support finally breaks, it often becomes resistance (and vice '
                'versa). Old floors become new ceilings.'),
            LessonBlock.keyTakeaway(
                'Support and resistance are crowd memory — levels where past '
                'battles were fought.'),
          ],
        ),
        Lesson(
          id: 'r2',
          title: 'Trends & trendlines',
          summary: 'The trend is your friend — until it bends.',
          minutes: 3,
          blocks: [
            LessonBlock.paragraph(
                'An uptrend is a series of higher highs and higher lows. A downtrend '
                'is lower highs and lower lows. Sideways ("range") is neither.'),
            LessonBlock.paragraph(
                'Trading with the trend puts the odds on your side. Fighting a '
                'strong trend ("catching a falling knife") is where beginners lose '
                'the most.'),
            LessonBlock.keyTakeaway(
                'Identify the trend first. Trade with it unless you have a strong, '
                'specific reason not to.'),
          ],
        ),
        Lesson(
          id: 'r3',
          title: 'Moving averages & RSI',
          summary: 'Your first two indicators.',
          minutes: 4,
          blocks: [
            LessonBlock.heading('Moving averages (MA)'),
            LessonBlock.paragraph(
                'A moving average smooths price into a single line — the average of '
                'the last N candles. When price is above a rising MA, the trend is '
                'generally up. MAs help you see the forest instead of every tree.'),
            LessonBlock.heading('RSI (Relative Strength Index)'),
            LessonBlock.paragraph(
                'RSI is a 0-100 gauge of momentum. Above ~70 is often called '
                '"overbought", below ~30 "oversold". But beware: in a strong trend, '
                'RSI can stay overbought for a long time. It\'s a hint, not a '
                'command.'),
            LessonBlock.warning(
                'No indicator predicts the future. They summarise the past. Use them '
                'to confirm an idea, never as a crystal ball.'),
            LessonBlock.keyTakeaway(
                'Indicators describe momentum and trend — they support decisions, '
                'they don\'t make them.'),
          ],
        ),
        Lesson(
          id: 'r4',
          title: 'Volume: the fuel gauge',
          summary: 'Moves that mean something have volume behind them.',
          minutes: 3,
          blocks: [
            LessonBlock.paragraph(
                'Volume is how much was traded in a period. A price move on high '
                'volume is backed by real conviction. The same move on low volume is '
                'often a fake-out that reverses.'),
            LessonBlock.tip(
                'Breakouts through resistance are far more trustworthy when volume '
                'spikes. Low-volume breakouts often fail.'),
            LessonBlock.keyTakeaway(
                'Price tells you WHAT happened; volume tells you how much to believe '
                'it.'),
          ],
        ),
      ],
    ),

    // ────────────────────────────────────────────────────────────────
    AcademyModule(
      id: 'pro-mindset',
      title: 'Thinking Like a Pro',
      subtitle: 'The habits that outlast any single trade.',
      emoji: '🧠',
      level: 'Intermediate',
      accent: VxColors.neonYellow,
      lessons: [
        Lesson(
          id: 'p1',
          title: 'Build a trading plan',
          summary: 'Rules you write once and follow always.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'A trading plan is a short written document that answers, in advance, '
                'every decision you\'ll face in the heat of the moment:'),
            LessonBlock.bullets([
              'What markets and timeframes do I trade?',
              'What has to be true for me to enter?',
              'Where is my stop and target?',
              'How much do I risk per trade and per day?',
              'When do I stop for the day (win or lose)?',
            ]),
            LessonBlock.paragraph(
                'The plan\'s job is to take decisions away from your emotional, '
                'in-the-moment brain and give them to your calm, rational one.'),
            LessonBlock.keyTakeaway(
                'A written plan turns trading from reacting into executing.'),
          ],
        ),
        Lesson(
          id: 'p2',
          title: 'Fear, greed & discipline',
          summary: 'The real opponent is in the mirror.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'Most people don\'t lose because their analysis is bad. They lose '
                'because they can\'t follow their own rules. Fear makes you cut '
                'winners early; greed makes you hold losers too long and over-size.'),
            LessonBlock.heading('Revenge trading'),
            LessonBlock.paragraph(
                'After a loss, the urge to "win it back" immediately is powerful and '
                'destructive. This app\'s trade checks are built to catch exactly this '
                'pattern — but the real fix is awareness and a hard daily stop.'),
            LessonBlock.tip(
                'Journal every trade with why you entered and how you felt. Patterns '
                'in your behaviour become obvious — and fixable.'),
            LessonBlock.tryIt(
                text:
                    'The journal is built in. Tag each entry with how you felt '
                    '— it counts how often you traded while anxious, greedy or '
                    'chasing a loss, which is exactly the pattern this lesson '
                    'is about.',
                label: 'Open your trading journal',
                route: '/journal'),
            LessonBlock.keyTakeaway(
                'Discipline beats intelligence in trading. The edge is useless if '
                'you can\'t follow it.'),
          ],
        ),
        Lesson(
          id: 'p3',
          title: 'From idea to strategy',
          summary: 'Turn a hunch into rules you can test.',
          minutes: 3,
          blocks: [
            LessonBlock.paragraph(
                'A strategy is just a trading idea written as precise, repeatable '
                'rules: "Buy when the 50-MA crosses above the 200-MA, stop below the '
                'recent low, target twice my risk." Vague ideas can\'t be tested; '
                'rules can.'),
            LessonBlock.tryIt(
                text:
                    'Take a ready-made template and change one number at a '
                    'time, so you can see what each rule does.',
                label: 'Open Strategy Studio',
                route: '/simulator/templates'),
            LessonBlock.keyTakeaway(
                'If you can\'t write your idea as rules, you can\'t test it — and if '
                'you can\'t test it, you\'re guessing.'),
          ],
        ),
        Lesson(
          id: 'p4',
          title: 'Backtest before you risk',
          summary: 'Proof beats opinion.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'Backtesting runs your strategy\'s rules against years of real '
                'historical data to see how it would have performed — before you '
                'risk a cent. It answers "does this edge actually exist?"'),
            LessonBlock.bullets([
              'Win rate — how often it wins.',
              'Average win vs average loss — the size of each.',
              'Max drawdown — the worst peak-to-valley drop (can you stomach it?).',
              'Number of trades — enough to trust the result?',
            ]),
            LessonBlock.warning(
                'Beware "curve-fitting": tweaking rules until they look perfect on '
                'the past. A strategy that only works on history you\'ve already '
                'seen is worthless on tomorrow.'),
            LessonBlock.tryIt(
                text:
                    'Run a strategy through the Backtest Lab against real market '
                    'history and read its stats.',
                label: 'Open the Backtest Lab',
                route: '/lab'),
            LessonBlock.keyTakeaway(
                'Test on the past and practise on paper until the edge is proven. '
                'Only then does real money make sense.'),
          ],
        ),
      ],
    ),
  ];
}

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
        Lesson(
          id: 'f5',
          title: 'The odds you\'re up against',
          summary: 'What actually happens to most people who try this.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'Before you learn anything else, you should know the base rate — '
                'what happens to the average person who does this. Most trading '
                'education skips it. We think skipping it is how people end up '
                'surprised by an outcome that was the most likely one all along.'),
            LessonBlock.heading('What the research says'),
            LessonBlock.paragraph(
                'Studies of retail trading are consistent and unflattering. Barber '
                'and Odean\'s work on tens of thousands of brokerage accounts found '
                'that the most active traders underperformed the least active ones '
                'by a wide margin, largely through costs and overtrading. A study '
                'of Brazilian day traders by Chague and colleagues followed people '
                'who persisted for 300 days or more and found almost all of them '
                'lost money.'),
            LessonBlock.warning(
                'Read that again: persistence alone did not fix it. Trading longer '
                'did not turn losers into winners. Something else has to change, '
                'and that something is method and discipline.'),
            LessonBlock.heading('Why so many lose'),
            LessonBlock.bullets([
              'Costs — every trade pays a fee and a spread, and frequent trading '
                  'pays them over and over.',
              'Size — one oversized position undoes months of careful work.',
              'Behaviour — cutting winners early, holding losers, and revenge '
                  'trading after a loss.',
              'No edge — trading on feelings rather than a rule that has been '
                  'tested.',
            ]),
            LessonBlock.paragraph(
                'Notice that only the last one is about market knowledge. Three of '
                'the four are about cost control and self-control, which is exactly '
                'why this Academy spends more time on those than on chart patterns.'),
            LessonBlock.tip(
                'This is not a reason to give up. It is a reason to be honest about '
                'what you are attempting: you are trying to be in a minority. Anyone '
                'who tells you it is easy is selling you something.'),
            LessonBlock.keyTakeaway(
                'Most active retail traders lose money, mostly to costs, size and '
                'their own behaviour. Knowing the base rate is what lets you set out '
                'to beat it instead of assuming you already have.'),
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
        Lesson(
          id: 't5',
          title: 'What a trade actually costs',
          summary: 'The quiet tax that decides most outcomes.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'Every trade costs you something before the market has moved at '
                'all. Three things, each small, and all of them charged whether '
                'you win or lose.'),
            LessonBlock.bullets([
              'Fee — a percentage of the trade\'s value, charged when you open '
                  'and again when you close. Volex applies 0.075%, in line with a '
                  'typical crypto exchange.',
              'Spread — buyers bid slightly below what sellers ask, and a market '
                  'order crosses that gap.',
              'Slippage — the price moves between pressing the button and the '
                  'order filling.',
            ]),
            LessonBlock.heading('Do the arithmetic once'),
            LessonBlock.paragraph(
                'At 0.075% a side, a round trip costs roughly 0.15% of the position '
                'before spread and slippage. That sounds like nothing. Now suppose '
                'you are trading small moves and aiming for 0.3% a time: you are '
                'handing over about half your gross profit on every winner, and '
                'still paying the full cost on every loser.'),
            LessonBlock.paragraph(
                'Scale it up. Ten round trips a day is about 1.5% of your traded '
                'value a day in costs alone. You do not need to be wrong to lose '
                'money at that rate — you only need to be average.'),
            LessonBlock.warning(
                'This is the main reason frequent trading is dangerous, and it is '
                'usually invisible: the fee never feels like a loss, because it '
                'never appears as a losing trade.'),
            LessonBlock.tip(
                'A strategy that only works when you ignore costs does not work. '
                'Fewer, larger, better-chosen trades beat many small ones, because '
                'the cost is charged per trade, not per pound of profit.'),
            LessonBlock.tryIt(
                text:
                    'Place a paper trade and close it straight away without '
                    'waiting for a move. Your balance will be slightly lower '
                    'than it started. That difference is the cost, and Volex '
                    'charges it exactly like an exchange would.',
                label: 'See the cost for yourself',
                route: '/chart?symbol=BTCUSDT'),
            LessonBlock.keyTakeaway(
                'Costs are charged per trade, win or lose. Trading more often '
                'multiplies them, which is why frequency is the most expensive '
                'habit in trading.'),
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
        Lesson(
          id: 'r5',
          title: 'When five trades are really one',
          summary: 'Correlation, and the risk you did not know you took.',
          minutes: 3,
          blocks: [
            LessonBlock.paragraph(
                'You have learned to risk about 1% per trade. Now suppose you open '
                'five positions, each risking 1%, all of them long crypto. You have '
                'not taken five separate 1% risks. You have taken something much '
                'closer to one 5% risk wearing five different names.'),
            LessonBlock.heading('Why'),
            LessonBlock.paragraph(
                'Bitcoin, Ethereum and most large altcoins move together most of '
                'the time. When the market drops hard, it drops on all of them at '
                'once. The thing that would stop out one of your positions is the '
                'same thing that stops out all five, on the same afternoon.'),
            LessonBlock.paragraph(
                'Assets that move together are called correlated. Correlation is '
                'not fixed — pairs that drift apart in calm markets tend to move '
                'as one during a panic, which is precisely when you need the '
                'diversification you thought you had.'),
            LessonBlock.warning(
                'Diversification means holding things that do not move together. '
                'Holding five of the same thing is concentration with extra fees.'),
            LessonBlock.tip(
                'Count your risk by what moves together, not by how many tickets '
                'you opened. If a single bad day would hit every open position, add '
                'up their risk and treat the total as one number.'),
            LessonBlock.tryIt(
                text:
                    'Open the portfolio and look at your open positions. Ask '
                    'yourself which of them would still be fine if crypto fell '
                    '10% tomorrow. If the answer is none, that is your real '
                    'position size.',
                label: 'Review your open positions',
                route: '/portfolio'),
            LessonBlock.keyTakeaway(
                'Risk adds up across positions that move together. Five correlated '
                '1% trades is one 5% trade.'),
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
        Lesson(
          id: 'p5',
          title: 'Does this actually make money?',
          summary: 'Expectancy — the one number that answers it.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'You know your win rate. You know your reward-to-risk. Neither one '
                'tells you whether a strategy makes money, and that surprises most '
                'people. You need both, combined, and the combination has a name: '
                'expectancy.'),
            LessonBlock.heading('The formula'),
            LessonBlock.paragraph(
                'Expectancy = (win rate x average win) minus (loss rate x average '
                'loss). It tells you what one trade is worth on average, over many '
                'trades. Positive means the strategy makes money; negative means it '
                'loses, however good it feels.'),
            LessonBlock.heading('Two examples that flip the intuition'),
            LessonBlock.bullets([
              'Wins 40% of the time, winners are twice the size of losers: '
                  '(0.40 x 2) - (0.60 x 1) = +0.2. Profitable, while being wrong '
                  'six times out of ten.',
              'Wins 70% of the time, winners are half the size of losers: '
                  '(0.70 x 0.5) - (0.30 x 1) = +0.05. Barely profitable, despite '
                  'feeling excellent.',
              'Wins 70% of the time, winners are a third the size of losers: '
                  '(0.70 x 0.33) - (0.30 x 1) = -0.07. Loses money while winning '
                  'most of its trades.',
            ]),
            LessonBlock.warning(
                'That last one is the trap. A high win rate feels like skill and '
                'reads well in a screenshot, but a strategy that wins small and '
                'loses big can lose money at a 70% win rate. Win rate on its own '
                'is a vanity metric.'),
            LessonBlock.paragraph(
                'Expectancy is per trade, so your result is roughly expectancy '
                'multiplied by the number of trades — minus costs, which is why the '
                'previous lesson matters here. A tiny positive expectancy can be '
                'turned negative by fees alone.'),
            LessonBlock.tryIt(
                text:
                    'Run a backtest and look at win rate, average win and average '
                    'loss together rather than one at a time. Profit factor on '
                    'that screen is the same idea in a different form: gross '
                    'profit divided by gross loss.',
                label: 'Read a backtest properly',
                route: '/lab'),
            LessonBlock.keyTakeaway(
                'Win rate and reward-to-risk mean nothing apart. Expectancy '
                'combines them, and only a positive one makes money.'),
          ],
        ),
        Lesson(
          id: 'p6',
          title: 'How many trades before you believe it?',
          summary: 'Small samples lie, in both directions.',
          minutes: 4,
          blocks: [
            LessonBlock.paragraph(
                'The backtest lesson asked whether you had enough trades to trust a '
                'result. Here is the answer, and it is larger than most people '
                'expect.'),
            LessonBlock.heading('Why ten trades tells you nothing'),
            LessonBlock.paragraph(
                'Flip a fair coin ten times and getting seven heads is entirely '
                'ordinary — it happens about one run in six. If you judged the coin '
                'on that, you would conclude it was biased. Ten trades is exactly '
                'the same situation, except you have money and ego attached to the '
                'conclusion.'),
            LessonBlock.paragraph(
                'As a working rule, treat anything under about 30 trades as a story '
                'rather than evidence, and prefer 100 or more before you believe an '
                'edge is real. Even then the uncertainty is wide — a measured 55% '
                'win rate over 100 trades is consistent with a true rate anywhere '
                'from the mid-forties to the mid-sixties.'),
            LessonBlock.heading('Losing streaks are normal'),
            LessonBlock.paragraph(
                'This cuts the other way too. With a genuine 45% win rate, a run of '
                'six losses in a row will happen regularly — roughly once every '
                'sixty trades. It is not a sign your strategy has broken. It is '
                'what a 45% win rate looks like from the inside, and abandoning a '
                'working strategy during one is a common and expensive mistake.'),
            LessonBlock.warning(
                'Small samples are also how curve-fitting hides. Tune a strategy '
                'until it looks perfect over 20 historical trades and you have '
                'memorised twenty coincidences, not found an edge.'),
            LessonBlock.tryIt(
                text:
                    'Check the trade count on any backtest before you read its '
                    'other numbers. If it is small, the win rate and profit '
                    'factor are noise dressed up as findings.',
                label: 'Check a backtest\'s sample size',
                route: '/lab'),
            LessonBlock.keyTakeaway(
                'Judge a strategy on many trades, not a few. Small samples flatter '
                'bad strategies and condemn good ones.'),
          ],
        ),
      ],
    ),
  ];
}

import '../../models/daily_models.dart';

/// Foundations: what a market is, what the odds actually are, and the claims
/// a beginner meets before they ever place a trade.
///
/// These are the questions whose answers decide whether someone approaches
/// trading as a skill to be built slowly or as a way to get rich by Friday.
/// The base rates in particular are uncomfortable, and stating them plainly is
/// the most useful thing an educational app can do.
class FoundationsBank {
  FoundationsBank._();

  static const List<DailyCall> calls = [
    DailyCall(
      id: 'fo_base_rate',
      prompt: 'Across large studies of retail day traders, what share are '
          'profitable over a multi-year period?',
      context: 'Brazilian futures, Taiwanese equities, and others.',
      optionA: 'A small minority',
      optionB: 'Around half',
      correctIsA: true,
      explanation:
          'Chague and co-authors found almost no day traders in their sample '
          'were consistently profitable over time. This is the number to hold '
          'in mind when anyone shows you their returns — and the reason to '
          'start with a simulator.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_zero_sum',
      prompt: 'In derivatives markets like futures, one trader\'s gain is:',
      context: 'Before costs.',
      optionA: 'Created by the market',
      optionB: 'Another trader\'s loss',
      correctIsA: false,
      explanation:
          'Derivatives are contracts between two parties, so they are zero-sum '
          'before fees and negative-sum after. Your profit has to come from '
          'someone, and increasingly that someone is a professional.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_who_else',
      prompt: 'Who is on the other side of your trade?',
      context: 'Realistically.',
      optionA: 'Often a firm with better data and lower costs',
      optionB: 'Usually another beginner',
      correctIsA: true,
      explanation:
          'Much of the volume in liquid markets comes from professional '
          'market makers and funds. That is not a reason not to participate, '
          'but it should end any idea that you are competing with people like '
          'you.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_price_meaning',
      prompt: 'What is a market price, fundamentally?',
      context: 'At any instant.',
      optionA: 'What something is worth',
      optionB: 'The price at which a buyer and a seller last agreed',
      correctIsA: false,
      explanation:
          'Price is an agreement, not a valuation. It reflects what the '
          'marginal buyer and seller could settle on, which may be far from '
          'anything anyone would call fair value.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_expected_value',
      prompt: 'A bet wins \$10 with 30% probability and loses \$3 with 70%. '
          'Take it?',
      context: 'Repeatedly.',
      optionA: 'Yes — expectancy is +\$0.90',
      optionB: 'No, you lose most of the time',
      correctIsA: true,
      explanation:
          '(0.3 × 10) − (0.7 × 3) = 3 − 2.1 = +0.9. Losing most of the time is '
          'entirely compatible with making money, which is the single most '
          'important idea in trading and the least intuitive.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'fo_gamblers_fallacy',
      prompt: 'A coin lands heads five times. What is the chance of tails '
          'next?',
      context: 'A fair coin.',
      optionA: 'Higher than 50% — it is due',
      optionB: '50%',
      correctIsA: false,
      explanation:
          'The coin has no memory. Markets are not coins, but the same '
          'reasoning error shows up as "it has fallen five days, it must '
          'bounce" — which is a belief about fairness, not about the market.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'fo_small_numbers',
      prompt: 'Why are conclusions from a handful of trades unreliable?',
      context: 'Ten trades.',
      optionA: 'Random outcomes easily produce convincing patterns',
      optionB: 'They are not — ten is enough',
      correctIsA: true,
      explanation:
          'Small samples are dominated by noise, and noise makes shapes. '
          'People see trends in randomness readily, which is why a strategy '
          'can feel proven after a week and be nothing at all.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'fo_volatility_meaning',
      prompt: 'High volatility means what?',
      context: 'A volatile market.',
      optionA: 'Prices are going up fast',
      optionB: 'Large moves in both directions',
      correctIsA: false,
      explanation:
          'Volatility is size of movement, not direction. Conflating the two '
          'is why people take on far more risk in "exciting" markets than they '
          'intended — the same position is simply bigger in risk terms.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'fo_crypto_volatility',
      prompt: 'Compared with large stock indices, crypto is typically:',
      context: 'Daily moves.',
      optionA: 'Several times more volatile',
      optionB: 'About the same',
      correctIsA: true,
      explanation:
          'Moves that would be extraordinary in an index are an ordinary '
          'Tuesday in crypto. That means position sizes must be smaller for '
          'the same risk, not that opportunity is larger.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'fo_guaranteed_returns',
      prompt: 'Someone offers guaranteed 5% monthly returns. What is that?',
      context: 'Guaranteed.',
      optionA: 'An attractive opportunity',
      optionB: 'Almost certainly a fraud',
      correctIsA: false,
      explanation:
          '5% a month is roughly 80% a year, compounding, forever. Nobody who '
          'could do that would need your money, and "guaranteed" plus a return '
          'above risk-free is the defining signature of a Ponzi scheme.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_signal_seller',
      prompt: 'If someone\'s trading signals were reliably profitable, '
          'what would they do?',
      context: 'They are selling a subscription.',
      optionA: 'Trade them, quietly',
      optionB: 'Sell them to strangers',
      correctIsA: true,
      explanation:
          'Edges are finite and crowding them out destroys them. The business '
          'model of selling signals only makes sense if the subscriptions are '
          'worth more than the trading — which tells you what the trading is '
          'worth.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_leverage_ads',
      prompt: 'A platform advertises 100x leverage. What is it optimised for?',
      context: 'The offer.',
      optionA: 'Your returns',
      optionB: 'Their fee revenue from your turnover',
      correctIsA: false,
      explanation:
          'At 100x a 1% move liquidates you, so positions turn over '
          'constantly — and turnover is where the platform earns. The product '
          'is not a tool for you, it is a source of volume for them.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'fo_get_rich',
      prompt: 'A realistic timeframe to become consistently competent at '
          'trading?',
      context: 'Honest answer.',
      optionA: 'Years',
      optionB: 'A few weeks with the right course',
      correctIsA: true,
      explanation:
          'It is a skill with slow, noisy feedback — the hardest kind to '
          'learn. Anything promising competence in weeks is selling the hope, '
          'not the skill.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_passive_benchmark',
      prompt: 'What should any active strategy be compared against?',
      context: 'A baseline.',
      optionA: 'Zero',
      optionB: 'Buying and holding, doing nothing',
      correctIsA: false,
      explanation:
          'Beating zero is not an achievement when the alternative was sitting '
          'still and earning the market return. Active trading must clear that '
          'bar plus its own costs to have been worth the effort.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'fo_liquidity_why',
      prompt: 'Why does liquidity matter to a small trader?',
      context: '"I am tiny, it cannot matter."',
      optionA: 'It sets your spread and slippage on every trade',
      optionB: 'It does not at small size',
      correctIsA: true,
      explanation:
          'Even small orders pay the spread, and in illiquid markets that '
          'spread is enormous relative to any edge. Liquidity is a cost you '
          'pay whether or not you move the price.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'fo_market_cap',
      prompt: 'A coin is "cheap" at \$0.0001. Is that meaningful?',
      context: 'Low unit price.',
      optionA: 'Yes, more room to grow',
      optionB: 'No — supply determines what the price per unit means',
      correctIsA: false,
      explanation:
          'Price per unit is arbitrary without supply. A trillion tokens at '
          '\$0.0001 is a \$100m asset. The "cheap coin" intuition is one of the '
          'most reliably exploited misunderstandings in crypto.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_diversify_alts',
      prompt: 'Holding ten different altcoins. How diversified are you?',
      context: 'Ten names.',
      optionA: 'Much less than it looks — they move together',
      optionB: 'Well diversified',
      correctIsA: true,
      explanation:
          'Diversification requires assets that behave differently. Ten '
          'high-beta crypto assets in a drawdown are one position, and often a '
          'worse one than simply holding the largest.',
      lessonId: 'r5',
    ),
    DailyCall(
      id: 'fo_time_in_market',
      prompt: 'Missing the best few days of a long bull market typically '
          'does what to returns?',
      context: 'A well-documented effect.',
      optionA: 'Barely matters',
      optionB: 'Reduces them dramatically',
      correctIsA: false,
      explanation:
          'Returns cluster into a small number of days, and those days often '
          'sit right next to the worst ones. Being out during volatility means '
          'being out for both, which is the hidden cost of trying to time it.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'fo_news_speed',
      prompt: 'You read news on a major site. Can you trade it profitably?',
      context: 'It just published.',
      optionA: 'Rarely — algorithms priced it in seconds ago',
      optionB: 'Yes, you are early',
      correctIsA: true,
      explanation:
          'By the time information reaches a consumer news site it has been '
          'traded on. Retail news trading is usually buying from someone who '
          'knew first.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'fo_insider_edge',
      prompt: 'What edge can a retail trader realistically have?',
      context: 'Against faster, better-funded participants.',
      optionA: 'Speed',
      optionB: 'Patience — no obligation to trade',
      correctIsA: false,
      explanation:
          'You will never win on latency or data. You can wait indefinitely, '
          'take no position, and skip unattractive conditions — freedoms a '
          'fund with mandates does not have.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_compound_math',
      prompt: '1% a day compounded for a year is roughly what?',
      context: '~250 trading days.',
      optionA: 'Over a 1,000% gain — which is why it is implausible',
      optionB: 'About 250%',
      correctIsA: true,
      explanation:
          '1.01^250 is about 12x. When a claimed daily return compounds to '
          'something absurd, the claim is the problem. This arithmetic is the '
          'fastest way to identify a fantasy.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_survivorship_social',
      prompt: 'Why do trading results online look so much better than the '
          'research?',
      context: 'Everyone seems to win.',
      optionA: 'The research is outdated',
      optionB: 'Losers stop posting',
      correctIsA: false,
      explanation:
          'Visibility selects for success and for exaggeration. The average '
          'outcome is invisible by construction, because nobody screenshots a '
          'slow bleed.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_simulated_limits',
      prompt: 'Simulated results differ from real ones mainly because of:',
      context: 'The standard disclaimer.',
      optionA: 'Unmodelled costs and untested emotions',
      optionB: 'Nothing meaningful',
      correctIsA: true,
      explanation:
          'A simulator can model fees and slippage approximately and cannot '
          'model fear at all. Both gaps push in the same direction: real '
          'results are usually worse.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'fo_risk_free',
      prompt: 'An investment with no risk of loss and above-market returns:',
      context: 'Evaluating an offer.',
      optionA: 'Is rare but findable',
      optionB: 'Does not exist',
      correctIsA: false,
      explanation:
          'Return is compensation for risk. Anything offering more return '
          'with less risk either hides the risk or is a fraud, and the hidden '
          'risk usually appears all at once.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_stablecoin',
      prompt: 'A stablecoin is pegged to \$1. Is it risk-free?',
      context: 'It holds the peg.',
      optionA: 'No — pegs depend on reserves and have broken before',
      optionB: 'Yes, it is always \$1',
      correctIsA: true,
      explanation:
          'The peg is a promise backed by whatever the issuer holds. Several '
          'have broken, some to zero. "Stable" describes the intention, not a '
          'guarantee.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_custody',
      prompt: 'Coins held on an exchange are:',
      context: 'In your account balance.',
      optionA: 'Yours, in your wallet',
      optionB: 'A claim on the exchange, not coins you control',
      correctIsA: false,
      explanation:
          'You hold an entry in their database. Multiple large exchanges have '
          'failed and taken customer balances with them. This is why the '
          'phrase "not your keys, not your coins" exists.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_pump_group',
      prompt: 'A group promises coordinated buying to pump a coin. '
          'Where are you in that plan?',
      context: 'You were invited.',
      optionA: 'Among the people being sold to',
      optionB: 'Early, with the organisers',
      correctIsA: true,
      explanation:
          'Organisers accumulate before announcing and sell into the buying '
          'they created. If you heard about it, you are the exit liquidity — '
          'that is the whole mechanism.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_dca',
      prompt: 'Dollar-cost averaging mainly reduces what?',
      context: 'Buying fixed amounts regularly.',
      optionA: 'The chance of losing money',
      optionB: 'The risk of committing everything at a bad moment',
      correctIsA: false,
      explanation:
          'It spreads entry timing, which reduces timing risk, not market '
          'risk. If the asset falls for years you still lose — just less '
          'dramatically than if you had bought the top in one go.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'fo_holding_period',
      prompt: 'Longer holding periods tend to affect costs how?',
      context: 'Same capital.',
      optionA: 'Fewer transactions, so lower total cost drag',
      optionB: 'Higher costs from holding',
      correctIsA: true,
      explanation:
          'Costs scale with turnover, not time. Holding is cheap; trading is '
          'expensive. This is the mechanical reason patient strategies clear a '
          'lower bar to be profitable.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'fo_efficient',
      prompt: 'If markets were perfectly efficient, what would follow?',
      context: 'A thought experiment.',
      optionA: 'Prices would never move',
      optionB: 'No strategy could reliably beat holding, after costs',
      correctIsA: false,
      explanation:
          'Efficiency is about information being priced, not about stillness. '
          'Real markets are close enough to efficient that edges are small and '
          'temporary — which is a useful prior when evaluating any claim.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_why_edge_fades',
      prompt: 'Why do published trading edges tend to weaken?',
      context: 'Once written about.',
      optionA: 'Enough people trade them to remove the opportunity',
      optionB: 'Markets become more random',
      correctIsA: true,
      explanation:
          'An edge is a mispricing. Acting on it corrects it. Anything widely '
          'known has already been traded toward disappearance, which is why '
          'the best-documented patterns are often the weakest.',
      lessonId: 'f1',
    ),
    DailyCall(
      id: 'fo_regulation',
      prompt: 'Why do regulators restrict leverage for retail traders in '
          'many countries?',
      context: 'Caps on CFDs and similar.',
      optionA: 'To protect institutional profits',
      optionB: 'Because most retail accounts using it lose money',
      correctIsA: false,
      explanation:
          'Brokers in some jurisdictions must disclose the percentage of '
          'retail accounts that lose money; the figures are routinely between '
          '70 and 85%. The caps followed that data.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'fo_practice_value',
      prompt: 'What does practising in a simulator genuinely build?',
      context: 'Setting expectations.',
      optionA: 'Mechanics, process, and a record to learn from',
      optionB: 'Proof you will succeed live',
      correctIsA: true,
      explanation:
          'You can learn order types, sizing arithmetic and trade management '
          'without paying for the lesson. What remains untested is how you '
          'behave when the money is real.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'fo_learning_speed',
      prompt: 'Why is trading a difficult skill to learn from experience?',
      context: 'Compared with, say, chess.',
      optionA: 'It requires more calculation',
      optionB: 'Feedback is noisy — good decisions often lose',
      correctIsA: false,
      explanation:
          'In chess a blunder is punished reliably. In trading a bad decision '
          'frequently profits and a good one frequently loses, so experience '
          'teaches the wrong lessons unless you track process deliberately.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'fo_capital_needed',
      prompt: 'Trying to live on trading income from a small account '
          'creates what?',
      context: '\$2,000 and monthly bills.',
      optionA: 'Pressure to take risks the account cannot survive',
      optionB: 'Healthy motivation',
      correctIsA: true,
      explanation:
          'Required returns force oversized positions. The account size and '
          'the income requirement are simply incompatible, and no amount of '
          'skill resolves the arithmetic.',
      lessonId: 'r3',
    ),
    DailyCall(
      id: 'fo_expectancy_meaning',
      prompt: 'Positive expectancy guarantees what over the next ten trades?',
      context: 'A genuinely good strategy.',
      optionA: 'A profit',
      optionB: 'Nothing — ten trades is well inside variance',
      correctIsA: false,
      explanation:
          'Expectancy is an average over many trades. A positive-edge strategy '
          'loses over ten trades routinely, which is precisely why people '
          'abandon good strategies and why sizing must assume it.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'fo_two_traders',
      prompt: 'Two traders, same strategy, different results over a year. '
          'Most likely explanation?',
      context: 'Both followed it.',
      optionA: 'Variance and timing',
      optionB: 'One executed better',
      correctIsA: true,
      explanation:
          'Starting at different times gives you different trades. Over a '
          'year that alone produces wide dispersion — another reason a single '
          'person\'s track record is weak evidence about a method.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'fo_why_simulate',
      prompt: 'The strongest argument for starting in a simulator is:',
      context: 'Given the base rates.',
      optionA: 'It is easier than real trading',
      optionB: 'The mistakes you will definitely make cost nothing',
      correctIsA: false,
      explanation:
          'Everyone makes the same early errors — oversizing, no stop, '
          'revenge trading. Making them against virtual money is the only '
          'cheap way to find out that you make them.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'fo_realistic_goal',
      prompt: 'Which annual return would be considered excellent by '
          'professional standards?',
      context: 'Sustained, risk-adjusted.',
      optionA: 'Consistently beating the market by a few percent',
      optionB: 'Doubling every year',
      correctIsA: true,
      explanation:
          'Top funds are celebrated for steady, modest outperformance over '
          'decades. Expecting to double annually is expecting to outperform '
          'the best in the world, starting out, alone.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'fo_first_priority',
      prompt: 'For a new trader, what matters most?',
      context: 'One priority.',
      optionA: 'Finding a winning strategy',
      optionB: 'Not blowing up while you learn',
      correctIsA: false,
      explanation:
          'Strategies can be found and refined for as long as you are still '
          'in the game. Survival is the precondition for everything else, and '
          'it is decided by sizing rather than by insight.',
      lessonId: 'r1',
    ),
  ];
}

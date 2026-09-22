import '../../models/daily_models.dart';

/// Indicators, patterns, and what a chart can and cannot tell you.
///
/// Every indicator is a transformation of price and volume you already have.
/// None of them adds information; they reorganise it, which is useful, and
/// they look authoritative, which is dangerous. Most questions here are about
/// the gap between those two facts.
class IndicatorsBank {
  IndicatorsBank._();

  static const List<DailyCall> calls = [
    DailyCall(
      id: 'i_source',
      prompt: 'Where does an indicator get its information?',
      context: 'Any indicator on your chart.',
      optionA: 'From the price and volume already on the chart',
      optionB: 'From outside data the chart lacks',
      correctIsA: true,
      explanation:
          'Indicators are arithmetic on past price. They can make a pattern '
          'easier to see, but they cannot know anything the chart does not. '
          'Stacking five of them is five views of one fact.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_lagging',
      prompt: 'A 200-day moving average turns up. When did the move start?',
      context: 'The average just crossed.',
      optionA: 'Right now',
      optionB: 'Considerably earlier',
      correctIsA: false,
      explanation:
          'An average of the last 200 days only turns after enough new data '
          'outweighs the old. Lag is not a flaw to be tuned away — it is what '
          'an average is. Shorter settings react faster and whipsaw more.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_rsi_overbought',
      prompt: 'RSI has been above 70 for two weeks in a strong uptrend. '
          'What does that mean?',
      context: '"Overbought."',
      optionA: 'The trend is strong — it is not a sell signal',
      optionB: 'A reversal is due',
      correctIsA: true,
      explanation:
          'In trends, RSI sits at an extreme for long stretches. Shorting '
          'strength because a number is high is one of the most reliable ways '
          'to lose money in a bull market.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_rsi_meaning',
      prompt: 'RSI measures what?',
      context: 'The underlying calculation.',
      optionA: 'How many people are buying',
      optionB: 'The ratio of recent gains to recent losses',
      correctIsA: false,
      explanation:
          'It compares average up-moves to average down-moves over a lookback '
          'and scales the result to 0–100. It is a momentum descriptor, not a '
          'measure of participation or sentiment.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_divergence',
      prompt: 'Price makes a higher high, RSI makes a lower high. '
          'What is that?',
      context: 'Bearish divergence.',
      optionA: 'A warning that momentum is fading, not a signal',
      optionB: 'A reliable sell signal',
      correctIsA: true,
      explanation:
          'Divergence says the recent push was weaker than the last one. '
          'Trends often produce several divergences before actually turning, '
          'so it is context for a decision rather than the decision.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_ma_cross',
      prompt: 'A 50-day crosses above a 200-day. What is the honest '
          'description?',
      context: 'The "golden cross".',
      optionA: 'A prediction that price will rise',
      optionB: 'A slow confirmation that a trend already changed',
      correctIsA: false,
      explanation:
          'By the time two long averages cross, the move is well underway. '
          'The signal is not worthless — trend confirmation has value — but it '
          'describes the past, and its name does more work than its edge.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_bollinger',
      prompt: 'Price touches the upper Bollinger band. What does that tell '
          'you?',
      context: 'Two standard deviations above the mean.',
      optionA: 'It is statistically far from its recent average',
      optionB: 'It will revert to the middle',
      correctIsA: true,
      explanation:
          'The band is a volatility measurement, not a boundary. In a strong '
          'trend price walks the band for weeks. "Far from average" and "about '
          'to reverse" are different claims.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_volume_confirm',
      prompt: 'A breakout on very low volume. How much weight does it carry?',
      context: 'Price cleared resistance.',
      optionA: 'The same, price is price',
      optionB: 'Less — few participants agreed at that price',
      correctIsA: false,
      explanation:
          'Volume is how much conviction the move had behind it. A move on '
          'almost no volume can be a handful of orders in a thin book, and it '
          'reverses easily because nothing was built there.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_support_break',
      prompt: 'A long-respected support level finally breaks. '
          'What often happens to it?',
      context: 'Price is now below.',
      optionA: 'It tends to act as resistance',
      optionB: 'It disappears as a level',
      correctIsA: true,
      explanation:
          'People who bought there are now underwater and want out at '
          'break-even; people who wanted to sell got their level. Both create '
          'supply on a retest. The level persists because the positions do.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_pattern_after',
      prompt: 'You can see a perfect head-and-shoulders on last month\'s '
          'chart. What does that prove?',
      context: 'It played out exactly.',
      optionA: 'That the pattern works',
      optionB: 'Very little — patterns are obvious in hindsight',
      correctIsA: false,
      explanation:
          'The test is finding them in real time, before the right shoulder '
          'exists, and counting the ones that failed. Hindsight selects only '
          'the patterns that completed.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'i_more_indicators',
      prompt: 'Adding a sixth indicator that agrees with the other five. '
          'How much has your confidence changed?',
      context: 'All momentum-based.',
      optionA: 'Barely — they measure the same thing',
      optionB: 'Substantially, six confirmations',
      correctIsA: true,
      explanation:
          'Correlated indicators are not independent evidence. Six momentum '
          'oscillators agreeing is one opinion repeated, and it feels like '
          'six, which is exactly what makes it dangerous.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_macd',
      prompt: 'MACD is built from what?',
      context: 'The calculation.',
      optionA: 'Volume and open interest',
      optionB: 'The difference between two moving averages',
      correctIsA: false,
      explanation:
          'It is one average minus another, plus a signal line. Knowing that '
          'makes its behaviour obvious: it lags, it whipsaws in chop, and it '
          'is most useful when a trend is already established.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_atr',
      prompt: 'ATR is most useful for what?',
      context: 'Average True Range.',
      optionA: 'Sizing stops to the instrument\'s normal movement',
      optionB: 'Predicting direction',
      correctIsA: true,
      explanation:
          'ATR says nothing about which way. It says how much this thing '
          'typically moves, which is exactly what you need to place a stop '
          'outside the noise instead of inside it.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'i_timeframe_indicator',
      prompt: 'The same indicator says buy on the 4-hour and sell on the '
          '15-minute. Which is right?',
      context: 'Identical settings.',
      optionA: 'The higher timeframe, always',
      optionB: 'Both — they describe different horizons',
      correctIsA: false,
      explanation:
          'Each is correct about its own window. The real question is which '
          'horizon your trade is on, and whether you will manage it with the '
          'same patience you entered it with.',
      lessonId: 't3',
    ),
    DailyCall(
      id: 'i_candlestick_single',
      prompt: 'A single doji appears. How much should it change your plan?',
      context: 'One candle.',
      optionA: 'Almost nothing without context',
      optionB: 'It signals reversal',
      correctIsA: true,
      explanation:
          'A doji means the period opened and closed at similar prices — '
          'indecision. At the end of an extended run, in context, it can be '
          'informative. On its own, in the middle of chop, it is noise with a '
          'name.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_trendline',
      prompt: 'You can draw a trendline three different ways on the same '
          'chart. What does that tell you?',
      context: 'All look plausible.',
      optionA: 'One of them is objectively correct',
      optionB: 'Trendlines are interpretations, not measurements',
      correctIsA: false,
      explanation:
          'Where you anchor a line is a choice, and choices drift toward what '
          'you already believe. Being explicit about the rule — which highs, '
          'which lows — is what makes it testable rather than decorative.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_volume_profile',
      prompt: 'A price area with very high historical volume tends to act '
          'how?',
      context: 'Lots of business done there.',
      optionA: 'As an area price often stalls or returns to',
      optionB: 'As an area price avoids',
      correctIsA: true,
      explanation:
          'Heavy volume means many positions were opened at that price, so '
          'there is real supply and demand waiting there. It is one of the '
          'few chart features with a clear behavioural mechanism behind it.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_fib',
      prompt: 'Why might a Fibonacci retracement level "work"?',
      context: 'Price bounces at 61.8%.',
      optionA: 'Because of a mathematical property of markets',
      optionB: 'Because enough people watch it and place orders there',
      correctIsA: false,
      explanation:
          'There is no mechanism by which a ratio from a rabbit-breeding '
          'sequence governs prices. What there is: widespread use, so the '
          'orders really do cluster. That is a behavioural effect, and it is '
          'weaker than its mystique.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_indicator_settings',
      prompt: 'You change RSI from 14 to 11 because it back-tests better. '
          'What is the risk?',
      context: 'A small improvement.',
      optionA: 'You fitted a parameter to past noise',
      optionB: 'None, optimisation is good',
      correctIsA: true,
      explanation:
          'If 11 works and 14 does not, and the difference is small, you have '
          'probably found an accident of the sample. The default is not sacred '
          'but a fragile improvement is worse than no improvement.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'i_heikin',
      prompt: 'Heikin-Ashi candles look much smoother than normal candles. '
          'Why?',
      context: 'The same data.',
      optionA: 'They filter out bad ticks',
      optionB: 'They are averaged, so they hide the real open and close',
      correctIsA: false,
      explanation:
          'The smoothing is the point and also the trap: the prices shown are '
          'not prices you can trade at. Using them to place stops or read '
          'entries means working from numbers the market never printed.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_log_scale',
      prompt: 'For an asset that went from \$1 to \$50,000, which chart scale '
          'is more informative?',
      context: 'Long-term view.',
      optionA: 'Logarithmic',
      optionB: 'Linear',
      correctIsA: true,
      explanation:
          'On a linear scale the early years are a flat line and every move '
          'looks like a crash-or-moon. Log scale shows equal percentage moves '
          'as equal distances, which is how returns actually compound.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_indicator_repaint',
      prompt: 'An indicator changes its past signals when new data arrives. '
          'What is it good for?',
      context: 'The arrows move.',
      optionA: 'Spotting turning points',
      optionB: 'Nothing you can trade — the history is fiction',
      correctIsA: false,
      explanation:
          'A repainting indicator shows you signals that were never available '
          'at the time. Its backtest is pure look-ahead bias, and it will look '
          'astonishingly accurate right up until you trade it.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'i_chop',
      prompt: 'Trend-following indicators perform worst in what conditions?',
      context: 'Market character.',
      optionA: 'Sideways, choppy markets',
      optionB: 'Strong trends',
      correctIsA: true,
      explanation:
          'In chop, every small move looks like a new trend and the signals '
          'reverse constantly, producing a run of small losses. Knowing which '
          'environment your tool is for is most of using it well.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_volume_spike_top',
      prompt: 'A huge volume spike on a big green candle after a long rally. '
          'What is one plausible reading?',
      context: 'Record volume.',
      optionA: 'Certain continuation',
      optionB: 'Late buyers being sold into',
      correctIsA: false,
      explanation:
          'Someone supplied all that volume, and at the end of an extended '
          'move it is often those who bought early. It is not proof of a top, '
          'but reading maximum enthusiasm as maximum safety has it backwards.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_moving_average_support',
      prompt: 'Price "bounced off the 50-day moving average." What is the '
          'causal claim?',
      context: 'A common description.',
      optionA: 'Weak — the line is an average, not a barrier',
      optionB: 'Strong — the average supports price',
      correctIsA: true,
      explanation:
          'A moving average has no ability to hold anything up. To the extent '
          'it appears to work, it is because enough people act on it. Confusing '
          'a drawn line with a market force leads to enormous confidence in '
          'thin ideas.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_multi_confirm',
      prompt: 'What would genuinely independent confirmation look like?',
      context: 'Beyond stacking oscillators.',
      optionA: 'Three momentum indicators agreeing',
      optionB: 'Evidence from a different kind of data',
      correctIsA: false,
      explanation:
          'Independence means the second source could disagree for reasons the '
          'first cannot see — volume against price, one market against a '
          'related one. Derivatives of the same series always agree eventually.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_indicator_on_indicator',
      prompt: 'Applying a moving average to RSI. What have you built?',
      context: 'Smoothing the oscillator.',
      optionA: 'A slower, more lagging view of the same price data',
      optionB: 'A new source of information',
      correctIsA: true,
      explanation:
          'Each transformation adds lag and subtracts nothing. Sometimes '
          'useful for cutting noise, but it is worth being clear that you are '
          'further from the price, not closer to the truth.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_gap_fill',
      prompt: '"Gaps always get filled." Is that a rule?',
      context: 'A common saying.',
      optionA: 'Yes, eventually always',
      optionB: 'No — many do, some never do',
      correctIsA: false,
      explanation:
          'Plenty of gaps fill, which is why the saying survives, and plenty '
          'never do. As a trading rule "always" is doing the work, and '
          '"eventually" makes it unfalsifiable.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_higher_high',
      prompt: 'What is the simplest structural definition of an uptrend?',
      context: 'Without indicators.',
      optionA: 'Higher highs and higher lows',
      optionB: 'Green candles',
      correctIsA: true,
      explanation:
          'Structure is definable and testable without any indicator at all. '
          'It also gives you an obvious invalidation: the trend is over when '
          'the pattern of higher lows breaks.',
      lessonId: 't3',
    ),
    DailyCall(
      id: 'i_breakout_retest',
      prompt: 'Waiting for a retest after a breakout trades off what?',
      context: 'Entry technique.',
      optionA: 'Nothing, it is strictly better',
      optionB: 'A better entry against sometimes missing the move',
      correctIsA: false,
      explanation:
          'Retests give a tighter stop and a clearer invalidation, and '
          'sometimes never come. Every entry technique is a trade-off between '
          'price and participation; there is no version that gets both.',
      lessonId: 't3',
    ),
    DailyCall(
      id: 'i_indicator_default',
      prompt: 'Why are settings like RSI-14 so common?',
      context: 'Almost everyone uses them.',
      optionA: 'Convention — and that convention makes them self-reinforcing',
      optionB: 'They are mathematically optimal',
      correctIsA: true,
      explanation:
          'Fourteen was a choice by the indicator\'s author, not a derivation. '
          'It matters now mostly because so many people watch the same levels, '
          'which is a behavioural reason rather than a mathematical one.',
      lessonId: 't4',
    ),
    DailyCall(
      id: 'i_news_vs_chart',
      prompt: 'A chart pattern says up; a major regulatory ban was announced. '
          'What wins?',
      context: 'Conflicting inputs.',
      optionA: 'The pattern, charts price everything',
      optionB: 'The news — the pattern is built on a different world',
      correctIsA: false,
      explanation:
          '"Charts price everything in" assumes the market has seen the '
          'information. A pattern formed before a shock is a description of '
          'conditions that no longer exist.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_indicator_certainty',
      prompt: 'An indicator gives a signal. What is the most it can offer?',
      context: 'At best.',
      optionA: 'A slight shift in the odds',
      optionB: 'A reliable forecast',
      correctIsA: true,
      explanation:
          'Everything on a chart is a nudge to probabilities. Strategies work '
          'by applying small edges consistently with sizing that survives the '
          'losses — not by finding a signal that is right.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'i_scale_illusion',
      prompt: 'Zooming in makes a quiet market look violent. Why does that '
          'matter?',
      context: 'Same data, tighter axis.',
      optionA: 'It does not, price is price',
      optionB: 'It can make you act on moves that are noise',
      correctIsA: false,
      explanation:
          'The vertical axis rescales to whatever is on screen, so a 0.2% '
          'range can look like a cliff. Checking the actual percentage before '
          'reacting defuses a surprising number of impulses.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'i_correlation_btc',
      prompt: 'Most altcoins during a sharp BTC sell-off tend to do what?',
      context: 'A market-wide drop.',
      optionA: 'Fall further than BTC',
      optionB: 'Hold up independently',
      correctIsA: true,
      explanation:
          'Correlations rise toward 1 in stress, and smaller, less liquid '
          'assets fall hardest. A portfolio of ten alts is usually one bet '
          'with extra steps.',
      lessonId: 'r5',
    ),
    DailyCall(
      id: 'i_indicator_removal',
      prompt: 'You remove every indicator and just look at price. '
          'What have you lost?',
      context: 'A bare chart.',
      optionA: 'Essential signals',
      optionB: 'Convenience, not information',
      correctIsA: false,
      explanation:
          'Indicators are summaries of what is already visible. Many '
          'experienced traders work from bare price precisely because the '
          'summaries encourage reacting to the summary instead of the market.',
      lessonId: 't4',
    ),
  ];
}

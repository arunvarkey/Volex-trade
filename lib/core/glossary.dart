/// Plain-English definitions for the trading jargon a beginner meets in Volex.
///
/// Every entry has two layers — child-simple first, engineer-detail second —
/// so the same term serves a total beginner and a serious learner. Surfaced
/// via the "?" affordance on labels (see GlossarySheet / InfoLabel).
class GlossaryEntry {
  /// Display name of the term.
  final String term;

  /// One line a child could understand.
  final String simple;

  /// How to actually read/use it — the engineer's detail.
  final String detail;

  const GlossaryEntry(this.term, this.simple, this.detail);
}

class Glossary {
  const Glossary._();

  static const Map<String, GlossaryEntry> _entries = {
    'win_rate': GlossaryEntry(
      'Win Rate',
      'Out of all your trades, how many made money.',
      'The share of closed trades that ended in profit. 60% means 6 of every 10 trades won. On its own it isn\'t enough — a few large losses can wipe out many small wins, so read it together with Profit Factor and Max Drawdown.',
    ),
    'total_return': GlossaryEntry(
      'Total Return',
      'How much your money grew or shrank overall.',
      'The percentage change in equity over the test period. +20% means \$10,000 became \$12,000. Compare it to simply holding the asset ("buy and hold") to judge whether the strategy actually added value.',
    ),
    'max_drawdown': GlossaryEntry(
      'Max Drawdown',
      'The worst drop from a high point to a low point along the way.',
      'The largest peak-to-trough fall in equity during the test, as a percent. A -30% max drawdown means at some point you were down 30% from your best. Lower is calmer; big drawdowns are what make traders panic-sell in real life.',
    ),
    'profit_factor': GlossaryEntry(
      'Profit Factor',
      'How many dollars you won for every dollar you lost.',
      'Gross profit divided by gross loss. Above 1.0 is profitable; 2.0 means you made \$2 for every \$1 lost. Below 1.0 loses money regardless of win rate.',
    ),
    'sharpe_ratio': GlossaryEntry(
      'Sharpe Ratio',
      'Return earned for each unit of overall risk (ups and downs).',
      'Average return divided by the volatility of returns, annualized. Higher is better: above ~1 is decent, above ~2 is strong. It treats all volatility as risk, so a strategy with big winning swings can be penalized even though those swings helped you.',
    ),
    'sortino_ratio': GlossaryEntry(
      'Sortino Ratio',
      'Like Sharpe, but only counts the downside swings as risk.',
      'Return divided by "downside deviation" (the volatility of losing periods only), annualized. Because upside volatility isn\'t punished, it rewards strategies that are choppy on the way up but steady on the way down. Usually higher than the Sharpe for the same strategy.',
    ),
    'calmar_ratio': GlossaryEntry(
      'Calmar Ratio',
      'Annual return compared with the worst drop you had to sit through.',
      'Annualized return (CAGR) divided by max drawdown. It answers "how much return did I get per unit of worst-case pain?" Above 1 means yearly return exceeded the deepest drawdown; the higher, the more comfortable the ride relative to the reward.',
    ),
    'rsi': GlossaryEntry(
      'RSI',
      'A 0–100 gauge of whether a coin has been bought or sold too hard.',
      'Relative Strength Index (usually 14 periods). Above 70 is often called "overbought" (may pull back); below 30 "oversold" (may bounce). It measures momentum, not certainty — strong trends can stay overbought for a long time.',
    ),
    'macd': GlossaryEntry(
      'MACD',
      'Shows whether momentum is turning up or down.',
      'Moving Average Convergence Divergence: the gap between a fast and a slow moving average, plus a signal line. The MACD crossing above its signal line hints bullish momentum; crossing below hints bearish. Works best in trending markets.',
    ),
    'sma': GlossaryEntry(
      'SMA',
      'The average price over the last N candles, drawn as a smooth line.',
      'Simple Moving Average. SMA(20) averages the last 20 closes. Price above a rising SMA suggests an uptrend; crossovers of a fast and slow SMA (e.g. 50/200, the "golden/death cross") are classic trend signals.',
    ),
    'ema': GlossaryEntry(
      'EMA',
      'Like an SMA, but reacts faster to recent prices.',
      'Exponential Moving Average weights recent candles more, so it turns sooner than an SMA of the same length — earlier signals, but more false ones in choppy markets.',
    ),
    'bollinger_bands': GlossaryEntry(
      'Bollinger Bands',
      'A price "envelope" that widens when the market gets volatile.',
      'A moving average with an upper and lower band set a number of standard deviations away. Price tends to stay inside the bands; touches of the outer band can signal a stretch (mean-reversion) or, on a breakout, a strong move.',
    ),
    'volume': GlossaryEntry(
      'Volume',
      'How much of the coin was traded in that period.',
      'The number of units traded per candle. Rising volume confirms a move (more conviction); a breakout on low volume is weaker and more likely to fail.',
    ),
    'stop_loss': GlossaryEntry(
      'Stop Loss',
      'An automatic "get me out" price if the trade goes wrong.',
      'A preset exit that caps your loss on a trade. Setting it defines your risk before you enter — the cornerstone of not blowing up your account.',
    ),
    'take_profit': GlossaryEntry(
      'Take Profit',
      'An automatic "cash me out" price when the trade goes right.',
      'A preset exit that locks in gains at a target. Paired with a stop loss it sets your risk-to-reward ratio (e.g. risk 1% to make 2%).',
    ),
    'market_order': GlossaryEntry(
      'Market Order',
      'Buy or sell right now at the current price.',
      'Fills immediately at the best available price. Fast and certain to execute, but the exact fill price can slip in fast markets.',
    ),
    'limit_order': GlossaryEntry(
      'Limit Order',
      'Buy or sell only when the price reaches the number you set.',
      'Waits in the book until price hits your limit, then fills at that price or better. You control the price but not whether it fills.',
    ),
    'paper_trading': GlossaryEntry(
      'Paper Trading',
      'Practice trading with fake money and real prices.',
      'Simulated trading against live market data with zero financial risk — the whole point of Volex. Build real skill and prove strategies before any real money is involved.',
    ),
    'pnl': GlossaryEntry(
      'P&L',
      'How much you\'re up or down in dollars.',
      'Profit and Loss. Realized P&L is locked in from closed trades; unrealized P&L is the paper gain/loss on positions still open.',
    ),
    'leverage': GlossaryEntry(
      'Leverage',
      'Borrowing to trade bigger than your cash — amplifies wins AND losses.',
      'A multiplier on position size (e.g. 5x). It magnifies both gains and losses and can liquidate a position fast. Powerful and dangerous; beginners should master unleveraged trading first.',
    ),
    'backtest': GlossaryEntry(
      'Backtest',
      'Replaying past prices to see how a strategy would have done.',
      'Runs your strategy over historical data to estimate its performance. Useful for comparison, but past results don\'t guarantee the future — and over-tuning to history ("overfitting") is a common trap.',
    ),
    // ── Terms the rest of the app puts on screen ──────────────────────
    //
    // Everything above this line came from the backtest results screen. The
    // words below appear on the trade ticket, the risk settings, the chart,
    // the optimizer and the signal feed, where until now they were shown bare
    // and a beginner had no way to find out what they meant.
    'long': GlossaryEntry(
      'Long',
      'Betting the price goes up. You profit if it rises.',
      'Buying first and selling later. Your profit is the sell price minus the buy price, so a long gains when the market rises and loses when it falls. "Going long" and "buying" mean the same thing here.',
    ),
    'short': GlossaryEntry(
      'Short',
      'Betting the price goes down. You profit if it falls.',
      'Selling first and buying back later. Your profit is the sell price minus the (lower) buy-back price, so a short gains when the market falls. Losses on a short have no natural ceiling, because a price can keep rising, which is why a stop loss matters more here than anywhere else.',
    ),
    'position': GlossaryEntry(
      'Position',
      'A trade you currently have open.',
      'The quantity of an asset you are holding, long or short, together with the price you entered at. It stays open — with its profit or loss moving as the price moves — until you close it.',
    ),
    'position_size': GlossaryEntry(
      'Position Size',
      'How much you put into one trade.',
      'The quantity you buy or sell. Volex works it out backwards from your risk: you say how much of your balance you are willing to lose and where your stop goes, and the size that produces exactly that loss is calculated for you. Sizing by feel instead is how most beginners lose money.',
    ),
    'risk_per_trade': GlossaryEntry(
      'Risk Per Trade',
      'The most you are prepared to lose if one trade goes wrong.',
      'Usually set as a percentage of your balance — 1% is a common starting point. It, plus your stop-loss distance, determines your position size. Keeping it small is what lets you survive a losing streak: at 1% a run of ten losses costs about a tenth of your account, at 10% it costs almost all of it.',
    ),
    'risk_reward': GlossaryEntry(
      'Risk / Reward',
      'How much you stand to make compared with what you are risking.',
      'The distance from entry to take-profit divided by the distance from entry to stop-loss. At 2:1 you make twice what you risk when right, which means you can be wrong more often than you are right and still come out ahead. It is the number that makes a modest win rate survivable.',
    ),
    'slippage': GlossaryEntry(
      'Slippage',
      'The gap between the price you expected and the price you got.',
      'Markets move between the moment you press the button and the moment the order fills, so a market order rarely fills at exactly the quoted price. Volex models it in backtests because ignoring it is the single easiest way to make a losing strategy look profitable.',
    ),
    'fees': GlossaryEntry(
      'Trading Fees',
      'The exchange\'s cut, charged on every trade you make.',
      'A percentage of each trade\'s value, charged when you open and again when you close. Volex applies a 0.075% taker fee, in line with a typical crypto exchange. It sounds trivial until you trade often: a strategy taking many small profits can hand all of them to fees.',
    ),
    'spread': GlossaryEntry(
      'Spread',
      'The gap between the buying price and the selling price.',
      'Buyers bid slightly below what sellers ask, and the difference is the spread. You cross it every time you trade with a market order, so it acts as a cost on top of fees. Wider spreads mean a less liquid market.',
    ),
    'equity_curve': GlossaryEntry(
      'Equity Curve',
      'A line showing your account balance over time.',
      'Plots total account value trade by trade. The shape matters as much as the endpoint: a steady climb is a strategy you could actually sit through, while the same final return reached via violent swings is one most people would abandon partway.',
    ),
    'volatility': GlossaryEntry(
      'Volatility',
      'How wildly a price swings around.',
      'A measure of how much price moves, in either direction, over a period. High volatility means bigger opportunities and bigger losses, and it is why the same position size is not equally risky across two different markets.',
    ),
    'timeframe': GlossaryEntry(
      'Timeframe',
      'How much time each candle on the chart covers.',
      'On the 1h chart, one candle is one hour of trading. Shorter timeframes give more signals and more noise; longer ones give fewer, slower, generally more reliable ones. A strategy that works on the daily chart often falls apart on the 5-minute.',
    ),
    'candlestick': GlossaryEntry(
      'Candlestick',
      'One bar on the chart, showing four prices for that period.',
      'The body spans the open and close, and the thin wicks reach the high and low. Green means the close was above the open (price rose over that period), red means it fell. Four numbers in one shape, which is why charts use them.',
    ),
    'support_resistance': GlossaryEntry(
      'Support & Resistance',
      'Price levels where the market has repeatedly turned around.',
      'Support is a level buyers have stepped in at before; resistance is one sellers have. They are not laws — they are places where enough people are watching that behaviour repeats, until it doesn\'t. Broken resistance often becomes support.',
    ),
    'trend': GlossaryEntry(
      'Trend',
      'The general direction price has been heading.',
      'An uptrend makes higher highs and higher lows; a downtrend does the reverse; a range does neither. Most strategies work in one of these conditions and fail in the others, which is why a strategy that stopped working may just be facing a different market.',
    ),
    'breakout': GlossaryEntry(
      'Breakout',
      'Price pushing out of the range it has been stuck in.',
      'A move beyond a level price has repeatedly failed to pass. Breakouts on strong volume can start a big trend; breakouts on weak volume often reverse straight back into the range — the "false breakout" that catches out beginners.',
    ),
    'signal': GlossaryEntry(
      'Signal',
      'The app pointing out that a setup it watches for has appeared.',
      'A rules-based observation — an indicator crossed a level, a pattern completed — not a prediction and not advice. In Volex a signal tells you what the rule saw and why, so you can judge it. Acting on signals you do not understand is how a strategy becomes a lottery ticket.',
    ),
    'confidence': GlossaryEntry(
      'Confidence',
      'How well the setup matched the rules — not a chance of winning.',
      'A score for how cleanly conditions lined up. It is easy to misread: 80% confidence does not mean an 80% chance of profit. It means the pattern was a strong example of itself, and strong examples still fail regularly.',
    ),
    'overfitting': GlossaryEntry(
      'Overfitting',
      'Tuning a strategy so tightly to the past that it only works on the past.',
      'Push enough settings around and you will find some that would have made money on the exact history you tested, by memorising its noise rather than learning anything about markets. Such strategies look superb in a backtest and fail immediately in live conditions. It is the main risk of using an optimizer.',
    ),
    'optimization': GlossaryEntry(
      'Optimization',
      'Searching many setting combinations to find ones that did well.',
      'Volex uses a genetic search: it tries a population of settings, keeps those that scored best, combines and mutates them, and repeats over successive generations. It finds good settings quickly, and it will happily find overfitted ones just as quickly — always retest a winner on a period it has never seen.',
    ),
    'drawdown': GlossaryEntry(
      'Drawdown',
      'How far you are currently down from your best balance.',
      'The fall from a previous account peak. It is the number that decides whether a strategy is bearable in practice: a 40% drawdown means watching almost half your account disappear and still following the plan. Most people cannot, which is why they abandon strategies at the worst moment.',
    ),
    'daily_loss_limit': GlossaryEntry(
      'Daily Loss Limit',
      'A cap that stops you trading once you are down enough for one day.',
      'When the day\'s losses reach the limit you set, no new positions can be opened until tomorrow. It exists to break "revenge trading" — the urge to win it back immediately, which reliably turns a bad day into a much worse one. You can still close and manage the positions you already have.',
    ),
    'emergency_stop': GlossaryEntry(
      'Emergency Stop',
      'One switch that halts all automated strategies and new orders.',
      'A manual kill switch for when something is behaving in a way you did not intend. It blocks new positions and stops every running strategy at once. It never blocks you from reducing or closing what is already open — getting out must always stay possible.',
    ),
    'liquidation': GlossaryEntry(
      'Liquidation',
      'The exchange force-closing a leveraged position that ran out of margin.',
      'With leverage you only post part of the position\'s value. If the market moves against you far enough that your deposit can no longer cover the loss, the position is closed for you at whatever the price is — and the deposit is gone. Higher leverage means a smaller move gets you there.',
    ),
    // ── Event markets ─────────────────────────────────────────────────
    'prediction_market': GlossaryEntry(
      'Event Market',
      'A market on whether something will happen, rather than on a price.',
      'You buy Yes or No on a question with a definite answer — "will X happen by date Y". When the event resolves, the correct side is worth \$1 per contract and the other side is worth nothing. In Volex this runs entirely on virtual money.',
    ),
    'contract': GlossaryEntry(
      'Contract',
      'One unit of a bet, worth \$1 if you are right and \$0 if you are wrong.',
      'The thing you buy in an event market. Buying 50 contracts at 40c costs \$20; if the outcome goes your way they pay \$50, and if it does not you lose the \$20. Buying more contracts scales both the cost and the payout in a straight line.',
    ),
    'implied_probability': GlossaryEntry(
      'The Price Is A Probability',
      'A contract priced at 40c means the market thinks it is about 40% likely.',
      'Because a winning contract pays exactly \$1, its price is what people collectively think the chance is. 40c means roughly 40%. This is the single most useful thing to understand here: you are not judging whether the event will happen, you are judging whether the crowd has the odds wrong. Buying at 90c something you think is 95% likely is a better trade than buying at 40c something you think is 50% likely.',
    ),
  };

  static GlossaryEntry? of(String id) => _entries[id];

  static bool has(String id) => _entries.containsKey(id);

  /// Every term, alphabetical by display name — for a browsable glossary.
  static List<MapEntry<String, GlossaryEntry>> get all {
    final list = _entries.entries.toList()
      ..sort((a, b) => a.value.term.toLowerCase().compareTo(
            b.value.term.toLowerCase(),
          ));
    return list;
  }
}

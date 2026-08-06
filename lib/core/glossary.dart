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
  };

  static GlossaryEntry? of(String id) => _entries[id];

  static bool has(String id) => _entries.containsKey(id);
}

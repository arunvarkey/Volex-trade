class ScriptTemplates {
  static String generateRsiReversion({
    required int period,
    required double buyThreshold,
    required double sellThreshold,
  }) {
    return """
def on_candle(candle):
    # RSI Mean Reversion Strategy (Generated)
    # Buy when Oversold (< $buyThreshold), Sell when Overbought (> $sellThreshold)
    
    rsi = indicators.rsi(period=$period)
    
    if rsi < $buyThreshold:
        volex.buy()
        print(f"RSI Oversold ({rsi:.1f}). Buying.")
        
    elif rsi > $sellThreshold:
        volex.sell()
        print(f"RSI Overbought ({rsi:.1f}). Selling.")
""";
  }

  static String generateEmaTrend({
    required int fastPeriod,
    required int slowPeriod,
  }) {
    return """
def on_candle(candle):
    # EMA Trend Following Strategy (Generated)
    # Buy when Price > EMA ($fastPeriod) - 'Golden Trend'
    
    ema = indicators.ema(period=$fastPeriod)
    
    if close > ema:
        volex.buy()
    elif close < ema:
        volex.sell()
""";
  }
}

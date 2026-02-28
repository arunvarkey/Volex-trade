class SymbolInfo {
  final String symbol;      // BTCUSDT
  final String displayName; // Bitcoin
  final int pricePrecision; 
  final int qtyPrecision;
  final String wsStreamName; // btcusdt@kline_1m

  const SymbolInfo({
    required this.symbol,
    required this.displayName,
    this.pricePrecision = 2,
    this.qtyPrecision = 3,
    required this.wsStreamName,
  });
}

class SymbolRegistry {
  static const List<SymbolInfo> supportedSymbols = [
    SymbolInfo(
      symbol: "BTCUSDT",
      displayName: "BTC/USDT",
      pricePrecision: 2,
      wsStreamName: "btcusdt@kline_1m",
    ),
    SymbolInfo(
      symbol: "ETHUSDT",
      displayName: "ETH/USDT",
      pricePrecision: 2,
      wsStreamName: "ethusdt@kline_1m",
    ),
    SymbolInfo(
      symbol: "SOLUSDT",
      displayName: "SOL/USDT",
      pricePrecision: 3,
      wsStreamName: "solusdt@kline_1m",
    ),
    SymbolInfo(
      symbol: "DOGEUSDT",
      displayName: "DOGE/USDT",
      pricePrecision: 5,
      wsStreamName: "dogeusdt@kline_1m",
    ),
  ];

  static SymbolInfo get defaultSymbol => supportedSymbols.first;
}

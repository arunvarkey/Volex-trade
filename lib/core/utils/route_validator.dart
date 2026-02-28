/// Validation helper for deep links and route parameters
class RouteValidator {
  /// Validates if a symbol string is a valid trading pair
  ///
  /// Valid format: 3-10 uppercase letters followed by USDT
  /// Examples: BTCUSDT, ETHUSDT, ADAUSDT
  static bool isValidSymbol(String symbol) {
    return RegExp(r'^[A-Z]{3,10}USDT$').hasMatch(symbol);
  }

  /// Validates if a timeframe string is valid
  ///
  /// Valid values: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w, 1M
  static bool isValidTimeframe(String timeframe) {
    const validTimeframes = [
      '1m',
      '3m',
      '5m',
      '15m',
      '30m',
      '1h',
      '2h',
      '4h',
      '6h',
      '8h',
      '12h',
      '1d',
      '3d',
      '1w',
      '1M'
    ];
    return validTimeframes.contains(timeframe);
  }

  /// Sanitizes a symbol string by converting to uppercase and removing invalid characters
  static String sanitizeSymbol(String symbol) {
    return symbol.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
  }
}

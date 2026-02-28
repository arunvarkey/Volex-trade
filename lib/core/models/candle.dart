// lib/core/models/candle.dart
class Candle {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const Candle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromList(List<dynamic> list) {
    // Assumes list order: [timestamp(ms), open, high, low, close, volume]
    return Candle(
      timestamp: DateTime.fromMillisecondsSinceEpoch(list[0] as int),
      open: (list[1] as num).toDouble(),
      high: (list[2] as num).toDouble(),
      low: (list[3] as num).toDouble(),
      close: (list[4] as num).toDouble(),
      volume: (list[5] as num).toDouble(),
    );
  }

  factory Candle.fromCsv(List<dynamic> row) {
    // Helper to parse CSV row (assuming simple list of strings/nums)
    // Row might be strings if read from csv file directly without casting
    final ts = row[0] as num;
    return Candle(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          ts.toInt() * 1000), // Unix seconds
      open: (row[1] as num).toDouble(),
      high: (row[2] as num).toDouble(),
      low: (row[3] as num).toDouble(),
      close: (row[4] as num).toDouble(),
      volume: (row[5] as num).toDouble(),
    );
  }

  @override
  String toString() =>
      'Candle($timestamp, O:$open, H:$high, L:$low, C:$close, V:$volume)';
}

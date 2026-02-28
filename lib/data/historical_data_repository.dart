import 'dart:io';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/core/app_logger.dart';

/// Repository for loading and managing historical market data.
///
/// Supports:
/// *   **CSV Parsing**: Loading OHLCV data from local files.
/// *   **Mock Generation**: Creating synthetic data for testing/development.
/// *   **Data Validation**: Filtering invalid lines and ensuring chronological order.
class HistoricalDataRepository {
  /// Loads candle data from a CSV file at the specified [filePath].
  ///
  /// **Expected Format:** `timestamp(ms), open, high, low, close, volume`
  ///
  /// *   Automatically detects and skips header lines.
  /// *   Parses timestamp as generic integer (usually milliseconds epoch).
  /// *   Sorts resulting candles by date to ensure time-series integrity.
  ///
  /// Throws [FileSystemException] if the file does not exist.
  Future<List<Candle>> loadFromCsv(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      AppLogger.error("HISTORY: File not found at $filePath");
      throw FileSystemException("File not found", filePath);
    }

    final lines = await file.readAsLines();
    final List<Candle> candles = [];

    AppLogger.info("HISTORY: Parsing ${lines.length} lines from $filePath...");

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip header if detected (starts with non-digit)
      if (i == 0 && int.tryParse(line.split(',')[0]) == null) {
        continue;
      }

      try {
        final candle = _parseLine(line);
        if (candle != null) {
          candles.add(candle);
        }
      } catch (e) {
        AppLogger.warning("HISTORY: skipped bad line $i: '$line' ($e)");
      }
    }

    // Sort by Date (Generic safety)
    candles.sort((a, b) => a.date.compareTo(b.date));

    AppLogger.info("HISTORY: Successfully loaded ${candles.length} candles.");
    return candles;
  }

  Candle? _parseLine(String line) {
    final parts = line.split(',');
    if (parts.length < 5) return null;

    const timestampIdx = 0;
    const openIdx = 1;
    const highIdx = 2;
    const lowIdx = 3;
    const closeIdx = 4;
    const volIdx = 5; // Optional

    // Parse Timestamp (assume Milliseconds Epoch)
    final ts = int.parse(parts[timestampIdx]);
    // final date = DateTime.fromMillisecondsSinceEpoch(ts);

    return Candle(
      time: ts,
      open: double.parse(parts[openIdx]),
      high: double.parse(parts[highIdx]),
      low: double.parse(parts[lowIdx]),
      close: double.parse(parts[closeIdx]),
      volume: parts.length > 5 ? double.parse(parts[volIdx]) : 0.0,
    );
  }

  /// Generates synthetic price data for testing visualization and backtesting.
  ///
  /// *   Uses a Random Walk algorithm.
  /// *   Generates 1-minute interval candles going back [days].
  /// *   Useful when live API keys or CSV files are unavailable.
  Future<List<Candle>> generateMockHistory({int days = 30}) async {
    final List<Candle> candles = [];
    final now = DateTime.now();
    double price = 50000.0;

    // Generate 1-minute candles
    final count = days * 24 * 60;

    for (int i = 0; i < count; i++) {
      final date = now.subtract(Duration(minutes: count - i));

      // Random Walk
      final change = (i % 2 == 0 ? 1 : -1) * (i % 10 + 1) * 0.5;
      price += change;

      candles.add(Candle(
        time: date.millisecondsSinceEpoch,
        open: price,
        high: price + 5,
        low: price - 5,
        close: price + 2,
        volume: 100 + (i % 50).toDouble(),
      ));
    }
    return candles;
  }
}

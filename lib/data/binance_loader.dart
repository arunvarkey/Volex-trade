import 'dart:io';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/core/app_logger.dart';

class BinanceDataLoader {
  Future<List<Candle>> loadHistoricalData(String filepath) async {
    final file = File(filepath);
    final lines = await file.readAsLines();

    // Binance CSV format (No Header usually):
    // Open time, Open, High, Low, Close, Volume, ...
    // 1704067200000,42283.58,42331.7,42260.11,42283.58,24.13702, ...

    final List<Candle> candles = [];

    for (var line in lines) {
      // Manual split for speed/simplicity without external package
      final parts = line.split(',');
      if (parts.length < 6) continue;

      try {
        final timeMs = int.tryParse(parts[0]);
        if (timeMs == null) continue; // Skip header if present

        candles.add(Candle(
          time: timeMs,
          open: double.parse(parts[1]),
          high: double.parse(parts[2]),
          low: double.parse(parts[3]),
          close: double.parse(parts[4]),
          volume: double.parse(parts[5]),
        ));
      } catch (e) {
        // Skip malformed
        AppLogger.warning("Skipping line: $e");
      }
    }

    return candles;
  }
}

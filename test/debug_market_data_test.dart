import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/data/market_data_repository.dart';
import 'test_helper.dart';

void main() {
  test('MarketDataRepository fetches history for BTCUSDT', () async {
    final file = File('debug_log.txt');
    if (file.existsSync()) file.deleteSync();

    void log(String msg) {
      file.writeAsStringSync("$msg\n", mode: FileMode.append);
      // print(msg); // Optional
    }

    log("Starting Market Data Debug...");

    await setupServiceLocator(); // Register dependencies for MarketDataRepository factory

    // Initialize Repository
    final repo = MarketDataRepository.forTesting();
    log("Repository Created");

    try {
      log("Fetching History for BTCUSDT...");
      final candles =
          await repo.fetchHistory(symbol: "BTCUSDT", interval: "1m");

      log("Fetch Complete.");
      log("Candles found: ${candles.length}");

      if (candles.isNotEmpty) {
        log("First Candle: ${candles.first.date} - ${candles.first.close}");
        log("Last Candle: ${candles.last.date} - ${candles.last.close}");
      } else {
        log("WARNING: No candles returned.");
      }

      expect(candles, isNotNull);
    } catch (e, stack) {
      log("ERROR: $e");
      log("Stack: $stack");
      rethrow;
    } finally {
      // repo.dispose(); // Can cause errors if isolate killed during test shutdown?
      // Actually dispose is good practice.
      repo.dispose();
      log("Repository Disposed");
    }
  });
}

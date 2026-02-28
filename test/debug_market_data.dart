// ignore_for_file: avoid_print
import 'package:volex_terminal/data/market_data_repository.dart';

void main() async {
  print("Starting Market Data Debug...");

  // Initialize Logger (if needed, but it's likely static)

  final repo = MarketDataRepository();
  print("Repository Initialized.");

  try {
    print("Fetching History for BTCUSDT...");
    final candles = await repo.fetchHistory(symbol: "BTCUSDT", interval: "1m");

    print("Fetch Complete.");
    print("Candles found: ${candles.length}");

    if (candles.isNotEmpty) {
      print("First Candle: ${candles.first.date} - ${candles.first.close}");
      print("Last Candle: ${candles.last.date} - ${candles.last.close}");
    } else {
      print("WARNING: No candles returned.");
    }
  } catch (e) {
    print("ERROR: $e");
  } finally {
    // repo.dispose(); // Dispose mostly closes streams/isolates
    // We want to see if it hangs, but for script we should probably exit
    // repo.dispose();
    // IsolateManager needs to be disposed to kill the isolate
    repo.dispose();
  }
}

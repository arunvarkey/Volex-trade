import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/historical_repository.dart';
import '../../domain/symbol_info.dart';
import '../../domain/candle_model.dart';
import '../../core/app_logger.dart';
import 'package:volex_terminal/core/chart_math.dart'; // RSI (shared core math)
import 'package:volex_terminal/engine/notifications/notification_bus.dart';
import 'package:volex_terminal/engine/notifications/notification_model.dart';

class ScannerResult {
  final String symbol;
  final double trendStrength; // Linear Regression Slope
  final double volatility;
  final double rsi;
  final double volume; // 24h Volume (approx from window)
  final List<Candle> history;

  ScannerResult({
    required this.symbol,
    required this.trendStrength,
    required this.volatility,
    required this.rsi,
    required this.volume,
    required this.history,
  });
}

class ScannerEngine extends ChangeNotifier {
  final HistoricalRepository _repo;
  bool isScanning = false;
  Map<String, ScannerResult> results = {};
  Timer? _scanTimer;

  // Anti-Spam: Track last notification time per symbol
  final Map<String, DateTime> _lastAlertTime = {};

  ScannerEngine(this._repo);

  Future<void> scanAll({bool useRealData = false}) async {
    if (isScanning) return;
    isScanning = true;
    notifyListeners();

    try {
      final symbols =
          SymbolRegistry.supportedSymbols.map((s) => s.symbol).toList();
      AppLogger.info("SCANNER: Scanning ${symbols.length} symbols...");

      final dataBatch = await _repo.fetchHistoryBatch(
        symbols: symbols,
        interval: "1m",
        useRealData: useRealData,
        limit: 100, // Shorter window for scanning speed
      );

      final newResults = <String, ScannerResult>{};

      for (var entry in dataBatch.entries) {
        final symbol = entry.key;
        final candles = entry.value;

        if (candles.length < 14) continue; // Need min 14 for RSI

        // Calculate Factors
        final strength = _calculateTrendStrength(candles);
        final volatility = _calculateVolatility(candles);
        final rsi = _calculateLastRSI(candles);
        final volume = _calculateTotalVolume(candles);

        newResults[symbol] = ScannerResult(
          symbol: symbol,
          trendStrength: strength,
          volatility: volatility,
          rsi: rsi,
          volume: volume,
          history: candles,
        );

        // Check for Alerts
        _checkAndNotify(symbol, rsi, strength);
      }

      results = newResults;
      AppLogger.info(
          "SCANNER: Scan complete. Found trends for ${results.length} symbols.");
    } catch (e) {
      AppLogger.error("SCANNER: Scan failed: $e");
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  void _checkAndNotify(String symbol, double rsi, double strength) {
    // Debounce: Only 1 alert per symbol per 5 minutes
    final now = DateTime.now();
    if (_lastAlertTime.containsKey(symbol)) {
      if (now.difference(_lastAlertTime[symbol]!) <
          const Duration(minutes: 5)) {
        return;
      }
    }

    String? title;
    String? message;

    if (rsi < 30) {
      title = "$symbol OVERSOLD";
      message =
          "RSI is ${rsi.toStringAsFixed(1)}. Potential bounce opportunity.";
    } else if (rsi > 70) {
      title = "$symbol OVERBOUGHT";
      message = "RSI is ${rsi.toStringAsFixed(1)}. Potential pullback.";
    } else if (strength.abs() > 0.08) {
      final direction = strength > 0 ? "BULLISH" : "BEARISH";
      title = "$symbol STRONG $direction";
      message = "Momentum surge detected: ${strength.toStringAsFixed(2)}%";
    }

    if (title != null) {
      NotificationBus().publish(
          type: NotificationType.strategy,
          severity: NotificationSeverity.info,
          title: title,
          message: message!,
          userId: "current_user",
          metadata: {"rsi": rsi, "strength": strength, "symbol": symbol});
      _lastAlertTime[symbol] = now;
    }
  }

  void startAutoScan(
      {Duration interval = const Duration(seconds: 30),
      bool useRealData = false}) {
    _scanTimer?.cancel();
    _scanTimer =
        Timer.periodic(interval, (_) => scanAll(useRealData: useRealData));
    AppLogger.info(
        "SCANNER: Auto-scan started (Interval: ${interval.inSeconds}s).");
  }

  void stopAutoScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    AppLogger.info("SCANNER: Auto-scan stopped.");
  }

  @override
  void dispose() {
    stopAutoScan();
    super.dispose();
  }

  double _calculateLastRSI(List<Candle> candles) {
    // Wilder's RSI via the shared core math (same algorithm the chart uses).
    final closes = [for (final c in candles) c.close];
    final rsiSeries = ChartMath.rsiSeries(closes, period: 14);
    // Get the last non-null value
    for (int i = rsiSeries.length - 1; i >= 0; i--) {
      if (rsiSeries[i] != null) return rsiSeries[i]!;
    }
    return 50.0; // Default neutral
  }

  double _calculateTrendStrength(List<Candle> candles) {
    // Simplified Linear Regression Slope over the window
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;
    int n = candles.length;

    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = candles[i].close;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) return 0;

    // Weighted slope normalized by price to get % growth per candle (approx)
    double slope = (n * sumXY - sumX * sumY) / denominator;
    double avgPrice = sumY / n;

    return (slope / avgPrice) * 100; // % per period
  }

  double _calculateVolatility(List<Candle> candles) {
    // Standard deviation of returns (simplified)
    if (candles.isEmpty) return 0;
    double avg =
        candles.map((c) => c.close).reduce((a, b) => a + b) / candles.length;
    double variance = candles
            .map((c) => (c.close - avg) * (c.close - avg))
            .reduce((a, b) => a + b) /
        candles.length;
    return (variance / avg); // Normalized
  }

  double _calculateTotalVolume(List<Candle> candles) {
    if (candles.isEmpty) return 0;
    // For 1m interval over 100 candles, this is a proxy for 24h if scaled,
    // but we'll just show the window volume for now.
    return candles.map((c) => c.volume).reduce((a, b) => a + b);
  }
}

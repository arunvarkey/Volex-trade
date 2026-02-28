import '../parameters/parameter_models.dart';
import '../strategy/strategy_metadata.dart';
import 'sandbox_data_feed.dart';
import '../analytics/analytics_models.dart';

class SandboxSessionResult {
  final StrategyPerformanceMetrics metrics;
  final List<String> logs;
  final bool success;
  final String? error;

  SandboxSessionResult({
    required this.metrics,
    required this.logs,
    required this.success,
    this.error,
  });
}

class SandboxExecutionEngine {
  // Sandbox Limits
  static const int maxTicks = 10000;

  Future<SandboxSessionResult> run(
      StrategyMetadata strategy, SandboxDataFeed feed,
      {StrategyParameterSet? parameters, bool Function()? isCancelled}) async {
    List<String> logs = [];
    logs.add(
        "SANDBOX: Starting execution for ${strategy.name} on ${feed.type.name} feed.");

    if (parameters != null) {
      logs.add("SANDBOX: Loaded custom parameters: ${parameters.values}");
    }

    try {
      final prices = await feed.getPriceStream();

      int trades = 0;
      int wins = 0;

      // Simulation Loop
      for (int i = 0; i < prices.length; i++) {
        // Kill Switch Check
        if (isCancelled?.call() == true) {
          logs.add("SANDBOX: Execution terminated by user.");
          break;
        }

        if (i >= maxTicks) {
          logs.add("SANDBOX: Max ticks reached. Stopping.");
          break;
        }

        // Yield to event loop to allow UI updates and cancellation events
        if (i % 500 == 0) {
          await Future.delayed(Duration.zero);
        }

        // Mock Strategy Processing (Here we would actually call strategy.onTick)
        // For now, we simulate logic based on price movement
        if (i > 0) {
          // Dummy Logic: Buy if price went up
          if (prices[i] > prices[i - 1]) {
            trades++;
            if (i % 2 == 0) wins++; // Pseudo-random win
          }
        }
      }

      logs.add("SANDBOX: Execution complete.");

      // If cancelled, we still return the partial result
      return SandboxSessionResult(
          success: true,
          logs: logs,
          metrics: StrategyPerformanceMetrics(
              tradesExecuted: trades,
              wins: wins,
              losses: trades - wins,
              avgReturn: 0.05, // Mock
              sharpeEstimate: 1.2));
    } catch (e) {
      logs.add("SANDBOX CRITICAL ERROR: $e");
      return SandboxSessionResult(
          success: false,
          logs: logs,
          metrics: const StrategyPerformanceMetrics(),
          error: e.toString());
    }
  }
}

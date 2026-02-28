import '../domain/candle_model.dart';
import '../domain/ghost_model.dart';

class LinearRegressionService {
  /// Calculates a simple linear regression over the last [period] candles
  /// and projects it [projectForward] candles into the future.
  static GhostModel? compute(List<Candle> candles,
      {int period = 50, int projectForward = 20}) {
    if (candles.length < period) {
      return null;
    }

    final subset = candles.sublist(candles.length - period);

    // X = 0 to period-1
    // Y = Close Price

    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0; // sum of x^2

    final n = subset.length;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = subset[i].close;

      sumX += x;
      sumY += y;
      sumXY += (x * y);
      sumX2 += (x * x);
    }

    final denominator = (n * sumX2) - (sumX * sumX);
    if (denominator == 0) {
      return null;
    } // Time didn't move? Should be impossible.

    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    final intercept = (sumY - (slope * sumX)) / n;

    // Result
    // Start Point (at x=0 relative to subset start, which is index [total - period])
    // Actually, let's map it to absolute indices for the ChartController
    final absoluteStartIndex = candles.length - period;
    final absoluteEndIndex = candles.length + projectForward;

    // y = mx + b
    // At local x = 0 (Start of subset)
    final startY = (slope * 0) + intercept;

    // At local x = (period + projectForward)
    final endY = (slope * (period + projectForward - 1)) + intercept;

    return GhostModel(
      startIndex: absoluteStartIndex,
      endIndex: absoluteEndIndex, // Projected into future
      startPrice: startY,
      endPrice: endY,
    );
  }
}

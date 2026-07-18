import 'dart:math' as math;

/// Pure math helpers for the chart engine — kept dependency-free so they can
/// be unit-tested without a widget tree.
class ChartMath {
  ChartMath._();

  /// A "nice" grid step (1 / 2.5 / 5 / 10 × power of ten) near [rough].
  /// Returns 0 for non-positive/non-finite input (flat or empty ranges).
  static double niceStep(double rough) {
    if (!rough.isFinite || rough <= 0) return 0;
    final mag =
        math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    final norm = rough / mag;
    if (norm < 1.5) return mag;
    if (norm < 3.5) return 2.5 * mag;
    if (norm < 7.5) return 5 * mag;
    return 10 * mag;
  }

  /// Grid levels strictly inside (min, max) at nice steps. Empty when the
  /// range is flat, inverted, or non-finite — never throws.
  static List<double> priceLevels(double min, double max,
      {double divisions = 4.5}) {
    final range = max - min;
    if (!range.isFinite || range <= 0) return const [];
    final step = niceStep(range / divisions);
    if (step <= 0) return const [];
    final levels = <double>[];
    var level = (min / step).ceil() * step;
    while (level < max) {
      levels.add(level);
      level += step;
    }
    return levels;
  }

  /// Simple moving average of [values] ending at [index] (inclusive), or null
  /// if there is not enough history.
  static double? sma(List<double> values, int index, int period) {
    if (period <= 0 || index + 1 < period || index >= values.length) {
      return null;
    }
    double sum = 0;
    for (int i = index - period + 1; i <= index; i++) {
      sum += values[i];
    }
    return sum / period;
  }
}

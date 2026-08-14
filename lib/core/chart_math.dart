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

  /// Exponential moving average of [values], seeded with the simple average of
  /// the first [period] values. Returns a list the same length as [values];
  /// entries before index `period - 1` are null (not enough history).
  static List<double?> emaSeries(List<double> values, int period) {
    final out = List<double?>.filled(values.length, null);
    if (period <= 0 || values.length < period) return out;
    final k = 2 / (period + 1);
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += values[i];
    }
    double prev = sum / period;
    out[period - 1] = prev;
    for (int i = period; i < values.length; i++) {
      prev = (values[i] - prev) * k + prev;
      out[i] = prev;
    }
    return out;
  }

  /// Wilder's RSI over [closes]. Returns a list aligned to [closes]; the first
  /// defined value is at index [period]. A perfectly flat window (no gains or
  /// losses) yields a neutral 50.
  static List<double?> rsiSeries(List<double> closes, {int period = 14}) {
    final n = closes.length;
    final out = List<double?>.filled(n, null);
    if (period <= 0 || n <= period) return out;

    double gain = 0;
    double loss = 0;
    for (int i = 1; i <= period; i++) {
      final ch = closes[i] - closes[i - 1];
      if (ch > 0) {
        gain += ch;
      } else {
        loss -= ch; // ch <= 0, so -ch >= 0
      }
    }
    double avgGain = gain / period;
    double avgLoss = loss / period;
    out[period] = _rsiFrom(avgGain, avgLoss);

    for (int i = period + 1; i < n; i++) {
      final ch = closes[i] - closes[i - 1];
      final g = ch > 0 ? ch : 0.0;
      final l = ch < 0 ? -ch : 0.0;
      avgGain = (avgGain * (period - 1) + g) / period;
      avgLoss = (avgLoss * (period - 1) + l) / period;
      out[i] = _rsiFrom(avgGain, avgLoss);
    }
    return out;
  }

  /// Index of the entry in the ascending-sorted [times] closest to [target]
  /// (e.g. mapping a trade timestamp to its candle). Ties resolve to the lower
  /// index. Returns -1 for an empty list.
  static int nearestIndexByTime(List<int> times, int target) {
    final n = times.length;
    if (n == 0) return -1;
    if (target <= times.first) return 0;
    if (target >= times.last) return n - 1;
    int lo = 0;
    int hi = n - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final t = times[mid];
      if (t == target) return mid;
      if (t < target) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    // lo is now the first index past target; hi == lo - 1.
    return (target - times[hi]) <= (times[lo] - target) ? hi : lo;
  }

  /// Shortest distance from point (px,py) to the segment (ax,ay)-(bx,by),
  /// in the same units as the inputs. Used to hit-test trendlines. A
  /// zero-length segment measures distance to its single point.
  static double distanceToSegment(
      double px, double py, double ax, double ay, double bx, double by) {
    final dx = bx - ax;
    final dy = by - ay;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) {
      final ex = px - ax;
      final ey = py - ay;
      return math.sqrt(ex * ex + ey * ey);
    }
    var t = ((px - ax) * dx + (py - ay) * dy) / lenSq;
    t = t.clamp(0.0, 1.0);
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    final ex = px - cx;
    final ey = py - cy;
    return math.sqrt(ex * ex + ey * ey);
  }

  static double _rsiFrom(double avgGain, double avgLoss) {
    if (avgLoss == 0) return avgGain == 0 ? 50 : 100;
    final rs = avgGain / avgLoss;
    return 100 - 100 / (1 + rs);
  }

  /// MACD (fast/slow/signal, default 12/26/9) over [closes]. Each list is
  /// aligned to [closes] with nulls where there isn't enough history, and at
  /// every defined index `histogram == macd - signal`.
  static ({List<double?> macd, List<double?> signal, List<double?> histogram})
      macd(
    List<double> closes, {
    int fast = 12,
    int slow = 26,
    int signalPeriod = 9,
  }) {
    final n = closes.length;
    final emaFast = emaSeries(closes, fast);
    final emaSlow = emaSeries(closes, slow);

    final macdLine = List<double?>.filled(n, null);
    for (int i = 0; i < n; i++) {
      final f = emaFast[i];
      final s = emaSlow[i];
      if (f != null && s != null) macdLine[i] = f - s;
    }

    final signal = List<double?>.filled(n, null);
    final hist = List<double?>.filled(n, null);
    final firstIdx = macdLine.indexWhere((v) => v != null);
    if (firstIdx >= 0) {
      final defined = <double>[];
      for (int i = firstIdx; i < n; i++) {
        defined.add(macdLine[i]!);
      }
      final sig = emaSeries(defined, signalPeriod);
      for (int j = 0; j < sig.length; j++) {
        final v = sig[j];
        if (v == null) continue;
        final i = firstIdx + j;
        signal[i] = v;
        hist[i] = macdLine[i]! - v;
      }
    }
    return (macd: macdLine, signal: signal, histogram: hist);
  }
}

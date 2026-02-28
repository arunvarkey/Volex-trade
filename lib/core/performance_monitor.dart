class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, int> _startTimes = {};
  final Map<String, double> _metrics = {};

  // Rolling average
  final Map<String, List<double>> _history = {};
  static const int kRollingWindow = 60;

  void start(String metric) {
    _startTimes[metric] = DateTime.now().microsecondsSinceEpoch;
  }

  void end(String metric) {
    final start = _startTimes[metric];
    if (start == null) return;

    final end = DateTime.now().microsecondsSinceEpoch;
    final durationMs = (end - start) / 1000.0;

    // Update metric with simple rolling average
    _history.putIfAbsent(metric, () => []);
    final history = _history[metric]!;
    history.add(durationMs);
    if (history.length > kRollingWindow) {
      history.removeAt(0);
    }

    double sum = 0;
    for (var d in history) {
      sum += d;
    }
    _metrics[metric] = sum / history.length;
  }

  double getMetric(String metric) {
    return _metrics[metric] ?? 0.0;
  }
}

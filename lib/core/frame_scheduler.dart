import 'package:flutter/scheduler.dart';

/// A generic Ticker wrapper that drives the engine at 60fps (or device refresh rate).
class FrameScheduler {
  final void Function(double dt) onTick;
  final TickerProvider tickerProvider;

  late final Ticker _ticker;
  Duration? _lastElapsed;

  // FPS Monitoring
  int _frameCount = 0;
  double _fps = 0.0;
  DateTime _lastFpsUpdate = DateTime.now();

  double get currentFps => _fps;

  FrameScheduler({
    required this.onTick,
    required this.tickerProvider,
  }) {
    _ticker = tickerProvider.createTicker(_handleTick);
  }

  void _handleTick(Duration elapsed) {
    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    onTick(dt);

    // Calc FPS
    _frameCount++;
    final now = DateTime.now();
    if (now.difference(_lastFpsUpdate).inMilliseconds >= 1000) {
      _fps = _frameCount.toDouble();
      _frameCount = 0;
      _lastFpsUpdate = now;
    }
  }

  void start() {
    if (!_ticker.isActive) {
      _lastElapsed = null;
      _ticker.start();
    }
  }

  void stop() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }
}

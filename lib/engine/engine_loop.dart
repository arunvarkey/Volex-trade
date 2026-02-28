import 'package:flutter/material.dart';
import 'chart_controller.dart';
import 'execution_manager.dart';
import 'physics.dart';

/// The "Game Loop". Isolates logic from the UI.
/// Orchestrates Data -> Physics -> State Updates -> Execution.
class EngineLoop {
  final ChartController controller;
  final ExecutionManager executionManager;

  // Physics State
  double _velocity = 0.0;
  static const double kFriction = 0.95;

  EngineLoop(this.controller, this.executionManager);

  void update(double dt) {
    // 1. Apply Inertia (Momentum) via Physics Engine
    if (_velocity.abs() > Physics.kMinVelocity) {
      final newOffset = controller.scrollOffset + (_velocity * dt);
      // We rely on controller to clamp HARD bounds, but physics could dampen near edges
      controller.setScroll(newOffset);
      _velocity = Physics.applyFriction(_velocity, dt);
    } else {
      _velocity = 0.0;
    }

    _checkTriggers();
  }

  void _checkTriggers() {
    if (controller.allCandles.isEmpty) return;

    final currentCandle = controller.allCandles.last;
    final currentPrice = currentCandle.close;
    final currentIndex = controller.allCandles.length - 1;

    // PnL Update
    executionManager.updateUnrealizedPnl(currentPrice);

    for (final zone in controller.zones) {
      if (zone.isTriggered) continue;

      if (zone.contains(currentPrice, currentIndex)) {
        zone.isTriggered = true;
        // EXECUTION TRIGGER
        executionManager.onZoneTrigger(zone, currentCandle);
      }
    }
  }

  // Need to track start zoom for smooth scaling
  double _startZoomLevel = 1.0;

  void onScaleStart(ScaleStartDetails details) {
    _startZoomLevel = controller.zoomLevel;
    _velocity = 0.0; // kill momentum on touch
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 1) {
      // PAN
      controller
          .setScroll(controller.scrollOffset - details.focalPointDelta.dx);
    } else {
      // ZOOM
      final newScale = _startZoomLevel * details.scale;
      // Pass focal point into controller for "anchor" zooming (The "TradingView Feel")
      controller.setZoom(newScale, focalPointX: details.localFocalPoint.dx);
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    // Fling Physics
    _velocity = -details.velocity.pixelsPerSecond.dx;
  }
}

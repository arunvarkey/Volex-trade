import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import '../engine/chart_controller.dart';
import 'candle_painter.dart';
import 'ghost_painter.dart';
import 'trade_zone_painter.dart';
import 'crosshair_painter.dart';
import 'order_painter.dart';
import 'trade_marker_painter.dart';
import '../core/performance_monitor.dart';
import '../ui/design_system/vx_colors.dart';
import '../engine/execution_manager.dart';

class MainCanvasPainter extends CustomPainter {
  final ChartController controller;
  final ExecutionManager executionManager;
  final double fps;

  static final Paint _bgPaint = Paint()..color = VxColors.background;
  static final Paint _gridPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.03)
    ..strokeWidth = 1.0;

  MainCanvasPainter({
    required this.controller,
    required this.executionManager,
    required this.fps,
  }) : super(repaint: Listenable.merge([controller, executionManager]));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _bgPaint);

    final double spacing = 60.0 * controller.zoomLevel;
    final double offsetX = -controller.scrollOffset % spacing;

    for (double x = offsetX; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }

    CandlePainter.paint(canvas, size, controller);
    GhostPainter.paint(canvas, size, controller);
    TradeMarkerPainter.paint(canvas, size, controller);
    TradeZonePainter.paint(canvas, size, controller);
    OrderPainter.paint(canvas, size, controller, executionManager);
    CrosshairPainter.paint(canvas, size, controller);

    PerformanceMonitor().end('paint');
    _drawDebugInfo(canvas);
  }

  void _drawDebugInfo(Canvas canvas) {
    const textStyle = TextStyle(
        color: VxColors.neonCyan,
        fontSize: 10,
        fontFamily: VxTypography.monoFamily,
        letterSpacing: 1.2);
    final textSpan = TextSpan(
      text:
          'FPS: ${fps.toStringAsFixed(1)} // ZOOM: ${controller.zoomLevel.toStringAsFixed(2)} // OFFSET: ${controller.scrollOffset.toStringAsFixed(0)}',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: 400,
    );
    textPainter.paint(canvas, const Offset(20, 20));
  }

  @override
  bool shouldRepaint(covariant MainCanvasPainter oldDelegate) {
    return oldDelegate.controller != controller || oldDelegate.fps != fps;
  }
}

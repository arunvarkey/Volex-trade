import 'package:flutter/material.dart';
import 'vx_drawing_models.dart';

/// Custom painter to render drawings on chart
class VxDrawingPainter extends CustomPainter {
  final List<ChartDrawing> drawings;
  final DrawingInProgress? currentDrawing;
  final double minPrice;
  final double maxPrice;
  final int candleCount;

  VxDrawingPainter({
    required this.drawings,
    this.currentDrawing,
    required this.minPrice,
    required this.maxPrice,
    required this.candleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed drawings
    for (final drawing in drawings) {
      _paintDrawing(canvas, size, drawing);
    }

    // Draw in-progress drawing
    if (currentDrawing?.isActive == true) {
      _paintInProgress(canvas, size);
    }
  }

  void _paintDrawing(Canvas canvas, Size size, ChartDrawing drawing) {
    if (drawing is HorizontalLineDrawing) {
      _paintHorizontalLine(canvas, size, drawing);
    } else if (drawing is TrendLineDrawing) {
      _paintTrendLine(canvas, size, drawing);
    } else if (drawing is FibonacciDrawing) {
      _paintFibonacci(canvas, size, drawing);
    } else if (drawing is RectangleDrawing) {
      _paintRectangle(canvas, size, drawing);
    }
  }

  void _paintHorizontalLine(
      Canvas canvas, Size size, HorizontalLineDrawing line) {
    final y = _priceToY(line.price, size.height);

    final paint = Paint()
      ..color = line.color
      ..strokeWidth = line.strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );

    // Draw label
    if (line.label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: line.label,
          style: TextStyle(
            color: line.color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black.withOpacity(0.5),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              size.width - textPainter.width - 8, y - textPainter.height - 4));
    }

    // Draw drag handles (small circles at ends)
    _paintHandle(canvas, Offset(0, y), line.color);
    _paintHandle(canvas, Offset(size.width, y), line.color);
  }

  void _paintTrendLine(Canvas canvas, Size size, TrendLineDrawing trend) {
    final x1 = _indexToX(trend.startIndex, size.width);
    final y1 = _priceToY(trend.startPrice, size.height);
    final x2 = _indexToX(trend.endIndex, size.width);
    final y2 = _priceToY(trend.endPrice, size.height);

    final paint = Paint()
      ..color = trend.color
      ..strokeWidth = trend.strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw line
    if (trend.extend) {
      // Extend to edges
      final slope = (y2 - y1) / (x2 - x1);
      final extendedY1 = y1 - slope * x1;
      final extendedY2 = y1 + slope * (size.width - x1);

      canvas.drawLine(
        Offset(0, extendedY1),
        Offset(size.width, extendedY2),
        paint,
      );
    } else {
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Draw handles
    _paintHandle(canvas, Offset(x1, y1), trend.color);
    _paintHandle(canvas, Offset(x2, y2), trend.color);
  }

  void _paintFibonacci(Canvas canvas, Size size, FibonacciDrawing fib) {
    final x1 = _indexToX(fib.startIndex, size.width);
    final x2 = _indexToX(fib.endIndex, size.width);

    final dashedPaint = Paint()
      ..color = fib.color.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final range = fib.endPrice - fib.startPrice;

    for (final level in fib.levels) {
      final price = fib.startPrice + (range * level);
      final y = _priceToY(price, size.height);

      // Draw dashed line
      _drawDashedLine(canvas, Offset(x1, y), Offset(x2, y), dashedPaint);

      // Draw label
      final label =
          '${(level * 100).toStringAsFixed(1)}% (${price.toStringAsFixed(2)})';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: fib.color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            backgroundColor: Colors.black.withOpacity(0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x2 + 8, y - textPainter.height / 2));
    }

    // Draw handles at start/end
    _paintHandle(
        canvas, Offset(x1, _priceToY(fib.startPrice, size.height)), fib.color);
    _paintHandle(
        canvas, Offset(x2, _priceToY(fib.endPrice, size.height)), fib.color);
  }

  void _paintRectangle(Canvas canvas, Size size, RectangleDrawing rect) {
    final x1 = _indexToX(rect.startIndex, size.width);
    final x2 = _indexToX(rect.endIndex, size.width);
    final y1 = _priceToY(rect.topPrice, size.height);
    final y2 = _priceToY(rect.bottomPrice, size.height);

    final rectObj = Rect.fromLTRB(x1, y1, x2, y2);

    // Fill
    if (rect.filled) {
      final fillPaint = Paint()
        ..color = rect.color.withOpacity(rect.fillOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rectObj, fillPaint);
    }

    // Border
    final borderPaint = Paint()
      ..color = rect.color
      ..strokeWidth = rect.strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rectObj, borderPaint);

    // Handles at corners
    _paintHandle(canvas, Offset(x1, y1), rect.color);
    _paintHandle(canvas, Offset(x2, y1), rect.color);
    _paintHandle(canvas, Offset(x1, y2), rect.color);
    _paintHandle(canvas, Offset(x2, y2), rect.color);
  }

  void _paintInProgress(Canvas canvas, Size size) {
    if (currentDrawing == null || currentDrawing!.startPoint == null) return;

    final start = currentDrawing!.startPoint!;
    final current = currentDrawing!.currentPoint ?? start;

    final x1 = _indexToX(start.dx.toInt(), size.width);
    final y1 = _priceToY(start.dy, size.height);
    final x2 = _indexToX(current.dx.toInt(), size.width);
    final y2 = _priceToY(current.dy, size.height);

    final paint = Paint()
      ..color = currentDrawing!.tool.color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    switch (currentDrawing!.tool) {
      case DrawingTool.trendLine:
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        break;

      case DrawingTool.fibonacci:
        // Show preview lines
        final range = current.dy - start.dy;
        for (final level in [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0]) {
          final price = start.dy + (range * level);
          final y = _priceToY(price, size.height);
          _drawDashedLine(
            canvas,
            Offset(x1, y),
            Offset(x2, y),
            paint..color = currentDrawing!.tool.color.withOpacity(0.3),
          );
        }
        break;

      case DrawingTool.rectangle:
        final rect = Rect.fromLTRB(x1, y1, x2, y2);
        canvas.drawRect(rect, paint);
        break;

      default:
        break;
    }

    // Draw start point
    _paintHandle(canvas, Offset(x1, y1), currentDrawing!.tool.color);
  }

  void _paintHandle(Canvas canvas, Offset position, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 4, paint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(position, 4, borderPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final distance = (end - start).distance;
    final normalizedVector = (end - start) / distance;

    var currentDistance = 0.0;
    while (currentDistance < distance) {
      final dashEnd = currentDistance + dashWidth;
      if (dashEnd > distance) break;

      canvas.drawLine(
        start + normalizedVector * currentDistance,
        start + normalizedVector * dashEnd,
        paint,
      );

      currentDistance += dashWidth + dashSpace;
    }
  }

  double _indexToX(int index, double width) {
    if (candleCount == 0) return 0;
    return (index / candleCount) * width;
  }

  double _priceToY(double price, double height) {
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return height / 2;
    return height - ((price - minPrice) / priceRange * height);
  }

  @override
  bool shouldRepaint(VxDrawingPainter oldDelegate) {
    return drawings != oldDelegate.drawings ||
        currentDrawing != oldDelegate.currentDrawing ||
        minPrice != oldDelegate.minPrice ||
        maxPrice != oldDelegate.maxPrice ||
        candleCount != oldDelegate.candleCount;
  }
}

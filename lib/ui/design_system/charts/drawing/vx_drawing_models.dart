import 'package:flutter/material.dart';
import '../../vx_colors.dart';

/// Base class for all drawing objects
abstract class ChartDrawing {
  final String id;
  final Color color;
  final double strokeWidth;
  final DateTime createdAt;

  ChartDrawing({
    required this.id,
    required this.color,
    this.strokeWidth = 2.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert drawing to be rendered on chart
  Map<String, dynamic> toRenderData();

  /// Check if point is near this drawing (for selection/deletion)
  bool isNear(Offset point, Size chartSize);

  /// Create a copy with modifications
  ChartDrawing copyWith();
}

/// Horizontal Line (Support/Resistance)
class HorizontalLineDrawing extends ChartDrawing {
  final double price;
  final String? label;

  HorizontalLineDrawing({
    required super.id,
    required this.price,
    this.label,
    super.color = VxColors.neonCyan,
    super.strokeWidth,
  });

  @override
  Map<String, dynamic> toRenderData() {
    return {
      'type': 'horizontal',
      'price': price,
      'color': color,
      'strokeWidth': strokeWidth,
      'label': label,
    };
  }

  @override
  bool isNear(Offset point, Size chartSize) {
    // Check if tap is within 20 pixels of the line
    return (point.dy - price).abs() < 20;
  }

  @override
  ChartDrawing copyWith({double? price, String? label, Color? color}) {
    return HorizontalLineDrawing(
      id: id,
      price: price ?? this.price,
      label: label ?? this.label,
      color: color ?? this.color,
      strokeWidth: strokeWidth,
    );
  }
}

/// Trend Line (Diagonal)
class TrendLineDrawing extends ChartDrawing {
  final int startIndex;
  final double startPrice;
  final int endIndex;
  final double endPrice;
  final bool extend; // Extend line to edges

  TrendLineDrawing({
    required super.id,
    required this.startIndex,
    required this.startPrice,
    required this.endIndex,
    required this.endPrice,
    this.extend = false,
    super.color = VxColors.neonPurple,
    super.strokeWidth,
  });

  @override
  Map<String, dynamic> toRenderData() {
    return {
      'type': 'trend',
      'startIndex': startIndex,
      'startPrice': startPrice,
      'endIndex': endIndex,
      'endPrice': endPrice,
      'extend': extend,
      'color': color,
      'strokeWidth': strokeWidth,
    };
  }

  @override
  bool isNear(Offset point, Size chartSize) {
    // Calculate distance from point to line segment
    // Simplified: check if point is near start or end
    final startDist =
        (point.dx - startIndex).abs() + (point.dy - startPrice).abs();
    final endDist = (point.dx - endIndex).abs() + (point.dy - endPrice).abs();
    return startDist < 30 || endDist < 30;
  }

  @override
  ChartDrawing copyWith({
    int? startIndex,
    double? startPrice,
    int? endIndex,
    double? endPrice,
    bool? extend,
    Color? color,
  }) {
    return TrendLineDrawing(
      id: id,
      startIndex: startIndex ?? this.startIndex,
      startPrice: startPrice ?? this.startPrice,
      endIndex: endIndex ?? this.endIndex,
      endPrice: endPrice ?? this.endPrice,
      extend: extend ?? this.extend,
      color: color ?? this.color,
      strokeWidth: strokeWidth,
    );
  }

  double get slope {
    if (endIndex == startIndex) return 0;
    return (endPrice - startPrice) / (endIndex - startIndex);
  }

  double priceAtIndex(int index) {
    return startPrice + slope * (index - startIndex);
  }
}

/// Fibonacci Retracement
class FibonacciDrawing extends ChartDrawing {
  final int startIndex;
  final double startPrice;
  final int endIndex;
  final double endPrice;
  final List<double> levels; // [0.236, 0.382, 0.5, 0.618, 0.786]

  FibonacciDrawing({
    required super.id,
    required this.startIndex,
    required this.startPrice,
    required this.endIndex,
    required this.endPrice,
    List<double>? levels,
    super.color = const Color(0xFFFFAA00),
    super.strokeWidth = 1.5,
  }) : levels = levels ?? [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];

  @override
  Map<String, dynamic> toRenderData() {
    final range = endPrice - startPrice;
    return {
      'type': 'fibonacci',
      'startIndex': startIndex,
      'endIndex': endIndex,
      'levels': levels.map((level) {
        return {
          'level': level,
          'price': startPrice + (range * level),
          'label': '${(level * 100).toStringAsFixed(1)}%',
        };
      }).toList(),
      'color': color,
      'strokeWidth': strokeWidth,
    };
  }

  @override
  bool isNear(Offset point, Size chartSize) {
    // Check if near any fib level
    final range = endPrice - startPrice;
    for (final level in levels) {
      final price = startPrice + (range * level);
      if ((point.dy - price).abs() < 15) return true;
    }
    return false;
  }

  @override
  ChartDrawing copyWith({
    int? startIndex,
    double? startPrice,
    int? endIndex,
    double? endPrice,
    List<double>? levels,
    Color? color,
  }) {
    return FibonacciDrawing(
      id: id,
      startIndex: startIndex ?? this.startIndex,
      startPrice: startPrice ?? this.startPrice,
      endIndex: endIndex ?? this.endIndex,
      endPrice: endPrice ?? this.endPrice,
      levels: levels ?? this.levels,
      color: color ?? this.color,
      strokeWidth: strokeWidth,
    );
  }
}

/// Rectangle (Price Zone/Range)
class RectangleDrawing extends ChartDrawing {
  final int startIndex;
  final double topPrice;
  final int endIndex;
  final double bottomPrice;
  final bool filled;
  final double fillOpacity;

  RectangleDrawing({
    required super.id,
    required this.startIndex,
    required this.topPrice,
    required this.endIndex,
    required this.bottomPrice,
    this.filled = true,
    this.fillOpacity = 0.1,
    super.color = VxColors.neonGreen,
    super.strokeWidth,
  });

  @override
  Map<String, dynamic> toRenderData() {
    return {
      'type': 'rectangle',
      'startIndex': startIndex,
      'topPrice': topPrice,
      'endIndex': endIndex,
      'bottomPrice': bottomPrice,
      'filled': filled,
      'fillOpacity': fillOpacity,
      'color': color,
      'strokeWidth': strokeWidth,
    };
  }

  @override
  bool isNear(Offset point, Size chartSize) {
    // Check if point is inside or near rectangle border
    final insideX = point.dx >= startIndex && point.dx <= endIndex;
    final insideY = point.dy >= bottomPrice && point.dy <= topPrice;

    if (filled && insideX && insideY) return true;

    // Check near borders
    final nearLeft = (point.dx - startIndex).abs() < 15;
    final nearRight = (point.dx - endIndex).abs() < 15;
    final nearTop = (point.dy - topPrice).abs() < 15;
    final nearBottom = (point.dy - bottomPrice).abs() < 15;

    return (nearLeft || nearRight) && insideY ||
        (nearTop || nearBottom) && insideX;
  }

  @override
  ChartDrawing copyWith({
    int? startIndex,
    double? topPrice,
    int? endIndex,
    double? bottomPrice,
    bool? filled,
    double? fillOpacity,
    Color? color,
  }) {
    return RectangleDrawing(
      id: id,
      startIndex: startIndex ?? this.startIndex,
      topPrice: topPrice ?? this.topPrice,
      endIndex: endIndex ?? this.endIndex,
      bottomPrice: bottomPrice ?? this.bottomPrice,
      filled: filled ?? this.filled,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      color: color ?? this.color,
      strokeWidth: strokeWidth,
    );
  }
}

/// Drawing Tool Types
enum DrawingTool {
  none,
  horizontalLine,
  trendLine,
  fibonacci,
  rectangle;

  String get label {
    switch (this) {
      case DrawingTool.none:
        return 'Select';
      case DrawingTool.horizontalLine:
        return 'H-Line';
      case DrawingTool.trendLine:
        return 'Trend';
      case DrawingTool.fibonacci:
        return 'Fib';
      case DrawingTool.rectangle:
        return 'Box';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawingTool.none:
        return Icons.touch_app;
      case DrawingTool.horizontalLine:
        return Icons.horizontal_rule;
      case DrawingTool.trendLine:
        return Icons.trending_up;
      case DrawingTool.fibonacci:
        return Icons.analytics_outlined;
      case DrawingTool.rectangle:
        return Icons.crop_square;
    }
  }

  Color get color {
    switch (this) {
      case DrawingTool.none:
        return Colors.white54;
      case DrawingTool.horizontalLine:
        return VxColors.neonCyan;
      case DrawingTool.trendLine:
        return VxColors.neonPurple;
      case DrawingTool.fibonacci:
        return const Color(0xFFFFAA00);
      case DrawingTool.rectangle:
        return VxColors.neonGreen;
    }
  }
}

/// Drawing state for temporary drawing in progress
class DrawingInProgress {
  final DrawingTool tool;
  final Offset? startPoint;
  final Offset? currentPoint;

  DrawingInProgress({
    required this.tool,
    this.startPoint,
    this.currentPoint,
  });

  bool get isActive => startPoint != null;

  DrawingInProgress copyWith({
    DrawingTool? tool,
    Offset? startPoint,
    Offset? currentPoint,
    bool clearStart = false,
    bool clearCurrent = false,
  }) {
    return DrawingInProgress(
      tool: tool ?? this.tool,
      startPoint: clearStart ? null : (startPoint ?? this.startPoint),
      currentPoint: clearCurrent ? null : (currentPoint ?? this.currentPoint),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:volex_terminal/domain/candle_model.dart';
import 'vx_drawing_models.dart';
import 'vx_drawing_toolbar.dart';
import 'vx_drawing_painter.dart';
import '../../vx_colors.dart';
import '../vx_enhanced_chart.dart';

/// Chart with interactive drawing capabilities
class VxDrawableChart extends StatefulWidget {
  final List<Candle> candles;
  final bool showDrawingTools;

  const VxDrawableChart({
    super.key,
    required this.candles,
    this.showDrawingTools = true,
  });

  @override
  State<VxDrawableChart> createState() => _VxDrawableChartState();
}

class _VxDrawableChartState extends State<VxDrawableChart> {
  // Drawing state
  DrawingTool _selectedTool = DrawingTool.none;
  final List<ChartDrawing> _drawings = [];
  DrawingInProgress? _currentDrawing;

  // Chart bounds for coordinate conversion
  double _minPrice = 0;
  double _maxPrice = 0;
  int _candleCount = 0;

  @override
  void initState() {
    super.initState();
    _updateChartBounds();
  }

  @override
  void didUpdateWidget(VxDrawableChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles != widget.candles) {
      _updateChartBounds();
    }
  }

  void _updateChartBounds() {
    if (widget.candles.isEmpty) return;

    _minPrice =
        widget.candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    _maxPrice =
        widget.candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    _candleCount = widget.candles.length;

    final buffer = (_maxPrice - _minPrice) * 0.1;
    _minPrice -= buffer;
    _maxPrice += buffer;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base chart
        GestureDetector(
          onTapDown: _selectedTool != DrawingTool.none ? _handleTapDown : null,
          onPanUpdate:
              _selectedTool != DrawingTool.none ? _handlePanUpdate : null,
          onPanEnd: _selectedTool != DrawingTool.none ? _handlePanEnd : null,
          child: Stack(
            children: [
              VxEnhancedChart(
                candles: widget.candles,
                showControls: !widget.showDrawingTools,
              ),

              // Drawing overlay
              CustomPaint(
                painter: VxDrawingPainter(
                  drawings: _drawings,
                  currentDrawing: _currentDrawing,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                  candleCount: _candleCount,
                ),
                child: Container(), // Full size overlay
              ),
            ],
          ),
        ),

        // Drawing toolbar
        if (widget.showDrawingTools)
          Positioned(
            left: 8,
            top: 8,
            child: VxDrawingToolbar(
              selectedTool: _selectedTool,
              onToolSelected: (tool) {
                setState(() {
                  _selectedTool = tool;
                  _currentDrawing = null;
                });
              },
              onClearAll: () {
                setState(() {
                  _drawings.clear();
                });
              },
              onUndo: () {
                if (_drawings.isNotEmpty) {
                  setState(() {
                    _drawings.removeLast();
                  });
                }
              },
              hasDrawings: _drawings.isNotEmpty,
            ),
          ),

        // Instructions
        if (_selectedTool != DrawingTool.none)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VxDrawingInfoPanel(selectedTool: _selectedTool),
          ),
      ],
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;

    // Convert screen coordinates to chart coordinates
    final size = renderBox.size;
    final chartPoint = _screenToChart(localPosition, size);

    if (chartPoint == null) return;

    setState(() {
      switch (_selectedTool) {
        case DrawingTool.horizontalLine:
          _createHorizontalLine(chartPoint);
          break;

        case DrawingTool.trendLine:
        case DrawingTool.fibonacci:
        case DrawingTool.rectangle:
          if (_currentDrawing == null) {
            // Start drawing
            _currentDrawing = DrawingInProgress(
              tool: _selectedTool,
              startPoint: chartPoint,
            );
          } else {
            // Finish drawing
            _finishDrawing(chartPoint);
          }
          break;

        case DrawingTool.none:
          // Check if tapping on existing drawing to delete
          _checkDrawingSelection(chartPoint);
          break;
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_currentDrawing == null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final chartPoint = _screenToChart(details.localPosition, size);

    if (chartPoint == null) return;

    setState(() {
      _currentDrawing = _currentDrawing!.copyWith(currentPoint: chartPoint);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_currentDrawing?.currentPoint != null) {
      _finishDrawing(_currentDrawing!.currentPoint!);
    }
  }

  Offset? _screenToChart(Offset screenPos, Size size) {
    // Convert screen position to chart coordinates
    // X: candle index, Y: price

    // Simple safety check for division by zero
    if (size.width == 0 || size.height == 0) return null;

    final xRatio = screenPos.dx / size.width;
    final yRatio = 1 - (screenPos.dy / size.height); // Invert Y

    final candleIndex =
        (xRatio * _candleCount).round().clamp(0, _candleCount - 1);
    final price = _minPrice + (yRatio * (_maxPrice - _minPrice));

    return Offset(candleIndex.toDouble(), price);
  }

  void _createHorizontalLine(Offset point) {
    final line = HorizontalLineDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      price: point.dy,
      label: point.dy.toStringAsFixed(2),
      color: DrawingTool.horizontalLine.color,
    );

    _drawings.add(line);
    _selectedTool = DrawingTool.none; // Auto-deselect after drawing
  }

  void _finishDrawing(Offset endPoint) {
    if (_currentDrawing?.startPoint == null) return;

    final start = _currentDrawing!.startPoint!;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    ChartDrawing? drawing;

    switch (_selectedTool) {
      case DrawingTool.trendLine:
        drawing = TrendLineDrawing(
          id: id,
          startIndex: start.dx.toInt(),
          startPrice: start.dy,
          endIndex: endPoint.dx.toInt(),
          endPrice: endPoint.dy,
          color: DrawingTool.trendLine.color,
        );
        break;

      case DrawingTool.fibonacci:
        drawing = FibonacciDrawing(
          id: id,
          startIndex: start.dx.toInt(),
          startPrice: start.dy,
          endIndex: endPoint.dx.toInt(),
          endPrice: endPoint.dy,
          color: DrawingTool.fibonacci.color,
        );
        break;

      case DrawingTool.rectangle:
        final topPrice = start.dy > endPoint.dy ? start.dy : endPoint.dy;
        final bottomPrice = start.dy < endPoint.dy ? start.dy : endPoint.dy;

        drawing = RectangleDrawing(
          id: id,
          startIndex: start.dx.toInt(),
          topPrice: topPrice,
          endIndex: endPoint.dx.toInt(),
          bottomPrice: bottomPrice,
          color: DrawingTool.rectangle.color,
        );
        break;

      default:
        break;
    }

    if (drawing != null) {
      setState(() {
        _drawings.add(drawing!);
        _currentDrawing = null;
        _selectedTool = DrawingTool.none; // Auto-deselect
      });
    }
  }

  void _checkDrawingSelection(Offset point) {
    // Find and remove drawing near tap point
    for (int i = _drawings.length - 1; i >= 0; i--) {
      final drawing = _drawings[i];
      if (drawing.isNear(
          point, Size(_candleCount.toDouble(), _maxPrice - _minPrice))) {
        _showDeleteDrawingDialog(i);
        break;
      }
    }
  }

  void _showDeleteDrawingDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Drawing?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to remove this drawing from the chart?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _drawings.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

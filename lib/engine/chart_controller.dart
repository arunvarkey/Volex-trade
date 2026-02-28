import 'package:flutter/material.dart';
import '../domain/candle_model.dart';
import '../domain/ghost_model.dart';
import '../domain/trade_zone.dart';
import '../domain/trade_signal.dart';
import 'linear_regression_service.dart';
import 'package:uuid/uuid.dart';
import 'chart_enums.dart';
import 'trading/visual_order.dart';
import 'trading/trade_marker.dart';

/// Pure State Controller.
/// Stores the View Transform (Offset, Zoom) and Visible Range.
/// No business logic here.

class ChartController extends ChangeNotifier {
  ChartController();
  // --- View State ---
  double _scrollOffset = 0.0;
  double _zoomLevel = 1.0; // 1.0 = Default (e.g. 10px per candle)

  // --- Configuration ---
  static const double kMinZoom = 0.1;
  static const double kMaxZoom = 20.0;
  static const double kDefaultCandleWidth = 10.0;

  // --- Modes ---
  ChartMode _mode = ChartMode.area; // Default to sleek area
  ChartTimeframe _timeframe = ChartTimeframe.m1;

  ChartMode get mode => _mode;
  ChartTimeframe get timeframe => _timeframe;

  void setMode(ChartMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setTimeframe(ChartTimeframe tf) {
    _timeframe = tf;
    // Logic to request new data granularity from Pipeline would go here
    notifyListeners();
  }

  // --- Getters ---
  double get scrollOffset => _scrollOffset;
  double get zoomLevel => _zoomLevel;
  double get candleWidth => kDefaultCandleWidth * _zoomLevel;

  // --- Data ---
  List<Candle> _allCandles = [];
  List<Candle> get allCandles => _allCandles;

  // --- AI Ghost ---
  GhostModel? _ghost;
  GhostModel? get ghost => _ghost;

  // --- Visual Orders (Drag-to-Trade) ---
  final List<VisualOrder> _visualOrders = [];
  List<VisualOrder> get visualOrders => _visualOrders;

  // --- Historical Trade Markers (Backtest/Live) ---
  final List<TradeMarker> _tradeMarkers = [];
  List<TradeMarker> get tradeMarkers => _tradeMarkers;

  // --- Strategy Signals (Visual Backtesting) ---
  final List<TradeSignal> _signals = [];
  List<TradeSignal> get signals => _signals;

  void addSignal(TradeSignal signal) {
    _signals.add(signal);
    notifyListeners();
  }

  void clearSignals() {
    _signals.clear();
    notifyListeners();
  }

  void addTradeMarkers(List<TradeMarker> markers) {
    _tradeMarkers.addAll(markers);
    notifyListeners();
  }

  void clearTradeMarkers() {
    _tradeMarkers.clear();
    notifyListeners();
  }

  void addVisualOrder(VisualOrder order) {
    _visualOrders.add(order);
    notifyListeners();
  }

  void updateVisualOrderPrice(String id, double newPrice) {
    final index = _visualOrders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _visualOrders[index].price = newPrice;
      notifyListeners();
    }
  }

  void removeVisualOrder(String id) {
    _visualOrders.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  void clearVisualOrders() {
    _visualOrders.clear();
    notifyListeners();
  }

  // --- Derived State (Precomputed for Painter) ---
  // --- Derived State (Visible Metrics) ---
  int _startIndex = 0;
  int _endIndex = 0;
  double _minPrice = 0.0;
  double _maxPrice = 0.0; // Y-Axis range for current view

  int get startIndex => _startIndex;
  int get endIndex => _endIndex;
  double get minVisiblePrice => _minPrice;
  double get maxVisiblePrice => _maxPrice;

  // --- Coordinate Mapping (The Backbone) ---

  /// X-Pixel to Candle Index
  int xToIndex(double x) {
    return ((x + _scrollOffset) / candleWidth).floor();
  }

  /// Candle Index to X-Pixel (Center of candle)
  double indexToX(int index) {
    return (index * candleWidth) - _scrollOffset + (candleWidth / 2);
  }

  /// Price to Y-Pixel
  double priceToY(double price, double height) {
    final range = _maxPrice - _minPrice;
    if (range <= 0) return height / 2;
    // Inverted Y: 0 is top (High Price)
    return height - ((price - _minPrice) / range * height);
  }

  /// Y-Pixel to Price
  // (Useful for Sketch-to-Trade later)
  double yToPrice(double y, double height) {
    final range = _maxPrice - _minPrice;
    if (range <= 0) return 0;
    // inverted
    final normalizedY = (height - y) / height;
    return _minPrice + (normalizedY * range);
  }

  // --- Mutators ---

  void setData(List<Candle> data, {bool preserveState = false}) {
    _allCandles = data;

    if (!preserveState) {
      _signals.clear();
      _tradeMarkers.clear();
    }

    // Initial scroll to end if it's a fresh load
    if (!preserveState) {
      _scrollOffset = (_allCandles.length * kDefaultCandleWidth) - 1000;
    }

    _recalculateVisibleRange();
    _updateGhost();
    notifyListeners();
  }

  void _updateGhost() {
    _ghost = LinearRegressionService.compute(_allCandles,
        period: 100, projectForward: 20);
  }

  /// Live Update Logic
  void updateLastCandle(Candle newCandle) {
    if (_allCandles.isEmpty) {
      _allCandles.add(newCandle);
      notifyListeners();
      return;
    }

    final last = _allCandles.last;
    if (newCandle.time > last.time) {
      // New Candle (Close confirmed by time step)
      _allCandles.add(newCandle);
      // Auto-scroll if we were at the edge?
      // For MVP, simple physics-less auto-scroll if near end
      // if (_scrollOffset > ...) setScroll(...);
    } else if (newCandle.time == last.time) {
      // Update existing
      _allCandles[_allCandles.length - 1] = newCandle;
    } else {
      // Out of order? Ignore for now
      return;
    }

    // Efficiently recalulate only if needed?
    // Data changed, so yes.
    _recalculateVisibleRange();
    _updateGhost();
    notifyListeners();
  }

  void setScroll(double offset) {
    // Physics engine handles clamping/fling, controller just stores state
    // But we clamp hard limits here to prevent crashes
    if (_allCandles.isEmpty) return;
    final maxScroll =
        (_allCandles.length * candleWidth) + 2000; // Overscroll allowed
    _scrollOffset = offset.clamp(-1000.0, maxScroll);

    _recalculateVisibleRange();
    notifyListeners();
  }

  /// Smart Zoom with Focal Point
  void setZoom(double newZoom, {double? focalPointX, double? screenWidth}) {
    if (_allCandles.isEmpty) return;

    final oldZoom = _zoomLevel;
    final clampedZoom = newZoom.clamp(kMinZoom, kMaxZoom);

    if (clampedZoom == oldZoom) return;

    // FOCAL POINT MATH:
    // To keep the candle under 'focalPointX' stationary, we must adjust scrollOffset.
    // worldX = pixelX + scrollOffset
    // We want worldX (the data point) to stay at pixelX.

    if (focalPointX != null) {
      // 1. Calculate where the world point is currently
      final worldXOld = focalPointX + _scrollOffset;

      // 2. Calculate the "Index" of that world point (floating point index)
      final candleIndex =
          worldXOld / (kDefaultCandleWidth * oldZoom); // old candle width

      // 3. New Candle Width
      final newCandleWidth = kDefaultCandleWidth * clampedZoom;

      // 4. New WorldX for that same index
      final worldXNew = candleIndex * newCandleWidth;

      // 5. New Scroll Offset
      // We want: worldX_New - newScrollOffset = focalPointX
      // So: newScrollOffset = worldX_New - focalPointX
      _scrollOffset = worldXNew - focalPointX;
    }

    _zoomLevel = clampedZoom;
    _recalculateVisibleRange();
    notifyListeners();
  }

  void _recalculateVisibleRange() {
    if (_allCandles.isEmpty) return;

    const screenWidth =
        2000.0; // Assume logical max width for now (Painter filters precise)
    // In a real engine, we'd pass viewport width to the controller.
    // For now we just over-calculate slightly.

    final candleW = candleWidth;

    // Calculate indices based on scroll offset
    // Offset 0 = Index 0? No, usually charts scroll from Right.
    // Let's assume Left-to-Right for MVP. Index 0 is at x=0.

    int start = (_scrollOffset / candleW).floor();
    int count = (screenWidth / candleW).ceil();

    _startIndex = start.clamp(0, _allCandles.length - 1);
    _endIndex = (start + count).clamp(0, _allCandles.length - 1);

    // Calculate Y-Range (Min/Max Price) for the visible window
    // This enables the chart to "auto-scale" VERTICALLY as you scroll.
    double minP = double.infinity;
    double maxP = double.negativeInfinity;

    // Optimization: sampling step for large zoom-outs to avoid O(N) loop on 10k items
    // If showing > 500 candles, skip some
    int step = 1;
    if ((_endIndex - _startIndex) > 500) {
      step = (_endIndex - _startIndex) ~/ 500;
    }

    bool found = false;
    for (int i = _startIndex; i <= _endIndex; i += step) {
      final c = _allCandles[i];
      if (c.low < minP) minP = c.low;
      if (c.high > maxP) maxP = c.high;
      found = true;
    }

    if (!found) {
      // Fallback
      _minPrice = 0;
      _maxPrice = 100;
      return;
    }

    // Add padding (5% top/bottom)
    final padding = (maxP - minP) * 0.05;
    _minPrice = minP - padding;
    _maxPrice = maxP + padding;
  }

  // --- Crosshair State ---
  Offset? _crosshairOffset;
  Offset? get crosshairOffset => _crosshairOffset;

  void setCrosshair(Offset? offset) {
    if (_crosshairOffset == offset) return;
    _crosshairOffset = offset;
    notifyListeners();
  }

  // --- Drawing State (Sketch-to-Trade) ---
  bool _isDrawing = false;
  Offset? _activeDragStart;
  Offset? _activeDragEnd;

  final List<TradeZone> _zones = [];
  List<TradeZone> get zones => _zones;

  bool get isDrawing => _isDrawing;
  Offset? get activeDragStart => _activeDragStart;
  Offset? get activeDragEnd => _activeDragEnd;

  void startDrawing(Offset startPixel) {
    _isDrawing = true;
    _activeDragStart = startPixel;
    _activeDragEnd = startPixel;
    notifyListeners();
  }

  void updateDrawing(Offset currentPixel) {
    if (!_isDrawing) return;
    _activeDragEnd = currentPixel;
    notifyListeners();
  }

  void finalizeDrawing(double height) {
    if (!_isDrawing || _activeDragStart == null || _activeDragEnd == null) {
      _isDrawing = false;
      notifyListeners();
      return;
    }

    // Y-Axis (Price)
    final y1 = _activeDragStart!.dy;
    final y2 = _activeDragEnd!.dy;
    // X-Axis (Index)
    final x1 = _activeDragStart!.dx;
    final x2 = _activeDragEnd!.dx;

    final price1 = yToPrice(y1, height);
    final price2 = yToPrice(y2, height);

    final index1 = xToIndex(x1);
    final index2 = xToIndex(x2);

    // Normalize
    final minP = (price1 < price2) ? price1 : price2;
    final maxP = (price1 > price2) ? price1 : price2;

    final startI = (index1 < index2) ? index1 : index2;
    final endI = (index1 > index2) ? index1 : index2;

    final zone = TradeZone(
      id: const Uuid().v4(),
      minPrice: minP,
      maxPrice: maxP,
      startIndex: startI,
      endIndex: endI,
      symbol: "BTCUSDT", // Default for now, should come from context
      direction: y1 > y2
          ? ZoneDirection.long
          : ZoneDirection
              .short, // Mouse Drag Down (Y increases down) = Short intent? Wait, standard coords: Y=0 at TOP.
      // Drag Top (y1) to Bottom (y2) :: y1 < y2.
      // If Top (High Price) to Bottom (Low Price): Looking for Short entry?
      // Let's standard: Drag GREEN (Up) = Long, RED (Down) = Short.
      // Price1 (Start) -> Price2 (End).
      // If Price2 > Price1 => Long.
      // If Price2 < Price1 => Short.
    );

    _zones.add(zone);

    _isDrawing = false;
    _activeDragStart = null;
    _activeDragEnd = null;
    notifyListeners();
  }

  void restoreZones(List<TradeZone> zones) {
    _zones.clear();
    _zones.addAll(zones);
    notifyListeners();
  }

  // --- Zone Management ---
  int? _selectedZoneIndex;
  int? get selectedZoneIndex => _selectedZoneIndex;

  void selectZoneAt(Offset tapPixel, double height) {
    final price = yToPrice(tapPixel.dy, height);
    final index = xToIndex(tapPixel.dx);

    _selectedZoneIndex = null;

    // Iterate backwards to select top-most
    for (int i = _zones.length - 1; i >= 0; i--) {
      final zone = _zones[i];
      if (zone.contains(price, index)) {
        _selectedZoneIndex = i;
        break;
      }
    }
    notifyListeners();
  }

  void deleteSelectedZone() {
    if (_selectedZoneIndex != null && _selectedZoneIndex! < _zones.length) {
      _zones.removeAt(_selectedZoneIndex!);
      _selectedZoneIndex = null;
      notifyListeners();
    }
  }

  void clearZones() {
    _zones.clear();
    _selectedZoneIndex = null;
    notifyListeners();
  }
}

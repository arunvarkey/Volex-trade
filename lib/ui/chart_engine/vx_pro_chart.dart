import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'chart_math.dart';

/// VxProChart — Volex's own TradingView-class chart engine.
///
/// A single GPU-painted canvas (no charting library) with the interactions
/// professional traders expect:
///  - pan by dragging, zoom by pinch or mouse wheel
///  - crosshair with OHLC/volume legend (hover on desktop, long-press on touch)
///  - right-hand price axis with a live last-price line and label
///  - volume histogram pane
///  - SMA(20)/SMA(50) overlays
///  - magnitude-aware "nice" price grid and adaptive time axis
class VxProChart extends StatefulWidget {
  final List<Candle> candles;
  final bool showVolume;
  final bool showIndicators;

  /// Accepted for drop-in compatibility with the old chart; not yet rendered.
  final List<dynamic> activeSignals;

  const VxProChart({
    super.key,
    required this.candles,
    this.showVolume = true,
    this.showIndicators = true,
    this.activeSignals = const [],
  });

  @override
  State<VxProChart> createState() => _VxProChartState();
}

class _VxProChartState extends State<VxProChart> {
  static const int _minVisible = 15;
  static const int _maxVisible = 400;

  int _visibleCount = 90;
  int _rightIndex = 0;
  bool _followLatest = true;

  Offset? _cursor;

  // Gesture bookkeeping
  double _scaleStartVisible = 90;
  int _scaleStartRight = 0;

  @override
  void initState() {
    super.initState();
    _snapToLatest();
  }

  @override
  void didUpdateWidget(covariant VxProChart old) {
    super.didUpdateWidget(old);
    final n = widget.candles.length;
    if (n == 0) return;
    if (_followLatest || _rightIndex >= n) {
      _rightIndex = n - 1;
    }
  }

  void _snapToLatest() {
    final n = widget.candles.length;
    if (n == 0) return;
    _rightIndex = n - 1;
    _visibleCount = math.min(_visibleCount, math.max(_minVisible, n));
    _followLatest = true;
  }

  void _clampView() {
    final n = widget.candles.length;
    if (n == 0) return;
    _visibleCount =
        _visibleCount.clamp(_minVisible, math.min(_maxVisible, math.max(_minVisible, n)));
    _rightIndex = _rightIndex.clamp(math.min(_visibleCount - 1, n - 1), n - 1);
    _followLatest = _rightIndex >= n - 1;
  }

  void _zoomBy(double factor) {
    setState(() {
      _visibleCount = (_visibleCount * factor).round();
      _clampView();
    });
  }

  // ── Gestures ──────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _scaleStartVisible = _visibleCount.toDouble();
    _scaleStartRight = _rightIndex;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, double candleWidth) {
    setState(() {
      if (d.scale != 1.0) {
        _visibleCount = (_scaleStartVisible / d.scale).round();
      }
      if (candleWidth > 0) {
        final deltaCandles = d.focalPointDelta.dx / candleWidth;
        _rightIndex = (_rightIndex - deltaCandles).round();
      }
      _clampView();
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _zoomBy(event.scrollDelta.dy > 0 ? 1.15 : 1 / 1.15);
    }
  }

  void _setCursor(Offset? position) {
    setState(() => _cursor = position);
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: VxColors.neonCyan),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final chartWidth =
          constraints.maxWidth - _ProChartPainter.priceAxisWidth;
      final candleWidth = chartWidth / _visibleCount;

      return Listener(
        onPointerSignal: _onPointerSignal,
        child: MouseRegion(
          onHover: (e) => _setCursor(e.localPosition),
          onExit: (_) => _setCursor(null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onScaleStart,
            onScaleUpdate: (d) => _onScaleUpdate(d, candleWidth),
            onLongPressStart: (d) => _setCursor(d.localPosition),
            onLongPressMoveUpdate: (d) => _setCursor(d.localPosition),
            onLongPressEnd: (_) => _setCursor(null),
            onDoubleTap: () => setState(_snapToLatest),
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ProChartPainter(
                candles: widget.candles,
                rightIndex: _rightIndex,
                visibleCount: _visibleCount,
                cursor: _cursor,
                showVolume: widget.showVolume,
                showIndicators: widget.showIndicators,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════
// Painter
// ════════════════════════════════════════════════════════════════════

class _ProChartPainter extends CustomPainter {
  static const double priceAxisWidth = 64;
  static const double timeAxisHeight = 22;
  static const double volumeShare = 0.16;

  final List<Candle> candles;
  final int rightIndex;
  final int visibleCount;
  final Offset? cursor;
  final bool showVolume;
  final bool showIndicators;

  _ProChartPainter({
    required this.candles,
    required this.rightIndex,
    required this.visibleCount,
    required this.cursor,
    required this.showVolume,
    required this.showIndicators,
  });

  late double _chartW;
  late double _chartH;
  late double _priceTop;
  late double _priceBottom;
  late double _minP;
  late double _maxP;
  late int _startIdx;
  late int _endIdx;
  late double _candleW;

  double _y(double price) {
    final range = _maxP - _minP;
    if (range <= 0) return _priceTop + (_priceBottom - _priceTop) / 2;
    return _priceTop +
        (_priceBottom - _priceTop) * (1 - (price - _minP) / range);
  }

  double _x(int index) => (index - _startIdx + 0.5) * _candleW;

  @override
  void paint(Canvas canvas, Size size) {
    _chartW = size.width - priceAxisWidth;
    _chartH = size.height - timeAxisHeight;
    final volH = showVolume ? _chartH * volumeShare : 0.0;
    _priceTop = 8;
    _priceBottom = _chartH - volH - 6;

    _endIdx = rightIndex.clamp(0, candles.length - 1);
    _startIdx = math.max(0, _endIdx - visibleCount + 1);
    final visible = candles.sublist(_startIdx, _endIdx + 1);
    if (visible.isEmpty) return;
    _candleW = _chartW / visibleCount;

    // Price range across visible candles (plus indicator values).
    _minP = double.infinity;
    _maxP = -double.infinity;
    for (final c in visible) {
      _minP = math.min(_minP, c.low);
      _maxP = math.max(_maxP, c.high);
    }
    final pad = (_maxP - _minP) * 0.07;
    _minP -= pad;
    _maxP += pad;

    _drawGrid(canvas);
    if (showVolume) _drawVolume(canvas, visible, volH);
    _drawCandles(canvas, visible);
    if (showIndicators) _drawSmas(canvas);
    _drawLastPrice(canvas);
    _drawTimeAxis(canvas, visible);
    _drawPriceAxis(canvas);
    _drawCrosshair(canvas, size);
    _drawLegend(canvas);
  }

  // ── Grid & axes ───────────────────────────────────────────────────

  List<double> _priceLevels() => ChartMath.priceLevels(_minP, _maxP);

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = VxColors.gridLines.withOpacity(0.55)
      ..strokeWidth = 0.6;
    for (final level in _priceLevels()) {
      final y = _y(level);
      canvas.drawLine(Offset(0, y), Offset(_chartW, y), paint);
    }
    // Vertical grid roughly every 90px.
    final every = math.max(1, (90 / _candleW).round());
    for (int i = _startIdx; i <= _endIdx; i++) {
      if ((candles.length - 1 - i) % every != 0) continue;
      final x = _x(i);
      canvas.drawLine(Offset(x, _priceTop), Offset(x, _chartH), paint);
    }
  }

  String _fmtPrice(double p) {
    if (p >= 1000) return NumberFormat('#,##0.0').format(p);
    if (p >= 100) return p.toStringAsFixed(1);
    if (p >= 1) return p.toStringAsFixed(3);
    return p.toStringAsFixed(5);
  }

  TextPainter _text(String s,
      {double size = 9.5, Color color = VxColors.textTertiary, FontWeight weight = FontWeight.w500}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: GoogleFonts.robotoMono(
            fontSize: size, color: color, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  void _drawPriceAxis(Canvas canvas) {
    // Axis background strip
    canvas.drawRect(
      Rect.fromLTWH(_chartW, 0, priceAxisWidth, _chartH),
      Paint()..color = VxColors.background.withOpacity(0.6),
    );
    canvas.drawLine(Offset(_chartW, 0), Offset(_chartW, _chartH),
        Paint()..color = Colors.white12..strokeWidth = 0.7);
    for (final level in _priceLevels()) {
      final tp = _text(_fmtPrice(level));
      tp.paint(canvas, Offset(_chartW + 6, _y(level) - tp.height / 2));
    }
  }

  void _drawTimeAxis(Canvas canvas, List<Candle> visible) {
    final spanMs = (visible.last.time - visible.first.time).abs();
    final DateFormat fmt;
    if (spanMs > 5 * 24 * 3600 * 1000) {
      fmt = DateFormat('MM/dd');
    } else if (spanMs > 24 * 3600 * 1000) {
      fmt = DateFormat('dd HH:mm');
    } else {
      fmt = DateFormat('HH:mm');
    }
    final every = math.max(1, (90 / _candleW).round());
    for (int i = _startIdx; i <= _endIdx; i++) {
      if ((candles.length - 1 - i) % every != 0) continue;
      final tp = _text(fmt.format(candles[i].date));
      final x = (_x(i) - tp.width / 2).clamp(0.0, _chartW - tp.width);
      tp.paint(canvas, Offset(x, _chartH + 5));
    }
  }

  // ── Series ────────────────────────────────────────────────────────

  void _drawCandles(Canvas canvas, List<Candle> visible) {
    final bodyW = math.max(1.0, _candleW * 0.62);
    final wickPaint = Paint()..strokeWidth = math.max(0.8, _candleW * 0.08);

    for (int i = 0; i < visible.length; i++) {
      final c = visible[i];
      final x = _x(_startIdx + i);
      final color = c.isGreen ? VxColors.neonGreen : VxColors.neonRed;
      wickPaint.color = color;
      canvas.drawLine(
          Offset(x, _y(c.high)), Offset(x, _y(c.low)), wickPaint);

      final top = _y(math.max(c.open, c.close));
      final bottom = _y(math.min(c.open, c.close));
      final rect = Rect.fromLTRB(
          x - bodyW / 2, top, x + bodyW / 2, math.max(bottom, top + 1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        Paint()..color = color,
      );
    }
  }

  void _drawVolume(Canvas canvas, List<Candle> visible, double volH) {
    double maxV = 0;
    for (final c in visible) {
      maxV = math.max(maxV, c.volume);
    }
    if (maxV <= 0) return;
    final base = _chartH - 2;
    final bodyW = math.max(1.0, _candleW * 0.62);
    for (int i = 0; i < visible.length; i++) {
      final c = visible[i];
      final x = _x(_startIdx + i);
      final h = (c.volume / maxV) * (volH - 8);
      final color =
          (c.isGreen ? VxColors.neonGreen : VxColors.neonRed).withOpacity(0.32);
      canvas.drawRect(
        Rect.fromLTRB(x - bodyW / 2, base - h, x + bodyW / 2, base),
        Paint()..color = color,
      );
    }
  }

  double? _sma(int index, int period) {
    if (index + 1 < period) return null;
    double sum = 0;
    for (int i = index - period + 1; i <= index; i++) {
      sum += candles[i].close;
    }
    return sum / period;
  }

  void _drawSmaLine(Canvas canvas, int period, Color color) {
    final path = Path();
    bool started = false;
    for (int i = _startIdx; i <= _endIdx; i++) {
      final v = _sma(i, period);
      if (v == null) continue;
      final p = Offset(_x(i), _y(v));
      if (!started) {
        path.moveTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    if (started) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawSmas(Canvas canvas) {
    _drawSmaLine(canvas, 20, VxColors.neonCyan);
    _drawSmaLine(canvas, 50, VxColors.neonPurple);
  }

  // ── Last price & crosshair ────────────────────────────────────────

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 4, double gap = 4}) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    double covered = 0;
    while (covered < total) {
      final end = math.min(covered + dash, total);
      canvas.drawLine(a + dir * covered, a + dir * end, paint);
      covered = end + gap;
    }
  }

  void _axisTag(Canvas canvas, double y, String label, Color bg) {
    final tp = _text(label, color: Colors.black, weight: FontWeight.w700);
    final rect = Rect.fromLTWH(
        _chartW + 1, y - tp.height / 2 - 3, priceAxisWidth - 2, tp.height + 6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = bg);
    tp.paint(canvas, Offset(_chartW + 6, y - tp.height / 2));
  }

  void _drawLastPrice(Canvas canvas) {
    final last = candles.last;
    if (last.close < _minP || last.close > _maxP) return;
    final y = _y(last.close);
    final color = last.isGreen ? VxColors.neonGreen : VxColors.neonRed;
    _dashedLine(
      canvas,
      Offset(0, y),
      Offset(_chartW, y),
      Paint()
        ..color = color.withOpacity(0.55)
        ..strokeWidth = 0.8,
    );
    _axisTag(canvas, y, _fmtPrice(last.close), color);
  }

  void _drawCrosshair(Canvas canvas, Size size) {
    final c = cursor;
    if (c == null || c.dx < 0 || c.dx > _chartW || c.dy > _chartH) return;

    final idx =
        (_startIdx + (c.dx / _candleW - 0.5).round()).clamp(_startIdx, _endIdx);
    final snapX = _x(idx);

    final paint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 0.7;
    _dashedLine(canvas, Offset(snapX, _priceTop), Offset(snapX, _chartH), paint,
        dash: 3, gap: 3);
    _dashedLine(canvas, Offset(0, c.dy), Offset(_chartW, c.dy), paint,
        dash: 3, gap: 3);

    // Price tag at cursor height
    final range = _maxP - _minP;
    final priceAtCursor = range <= 0
        ? _minP
        : _maxP - ((c.dy - _priceTop) / (_priceBottom - _priceTop)) * range;
    _axisTag(canvas, c.dy, _fmtPrice(priceAtCursor), const Color(0xFF4A5568));

    // Time tag
    final t = _text(DateFormat('MM/dd HH:mm').format(candles[idx].date),
        color: Colors.white, weight: FontWeight.w600);
    final tagW = t.width + 10;
    final tx = (snapX - tagW / 2).clamp(0.0, _chartW - tagW);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(tx, _chartH + 2, tagW, t.height + 5),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF2D3748),
    );
    t.paint(canvas, Offset(tx + 5, _chartH + 4));
  }

  void _drawLegend(Canvas canvas) {
    // OHLC legend for the hovered candle (or the latest one).
    int idx = _endIdx;
    final c = cursor;
    if (c != null && c.dx >= 0 && c.dx <= _chartW) {
      idx = (_startIdx + (c.dx / _candleW - 0.5).round())
          .clamp(_startIdx, _endIdx);
    }
    final k = candles[idx];
    final chg = k.open == 0 ? 0.0 : ((k.close - k.open) / k.open) * 100;
    final chgColor = chg >= 0 ? VxColors.neonGreen : VxColors.neonRed;

    final parts = <(String, Color)>[
      ('O ${_fmtPrice(k.open)}', VxColors.textSecondary),
      ('H ${_fmtPrice(k.high)}', VxColors.textSecondary),
      ('L ${_fmtPrice(k.low)}', VxColors.textSecondary),
      ('C ${_fmtPrice(k.close)}', chgColor),
      ('${chg >= 0 ? '+' : ''}${chg.toStringAsFixed(2)}%', chgColor),
    ];
    double x = 8;
    for (final (label, color) in parts) {
      final tp = _text(label, color: color, weight: FontWeight.w600);
      tp.paint(canvas, Offset(x, 4));
      x += tp.width + 10;
    }
    if (showIndicators) {
      final s20 = _sma(idx, 20);
      final s50 = _sma(idx, 50);
      if (s20 != null) {
        final tp = _text('SMA20 ${_fmtPrice(s20)}', color: VxColors.neonCyan);
        tp.paint(canvas, Offset(8, 18));
      }
      if (s50 != null) {
        final tp =
            _text('SMA50 ${_fmtPrice(s50)}', color: VxColors.neonPurple);
        tp.paint(canvas, Offset(96, 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProChartPainter old) => true;
}

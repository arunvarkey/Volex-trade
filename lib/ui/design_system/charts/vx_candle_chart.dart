import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/trade_signal.dart';
import 'package:volex_terminal/ui/design_system/theme_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'vx_technical_indicators.dart' as indicators_math;
import 'vx_indicator_panel.dart';
import 'dart:math' as math;
import 'package:volex_terminal/domain/order.dart';

/// Professional-grade Candlestick Chart
/// Completely refactored for performance, accuracy, and theme integration.
class VxCandleChart extends StatefulWidget {
  final List<Candle> candles;
  final List<dynamic>? technicalData;
  final Duration interval;
  final bool showVolume;
  final bool showIndicators;
  final List<TradeSignal>? activeSignals;

  const VxCandleChart({
    super.key,
    required this.candles,
    this.technicalData,
    this.interval = const Duration(minutes: 1),
    this.showVolume = true,
    this.showIndicators = true,
    this.activeSignals,
  });

  @override
  State<VxCandleChart> createState() => _VxCandleChartState();
}

class _VxCandleChartState extends State<VxCandleChart> {
  List<TechnicalIndicator> _indicators = TechnicalIndicators.defaults;
  final Map<String, List<double?>> _calculatedLines = {};

  @override
  void initState() {
    super.initState();
    _recomputeAll();
  }

  @override
  void didUpdateWidget(VxCandleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles != widget.candles) {
      _recomputeAll();
    }
  }

  void _recomputeAll() {
    if (widget.candles.isEmpty) return;
    _calculatedLines.clear();

    for (final indicator in _indicators.where((i) => i.isEnabled)) {
      try {
        switch (indicator.id) {
          case 'sma':
            final period = indicator.params.first.value;
            _calculatedLines['sma'] =
                indicators_math.TechnicalIndicators.sma(widget.candles, period);
            break;
          case 'ema':
            final period = indicator.params.first.value;
            _calculatedLines['ema'] =
                indicators_math.TechnicalIndicators.ema(widget.candles, period);
            break;
          case 'rsi':
            final period = indicator.params.first.value;
            _calculatedLines['rsi'] =
                indicators_math.TechnicalIndicators.rsi(widget.candles, period);
            break;
          case 'bb':
            final period = indicator.params[0].value;
            final stdDev = indicator.params[1].value;
            final bb = indicators_math.TechnicalIndicators.bollingerBands(
                widget.candles, period, stdDev.toDouble());
            _calculatedLines['bb_upper'] = bb['upper'] ?? [];
            _calculatedLines['bb_middle'] = bb['middle'] ?? [];
            _calculatedLines['bb_lower'] = bb['lower'] ?? [];
            break;
          case 'macd':
            final fast = indicator.params[0].value;
            final slow = indicator.params[1].value;
            final signal = indicator.params[2].value;
            final macd = indicators_math.TechnicalIndicators.macd(
                widget.candles, fast, slow, signal);
            _calculatedLines['macd'] = macd['macd'] ?? [];
            _calculatedLines['macd_signal'] = macd['signal'] ?? [];
            break;
        }
      } catch (e) {
        // Silent fail for malformed params during calculation
      }
    }
  }

  void _onIndicatorsChanged(List<TechnicalIndicator> updated) {
    setState(() {
      _indicators = updated;
      _recomputeAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    if (widget.candles.isEmpty) {
      return Center(
          child: Text("AWAITING_PRICING_FEED",
              style: TextStyle(
                  color: theme.currentTheme.textSecondary,
                  letterSpacing: 2,
                  fontSize: 12)));
    }

    final hasRsi = _indicators.any((i) => i.id == 'rsi' && i.isEnabled);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildPricePane(theme),
                ),
                if (widget.showIndicators && hasRsi)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: constraints.maxHeight * 0.2,
                      child: _buildRsiPane(theme),
                    ),
                  ),
              ],
            ),
            if (widget.showIndicators)
              Positioned(
                top: 8,
                right: 8,
                child: VxIndicatorPanel(
                  indicators: _indicators,
                  onIndicatorsChanged: _onIndicatorsChanged,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPricePane(ThemeService theme) {
    final candles = widget.candles;

    // Auto-scale logic
    double minPrice = candles.map((c) => c.low).reduce(math.min);
    double maxPrice = candles.map((c) => c.high).reduce(math.max);

    // Include indicators in scale if they exist
    _calculatedLines.forEach((key, list) {
      if (key.contains('bb') || key == 'sma' || key == 'ema') {
        for (var val in list) {
          if (val != null) {
            minPrice = math.min(minPrice, val);
            maxPrice = math.max(maxPrice, val);
          }
        }
      }
    });

    final buffer = (maxPrice - minPrice) * 0.1;
    final minY = minPrice - buffer;
    final maxY = maxPrice + buffer;

    return Stack(
      children: [
        // Grid & Background Decorations
        _buildGrid(theme, minY, maxY),

        // Candlesticks (using BarChart for efficiency)
        BarChart(
          BarChartData(
            minY: minY,
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: candles.asMap().entries.map((e) {
              final idx = e.key;
              final c = e.value;
              final color = c.isGreen ? theme.candleUp : theme.candleDown;

              return BarChartGroupData(
                x: idx,
                barRods: [
                  // Main Body
                  BarChartRodData(
                    toY: math.max(c.open, c.close),
                    fromY: math.min(c.open, c.close),
                    color: color,
                    width: 6,
                    borderRadius: BorderRadius.zero,
                  ),
                  // Wick
                  BarChartRodData(
                    toY: c.high,
                    fromY: c.low,
                    color: color,
                    width: 1,
                    borderRadius: BorderRadius.zero,
                  ),
                ],
              );
            }).toList(),
            barTouchData: BarTouchData(enabled: false),
          ),
        ),

        // Indicator Lines Overlay
        LineChart(
          LineChartData(
            // ... (keep existing configuration)
            // Since we can't easily merge ReplaceFileContent for large blocks without
            // potentially breaking things, I will just reimplement the stack child order
            // by appending the ScatterChart below.
            // Ideally, we'd use a single CombinedChart if fl_chart supported it robustly
            // for this mix, but independent stacks work for overlay if scales match.
            // Note: Independent stacks can desync if auto-scaling differs.
            // We must force the same Min/Max.

            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(
                enabled: false), // Handle touches in base layer
            lineBarsData: _buildIndicatorLineData(theme),
          ),
        ),

        // 4. SIGNALS LAYER (ScatterChart)
        if (widget.activeSignals != null && widget.activeSignals!.isNotEmpty)
          _buildSignalsLayer(theme, minY, maxY),
      ],
    );
  }

  Widget _buildSignalsLayer(ThemeService theme, double minY, double maxY) {
    if (widget.activeSignals == null || widget.activeSignals!.isEmpty) {
      return const SizedBox();
    }

    // Map signals to indices
    // This is run on every build, optimization: move to didUpdateWidget if heavy.
    final List<ScatterSpot> spots = [];

    // Create a time-to-index map for optimization
    // Assuming candles are sorted? Yes.
    // Binary search is better, but Map is O(1) lookup if we build it once per candle update.
    // For now, let's just find index.

    for (var signal in widget.activeSignals!) {
      // Find close match
      int index = -1;
      // Optimization: search near end?
      // Let's iterate. usage is low (10-100 signals).
      for (int i = 0; i < widget.candles.length; i++) {
        if (widget.candles[i].date.isAtSameMomentAs(signal.timestamp)) {
          index = i;
          break;
        }
      }

      if (index != -1) {
        spots.add(ScatterSpot(
          index.toDouble(),
          signal.price,
          dotPainter: SignalDotPainter(
            isBuy: signal.side == OrderSide.buy,
            color: signal.side == OrderSide.buy
                ? VxColors.neonCyan
                : VxColors.neonRed,
          ),
        ));
      }
    }

    return ScatterChart(
      ScatterChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        scatterTouchData: ScatterTouchData(enabled: false),
        scatterSpots: spots,
      ),
    );
  }

  Widget _buildGrid(ThemeService theme, double minY, double maxY) {
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: (maxY - minY) / 6,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: theme.gridColor, strokeWidth: 1),
          getDrawingVerticalLine: (v) =>
              FlLine(color: theme.gridColor, strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [], // Static background grid
      ),
    );
  }

  List<LineChartBarData> _buildIndicatorLineData(ThemeService theme) {
    final List<LineChartBarData> lines = [];

    _calculatedLines.forEach((key, data) {
      Color color = theme.primary;
      double width = 1.5;

      if (key == 'sma') color = theme.currentTheme.accent;
      if (key == 'ema') color = theme.currentTheme.primary;
      if (key.contains('bb')) {
        color = theme.currentTheme.textSecondary.withValues(alpha: 0.3);
        width = 1.0;
      }
      if (key == 'macd') color = theme.currentTheme.success;
      if (key == 'macd_signal') color = theme.currentTheme.danger;

      lines.add(LineChartBarData(
        spots: data
            .asMap()
            .entries
            .where((e) => e.value != null)
            .map((e) => FlSpot(e.key.toDouble(), e.value!))
            .toList(),
        isCurved: true,
        color: color,
        barWidth: width,
        dotData: const FlDotData(show: false),
      ));
    });

    return lines;
  }

  Widget _buildRsiPane(ThemeService theme) {
    final rsiData = _calculatedLines['rsi'] ?? [];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (v) => [30, 70].contains(v.toInt())
              ? FlLine(
                  color: theme.gridColor, strokeWidth: 1, dashArray: [2, 2])
              : const FlLine(color: Colors.transparent),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) => [30, 70].contains(v.toInt())
                  ? Text(v.toInt().toString(),
                      style: TextStyle(
                          color: theme.currentTheme.textSecondary, fontSize: 8))
                  : const SizedBox(),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: rsiData
                .asMap()
                .entries
                .where((e) => e.value != null)
                .map((e) => FlSpot(e.key.toDouble(), e.value!))
                .toList(),
            color: theme.currentTheme.accent.withValues(alpha: 0.8),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class SignalDotPainter extends FlDotPainter {
  final bool isBuy;
  final Color color;

  SignalDotPainter({required this.isBuy, required this.color});

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final icon = isBuy ? Icons.arrow_upward : Icons.arrow_downward;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas,
        offsetInCanvas - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  Size getSize(FlSpot spot) => const Size(24, 24);

  // Implement missing lerp
  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (b is SignalDotPainter) {
      return SignalDotPainter(
        isBuy: b.isBuy,
        color: Color.lerp(a.mainColor, b.color, t) ?? b.color,
      );
    }
    return b;
  }

  // Implement missing mainColor getter
  @override
  Color get mainColor => color;

  @override
  List<Object?> get props => [isBuy, color];
}

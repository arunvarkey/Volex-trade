import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'vx_technical_indicators.dart' as calc;
import 'vx_indicator_panel.dart'; // Corrected from vx_indicator_controls.dart
import '../vx_colors.dart';
import '../../../engine/execution_manager.dart';
import '../../../domain/order.dart';
import 'package:uuid/uuid.dart';

/// Enhanced chart with interactive indicators
class VxEnhancedChart extends StatefulWidget {
  final List<Candle> candles;
  final Duration interval;
  final bool showControls;

  const VxEnhancedChart({
    super.key,
    required this.candles,
    this.interval = const Duration(minutes: 1),
    this.showControls = true,
  });

  @override
  State<VxEnhancedChart> createState() => _VxEnhancedChartState();
}

class _VxEnhancedChartState extends State<VxEnhancedChart> {
  int? _touchedIndex;
  List<TechnicalIndicator> _indicators = TechnicalIndicators.defaults;

  // Computed indicator data
  final Map<String, List<double?>> _indicatorData = {};

  @override
  void initState() {
    super.initState();
    _computeIndicators();
  }

  @override
  void didUpdateWidget(VxEnhancedChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles != widget.candles) {
      _computeIndicators();
    }
  }

  void _computeIndicators() {
    if (widget.candles.isEmpty) return;

    setState(() {
      _indicatorData.clear();

      for (final indicator in _indicators.where((i) => i.isEnabled)) {
        switch (indicator.id) {
          case 'sma':
            final period = indicator.params.first.value;
            _indicatorData['sma'] =
                calc.TechnicalIndicators.sma(widget.candles, period);
            break;
          case 'ema':
            final period = indicator.params.first.value;
            _indicatorData['ema'] =
                calc.TechnicalIndicators.ema(widget.candles, period);
            break;
          case 'rsi':
            final period = indicator.params.first.value;
            _indicatorData['rsi'] =
                calc.TechnicalIndicators.rsi(widget.candles, period);
            break;
          case 'bb':
            final period = indicator.params[0].value;
            final stdDev = indicator.params[1].value;
            final bb = calc.TechnicalIndicators.bollingerBands(
              widget.candles,
              period,
              stdDev.toDouble(),
            );
            _indicatorData['bb_upper'] = bb['upper'] ?? [];
            _indicatorData['bb_middle'] = bb['middle'] ?? [];
            _indicatorData['bb_lower'] = bb['lower'] ?? [];
            break;
          case 'macd':
            final fast = indicator.params[0].value;
            final slow = indicator.params[1].value;
            final signal = indicator.params[2].value;
            final macd = calc.TechnicalIndicators.macd(
              widget.candles,
              fast,
              slow,
              signal,
            );
            _indicatorData['macd_line'] = macd['macd'] ?? [];
            _indicatorData['macd_signal'] = macd['signal'] ?? [];
            _indicatorData['macd_histogram'] = macd['histogram'] ?? [];
            break;
        }
      }
    });
  }

  // Trade Mode State
  bool _isTradeMode = false;
  double? _draftBuyPrice;
  double? _draftStopPrice;
  double? _draftProfitPrice;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const Center(
        child: Text(
          "NO MARKET DATA",
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    final hasRSI = _indicators.any((i) => i.id == 'rsi' && i.isEnabled);
    final hasMACD = _indicators.any((i) => i.id == 'macd' && i.isEnabled);

    return Column(
      children: [
        // Main Price Chart
        Expanded(
          flex: hasRSI || hasMACD ? 3 : 1,
          child: Stack(
            children: [
              _buildPriceChart(),

              // Interactive Trade Layer (Only when Trade Mode is active)
              if (_isTradeMode)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildInteractiveOverlay(constraints);
                  },
                ),

              // Controls overlay
              if (widget.showControls)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trade Mode Toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isTradeMode = !_isTradeMode;
                            if (_isTradeMode) {
                              final current = widget.candles.last.close;
                              _draftBuyPrice = current * 0.995; // Default -0.5%
                              _draftStopPrice = current * 0.95; // Default -5%
                              _draftProfitPrice = current * 1.05; // Default +5%
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isTradeMode
                                ? VxColors.neonCyan
                                : Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _isTradeMode
                                    ? VxColors.neonCyan
                                    : Colors.white24),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app,
                                  size: 14,
                                  color: _isTradeMode
                                      ? Colors.black
                                      : Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                "TRADE",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isTradeMode
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Indicator Panel
                      VxIndicatorPanel(
                        indicators: _indicators,
                        onIndicatorsChanged: (updated) {
                          setState(() => _indicators = updated);
                          _computeIndicators();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // RSI Pane
        if (hasRSI) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: _buildRSIPane(),
          ),
        ],

        // MACD Pane
        if (hasMACD) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: _buildMACDPane(),
          ),
        ],
      ],
    );
  }

  Widget _buildInteractiveOverlay(BoxConstraints constraints) {
    if (_draftBuyPrice == null || _draftStopPrice == null) {
      return const SizedBox();
    }

    final candles = widget.candles;
    double minPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    double maxPrice =
        candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final buffer = (maxPrice - minPrice) * 0.1;
    final minY = minPrice - buffer;
    final maxY = maxPrice + buffer;
    final priceRange = maxY - minY;

    // Helper to map Price -> Pixel Y
    double getY(double price) {
      final normalized = (price - minY) / priceRange;
      return constraints.maxHeight *
          (1 - normalized); // Invert because 0 is top
    }

    final buyTop = getY(_draftBuyPrice!);
    final stopTop = getY(_draftStopPrice!);
    final profitTop = getY(_draftProfitPrice!);

    return Stack(
      children: [
        // Buy Line (Green)
        _buildPriceLine(
          label: "ENTRY",
          color: VxColors.neonCyan,
          price: _draftBuyPrice!,
          top: buyTop,
          onDrag: (newPrice) => setState(() => _draftBuyPrice = newPrice),
          constraints: constraints,
          minY: minY,
          maxY: maxY,
        ),

        // Stop Line (Red)
        _buildPriceLine(
          label: "STOP LOSS",
          color: VxColors.neonRed,
          price: _draftStopPrice!,
          top: stopTop,
          onDrag: (newPrice) => setState(() => _draftStopPrice = newPrice),
          constraints: constraints,
          minY: minY,
          maxY: maxY,
        ),

        // Profit Line (Green)
        _buildPriceLine(
          label: "TAKE PROFIT",
          color: VxColors.neonGreen,
          price: _draftProfitPrice!,
          top: profitTop,
          onDrag: (newPrice) => setState(() => _draftProfitPrice = newPrice),
          constraints: constraints,
          minY: minY,
          maxY: maxY,
        ),

        // Execute Button
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                // Execute Logic: Place Limit Order
                // We need a callback or access to ExecutionManager?
                // Ideally call a method passed to widget, or show dialog.
                // For V1, simple popup confirmation.
                _showExecutionDialog();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: VxColors.neonCyan,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: VxColors.neonCyan.withValues(alpha: 0.4),
                        blurRadius: 12)
                  ],
                ),
                child: const Text("EXECUTE ORDER",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceLine({
    required String label,
    required Color color,
    required double price,
    required double top,
    required Function(double) onDrag,
    required BoxConstraints constraints,
    required double minY,
    required double maxY,
  }) {
    return Positioned(
      top: top - 20,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          final newY = top + details.delta.dy;
          final normalized = 1 - (newY / constraints.maxHeight);
          final newPrice = minY + (normalized * (maxY - minY));
          onDrag(newPrice);
        },
        child: Container(
          height: 40,
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0), color],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)
                  ],
                ),
                child: Text(
                  "$label: \$${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 50), // Margin for Y-axis titles
            ],
          ),
        ),
      ),
    );
  }

  void _showExecutionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        title:
            const Text("Confirm Order", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow("ENTRY", _draftBuyPrice!, VxColors.neonCyan),
            _buildDialogRow("STOP LOSS", _draftStopPrice!, VxColors.neonRed),
            _buildDialogRow(
                "TAKE PROFIT", _draftProfitPrice!, VxColors.neonGreen),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              _placeVisualOrder();
              Navigator.pop(context);
              setState(() => _isTradeMode = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Trade Order Executed!"),
                  backgroundColor: VxColors.neonGreen));
            },
            child: const Text("PLACE ORDER",
                style: TextStyle(
                    color: VxColors.neonGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _placeVisualOrder() {
    final order = Order(
      id: const Uuid().v4(),
      symbol: "BTCUSDT",
      side: OrderSide.buy,
      timestamp: DateTime.now(),
      type: OrderType.limit,
      price: _draftBuyPrice!,
      status: OrderStatus.pending,
      quantity: 1.0,
    );

    context.read<ExecutionManager>().placeMarketOrder(
          symbol: order.symbol,
          side: order.side,
          quantity: order.quantity,
          currentPrice: order.price,
        );
  }

  Widget _buildDialogRow(String label, double price, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          Text("\$${price.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'RobotoMono')),
        ],
      ),
    );
  }

  Widget _buildPriceChart() {
    final candles = widget.candles;

    // Calculate min/max including all indicators
    double minPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    double maxPrice =
        candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);

    // Include Bollinger Bands in range if enabled
    if (_indicatorData.containsKey('bb_upper')) {
      final bbUpper = _indicatorData['bb_upper']!.whereType<double>();
      final bbLower = _indicatorData['bb_lower']!.whereType<double>();
      if (bbUpper.isNotEmpty && bbLower.isNotEmpty) {
        maxPrice = [maxPrice, ...bbUpper].reduce((a, b) => a > b ? a : b);
        minPrice = [minPrice, ...bbLower].reduce((a, b) => a < b ? a : b);
      }
    }

    final buffer = (maxPrice - minPrice) * 0.1;
    final minY = minPrice - buffer;
    final maxY = maxPrice + buffer;

    return Stack(
      children: [
        // Candlesticks
        BarChart(
          BarChartData(
            minY: minY,
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (val) => FlLine(
                color: Colors.white.withValues(alpha: 0.03),
                strokeWidth: 1,
              ),
            ),
            barGroups: candles.asMap().entries.map((e) {
              final index = e.key;
              final candle = e.value;
              final isGreen = candle.isGreen;
              final color = isGreen ? VxColors.neonGreen : VxColors.neonRed;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY:
                        candle.open > candle.close ? candle.open : candle.close,
                    fromY:
                        candle.open < candle.close ? candle.open : candle.close,
                    color: color,
                    width: 4,
                  ),
                  BarChartRodData(
                    toY: candle.high,
                    fromY: candle.low,
                    color: color,
                    width: 1,
                  ),
                ],
              );
            }).toList(),
            barTouchData: BarTouchData(enabled: false),
          ),
        ),

        // Indicator overlays
        LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (v, m) => Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      v.toStringAsFixed(0),
                      style:
                          const TextStyle(color: Colors.white24, fontSize: 9),
                    ),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchCallback: (event, response) {
                if (response?.lineBarSpots != null) {
                  setState(() =>
                      _touchedIndex = response!.lineBarSpots!.first.x.toInt());
                } else {
                  setState(() => _touchedIndex = null);
                }
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => VxColors.surface,
                getTooltipItems: (spots) => spots.map((s) {
                  if (s.x.toInt() < 0 || s.x.toInt() >= candles.length) {
                    return null;
                  }
                  final c = candles[s.x.toInt()];
                  return LineTooltipItem(
                    "O: ${c.open.toStringAsFixed(2)}\nH: ${c.high.toStringAsFixed(2)}\n"
                    "L: ${c.low.toStringAsFixed(2)}\nC: ${c.close.toStringAsFixed(2)}",
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'RobotoMono',
                    ),
                  );
                }).toList(),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: _buildIndicatorLines(),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (_touchedIndex != null && _touchedIndex! < candles.length)
                  HorizontalLine(
                    y: candles[_touchedIndex!].close,
                    color: Colors.white24,
                    strokeWidth: 1,
                    dashArray: [2, 2],
                  ),
              ],
              verticalLines: [
                if (_touchedIndex != null)
                  VerticalLine(
                    x: _touchedIndex!.toDouble(),
                    color: VxColors.neonCyan.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<LineChartBarData> _buildIndicatorLines() {
    final lines = <LineChartBarData>[];

    // Bollinger Bands
    if (_indicatorData.containsKey('bb_upper')) {
      final bbColor = _getIndicatorColor('bb');
      lines.addAll([
        _createLine('bb_upper', bbColor.withValues(alpha: 0.5), 1),
        _createLine('bb_middle', bbColor, 1.5),
        _createLine('bb_lower', bbColor.withValues(alpha: 0.5), 1),
      ]);
    }

    // EMA
    if (_indicatorData.containsKey('ema')) {
      lines.add(_createLine('ema', _getIndicatorColor('ema'), 2));
    }

    // SMA
    if (_indicatorData.containsKey('sma')) {
      lines.add(_createLine('sma', _getIndicatorColor('sma'), 1.5));
    }

    return lines;
  }

  LineChartBarData _createLine(String key, Color color, double width) {
    final data = _indicatorData[key] ?? [];
    return LineChartBarData(
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
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildRSIPane() {
    final rsiData = _indicatorData['rsi'] ?? [];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (v, m) {
                if ([30, 70].contains(v.toInt())) {
                  return Text(
                    v.toInt().toString(),
                    style: const TextStyle(color: Colors.white10, fontSize: 8),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
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
            color: _getIndicatorColor('rsi'),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
                y: 30,
                color: VxColors.neonGreen.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [2, 2]),
            HorizontalLine(
                y: 70,
                color: VxColors.neonRed.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [2, 2]),
          ],
        ),
      ),
    );
  }

  Widget _buildMACDPane() {
    final macdLine = _indicatorData['macd_line'] ?? [];
    final signalLine = _indicatorData['macd_signal'] ?? [];

    // Histogram is BarChart ideally, but LineChart is easier to stack here.
    // For V1 Advanced, let's keep lines.

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: macdLine
                .asMap()
                .entries
                .where((e) => e.value != null)
                .map((e) => FlSpot(e.key.toDouble(), e.value!))
                .toList(),
            color: VxColors.neonGreen,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: signalLine
                .asMap()
                .entries
                .where((e) => e.value != null)
                .map((e) => FlSpot(e.key.toDouble(), e.value!))
                .toList(),
            color: VxColors.neonRed,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Color _getIndicatorColor(String id) {
    final indicator = _indicators.firstWhere((i) => i.id == id);
    return indicator.color;
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import '../engine/chart_controller.dart';
import '../features/simulator/backtest/backtest_engine.dart';
import '../features/simulator/backtest/models/backtest_request.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import '../engine/strategy/strategy_engine.dart';
import '../domain/symbol_info.dart';
import '../domain/candle_model.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';
import '../features/simulator/backtest/models/backtest_result.dart';
import '../features/simulator/backtest/models/trade_marker.dart' as backtest;
import '../engine/trading/trade_marker.dart' as trading; // Alias
import '../core/service_locator.dart';

class BacktestPanel extends StatefulWidget {
  final List<Strategy> availableStrategies;
  final SymbolInfo currentSymbol;
  final List<Candle> history;
  final ChartController chartController;
  final VoidCallback onClose;

  const BacktestPanel({
    super.key,
    required this.availableStrategies,
    required this.currentSymbol,
    required this.history,
    required this.chartController,
    required this.onClose,
  });

  @override
  State<BacktestPanel> createState() => _BacktestPanelState();
}

class _BacktestPanelState extends State<BacktestPanel> {
  Strategy? _selectedStrategy;
  bool _isRunning = false;
  BacktestResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.availableStrategies.isNotEmpty) {
      _selectedStrategy = widget.availableStrategies.first;
    }
  }

  Future<void> _runBacktest() async {
    if (_selectedStrategy == null) return;
    setState(() {
      _isRunning = true;
      _result = null;
    });

    await Future.delayed(Duration.zero);

    final genStrategy = GeneratedStrategy(
        name: _selectedStrategy!.name,
        description: _selectedStrategy!.description,
        symbol: widget.currentSymbol.symbol,
        timeframe: '1h',
        parameters: _selectedStrategy!.currentParameterValues,
        templateId: GeneratedStrategy.inferTemplateId(
            _selectedStrategy!.currentParameterValues),
        entryConditions: const [],
        exitConditions: const [],
        riskParams: const RiskParameters(
            stopLossPercent: 2, takeProfitPercent: 4, positionSizePercent: 10),
        educationalExplanation: 'Backtest Run',
        confidenceScore: 0);

    final request = BacktestRequest(
      strategy: genStrategy,
      startDate: widget.history.first.date,
      endDate: widget.history.last.date,
      initialEquity: 10000,
    );

    final result = await getIt<BacktestEngine>().run(request);

    if (mounted) {
      // Map backtest markers (backtest.TradeMarker) to visualization markers (trading.TradeMarker)
      final tradingMarkers = result.trades.map((t) {
        // Simple mapping: Entry = Buy, Exit = Sell (Assumption for MVP)
        // Ideally we need OrderDirection in BacktestTradeMarker
        bool isBuy = t.type == backtest.TradeType.entry;

        String label = t.type == backtest.TradeType.entry
            ? "ENTRY"
            : "EXIT ${t.pnlPercent?.toStringAsFixed(2)}%";

        return trading.TradeMarker(
          timestamp: t.timestamp,
          price: t.price,
          isBuy: isBuy,
          label: label,
        );
      }).toList();

      widget.chartController.clearTradeMarkers();
      widget.chartController.addTradeMarkers(tradingMarkers);

      setState(() {
        _isRunning = false;
        _result = result;
      });
    }
  }

  // Removed unused _inferTemplateId as it is consolidated in GeneratedStrategy

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 640,
            height: 520,
            decoration: BoxDecoration(
              color: VxColors.background.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VxColors.neonCyan.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: VxColors.neonCyan.withOpacity(0.1),
                  blurRadius: 30,
                )
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(VxSpacing.lg),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.science_outlined,
                              color: VxColors.neonCyan, size: 20),
                          const SizedBox(width: 12),
                          VxText.heading3("QUANT_LAB // BACKTEST_CORE",
                              color: Colors.white),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white38, size: 20),
                        onPressed: widget.onClose,
                      )
                    ],
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.all(VxSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Strategy>(
                          value: _selectedStrategy,
                          dropdownColor: VxColors.surface,
                          style: const TextStyle(
                              fontFamily: 'RobotoMono', color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "STRATEGY_MODEL",
                            labelStyle:
                                TextStyle(color: Colors.white38, fontSize: 11),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white10)),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: VxColors.neonCyan)),
                          ),
                          items: widget.availableStrategies.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: VxText.mono(s.name, fontSize: 13),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedStrategy = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isRunning ? null : _runBacktest,
                        icon: _isRunning
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.play_arrow),
                        label: VxText.bodyBold(
                            _isRunning ? "COMPUTING..." : "RUN_SIMULATION"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VxColors.neonCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 22),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12, height: 1),

                // Results
                Expanded(
                  child: _isRunning
                      ? Center(
                          child: VxText.body(
                              "PROCESSING_${widget.history.length}_CYCLES...",
                              color: Colors.white38,
                              fontSize: 12))
                      : _result == null
                          ? Center(
                              child: VxText.body("AWAITING_MODEL_VALIDATION",
                                  color: Colors.white10, fontSize: 12))
                          : _buildResults(_result!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BacktestResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VxText.heading3("PERFORMANCE_REPORT", color: Colors.white),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            childAspectRatio: 2.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _StatCard(
                  label: "WIN RATE",
                  value:
                      "${(result.metrics.winRate * 100).toStringAsFixed(1)}%"),
              _StatCard(
                  label: "TOTAL TRADES",
                  value: "${result.metrics.totalTrades}"),
              _StatCard(
                  label: "PROFIT [USDT]",
                  value: result.totalPnl.toStringAsFixed(2)),
              _StatCard(
                  label: "SHARPE",
                  value: result.metrics.sharpeRatio.toStringAsFixed(2)),
              _StatCard(
                  label: "MAX DRAWDOWN",
                  value: result.metrics.maxDrawdownPercent.toStringAsFixed(2)),
              const _StatCard(
                  label: "RUNTIME",
                  value: "N/A"), // Duration not in standard metrics yet?
            ],
          ),

          const SizedBox(height: 32),
          VxText.heading3("EQUITY_CURVE", color: Colors.white),
          const SizedBox(height: 12),

          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
                color: Colors.white.withOpacity(0.01)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _SimpleEquityPainter(result.equityCurve),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VxText.mono(label, fontSize: 9, color: Colors.white24),
          const SizedBox(height: 4),
          VxText.monoBold(value, fontSize: 16, color: VxColors.neonCyan),
        ],
      ),
    );
  }
}

class _SimpleEquityPainter extends CustomPainter {
  final List<double> data;
  _SimpleEquityPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = VxColors.neonGreen
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    double min = data.reduce((curr, next) => curr < next ? curr : next);
    double max = data.reduce((curr, next) => curr > next ? curr : next);

    if (min == max) {
      max += 1;
      min -= 1;
    }

    double wStep = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      double y = size.height - ((data[i] - min) / (max - min) * size.height);
      if (i == 0) {
        path.moveTo(0, y);
      } else {
        path.lineTo(i * wStep, y);
      }
    }

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        VxColors.neonGreen.withOpacity(0.15),
        VxColors.neonGreen.withOpacity(0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

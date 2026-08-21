import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/data/historical_repository.dart';
import 'package:volex_terminal/data/binance/binance_exchange_service.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/engine/optimization/optimization_job.dart';
import 'package:volex_terminal/engine/strategy/built_in_strategies.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';

class OptimizerScreen extends StatefulWidget {
  const OptimizerScreen({super.key});

  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  OptimizationJob? _job;
  bool _isLoadingData = false;
  bool _useRealData = false;
  List<Candle>? _activeData;
  Map<String, dynamic>? _bestParams;
  final List<double> _pnlHistory = [];

  void _start() async {
    final executionManager = context.read<ExecutionManager>();

    if (_useRealData && !executionManager.isLiveMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Enable 'Live Mode' in Settings to fetch real data!")),
      );
      return;
    }

    setState(() {
      _isLoadingData = true;
      _pnlHistory.clear();
    });

    try {
      // 1. Load Data
      final binanceExchange =
          executionManager.exchange is BinanceExchangeService
              ? executionManager.exchange as BinanceExchangeService
              : null;

      final repo = HistoricalRepository(exchange: binanceExchange);
      final data = await repo.fetchHistory(
        symbol: "BTCUSDT",
        interval: "1m",
        useRealData: _useRealData,
        limit: 1000,
      );

      // 2. Setup Job (Ghost Trend Default)
      final job = OptimizationJob(
        prototype: GhostTrendStrategy(slopeThreshold: 0.5),
        data: data,
      );

      if (mounted) {
        setState(() {
          _job = job;
          _activeData = data;
          _isLoadingData = false;
        });
      }

      // 3. Listen & Run
      job.progress.listen((gen) {
        if (mounted) {
          setState(() {
            _pnlHistory.add(gen.bestResult.totalPnl);
            _bestParams = gen.bestParameters;
          });
        }
      });

      await job.start();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Data Fetch Failed: $e")),
        );
      }
    }
  }

  void _applyToLive() async {
    if (_job == null || _bestParams == null) return;

    final engine = context.read<StrategyEngine>();
    const strategyId = "ghost_trend_v1"; // Hardcoded for MVP as per design

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        title: Text("Deploy Strategy?",
            style: GoogleFonts.dmSans(color: VxColors.neonCyan)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "This will update your live bot with the following parameters:",
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ..._bestParams!.entries.map((e) => Text(
                "• ${e.key}: ${e.value is double ? e.value.toStringAsFixed(2) : e.value}",
                style: GoogleFonts.jetBrainsMono(color: VxColors.neonCyan))),
            const SizedBox(height: 16),
            const Text("Are you sure you want to proceed?",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white24)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: VxColors.neonCyan),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Deploy", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      engine.updateStrategyParams(strategyId, _bestParams!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: VxColors.neonGreen,
            content: Text("STRATEGY UPDATED: GENETIC CODE INJECTED",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Strategy Optimizer"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: VxColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.biotech,
                        size: 48, color: VxColors.neonCyan),
                    const SizedBox(height: 16),
                    Text("Genetic Optimization",
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      _useRealData
                          ? "Evolving the 'Ghost Trend' strategy against 1,000 minutes of real Binance history."
                          : "Evolving the 'Ghost Trend' strategy against 1,000 minutes of simulated data.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    // Real Data Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Simulated",
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: !_useRealData
                                    ? VxColors.neonCyan
                                    : Colors.white24)),
                        Switch(
                          value: _useRealData,
                          onChanged: (val) =>
                              setState(() => _useRealData = val),
                          activeThumbColor: VxColors.neonCyan,
                          inactiveThumbColor: VxColors.neonCyan,
                        ),
                        Text("Binance Live",
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: _useRealData
                                    ? VxColors.neonCyan
                                    : Colors.white24)),
                      ],
                    ),
                  ],
                ),
              ),

              if (_activeData != null) ...[
                const SizedBox(height: 16),
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CustomPaint(
                    painter: PriceSparklinePainter(
                      candles: _activeData!,
                      color: _useRealData
                          ? VxColors.neonCyan
                          : VxColors.neonCyan,
                    ),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _useRealData
                        ? "Loaded: Binance 1m History"
                        : "Loaded: Simulated Stream",
                    // Descriptive label, not data — DM Sans, and 9pt was
                    // below a comfortable reading size.
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: Colors.white38),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Progress Section
              if (_job != null) ...[
                Text(
                  "Generation ${_job!.currentGeneration} / ${_job!.totalGenerations}",
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 24,
                      color: VxColors.neonCyan,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _job!.currentGeneration / _job!.totalGenerations,
                  backgroundColor: VxColors.surface,
                  color: VxColors.neonCyan,
                  minHeight: 10,
                ),
                const SizedBox(height: 20),

                // Results Display
                if (_job!.bestResultSoFar != null)
                  _buildResultCard(_job!.bestResultSoFar!, _bestParams),
              ],

              const SizedBox(height: 32),

              // Action Button
              ElevatedButton(
                onPressed: (_job != null && _job!.isRunning) || _isLoadingData
                    ? null
                    : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _job == null
                      ? "Start Evolution"
                      : (_job!.isRunning ? "Evolving..." : "Restart"),
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(dynamic result, Map<String, dynamic>? params) {
    // result is BacktestResult
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.neonGreen.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text("Current Best",
              style: GoogleFonts.dmSans(
                  color: VxColors.neonGreen, fontSize: 12)),
          if (params != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: params.entries
                  .map((e) => Chip(
                        label: Text(
                            "${e.key}: ${e.value is double ? e.value.toStringAsFixed(2) : e.value}",
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white70)),
                        backgroundColor: Colors.white10,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat("PnL", "\$${result.totalPnl.toStringAsFixed(2)}"),
              _stat("Trades", "${result.tradeCount}"),
              _stat("MaxDD", "${result.maxDrawdown.toStringAsFixed(1)}%"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text("Apply to Live"),
              style: OutlinedButton.styleFrom(
                foregroundColor: VxColors.neonCyan,
                side: const BorderSide(color: VxColors.neonCyan),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLoadingData || (_job?.isRunning ?? false)
                  ? null
                  : _applyToLive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }
}

class PriceSparklinePainter extends CustomPainter {
  final List<Candle> candles;
  final Color color;

  PriceSparklinePainter({required this.candles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final maxPrice = candles.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    final minPrice = candles.map((e) => e.low).reduce((a, b) => a < b ? a : b);
    final range = maxPrice - minPrice;

    for (int i = 0; i < candles.length; i++) {
      final x = (i / (candles.length - 1)) * size.width;
      final y =
          size.height - ((candles[i].close - minPrice) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

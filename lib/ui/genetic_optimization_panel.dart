import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import '../engine/optimization/genetic_optimizer.dart';
import '../engine/strategy/strategy_engine.dart';
import '../domain/symbol_info.dart';
import '../domain/candle_model.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';

class GeneticOptimizationPanel extends StatefulWidget {
  final List<Strategy> availableStrategies;
  final SymbolInfo currentSymbol;
  final List<Candle> history;
  final VoidCallback onClose;

  const GeneticOptimizationPanel({
    super.key,
    required this.availableStrategies,
    required this.currentSymbol,
    required this.history,
    required this.onClose,
  });

  @override
  State<GeneticOptimizationPanel> createState() =>
      _GeneticOptimizationPanelState();
}

class _GeneticOptimizationPanelState extends State<GeneticOptimizationPanel> {
  Strategy? _selectedStrategy;
  bool _isRunning = false;

  List<double> _bestFitnessHistory = [];
  List<double> _avgFitnessHistory = [];
  Map<String, double>? _bestParams;
  BacktestResult? _bestResult;
  int _currentGen = 0;

  int _popSize = 25;
  int _generations = 10;
  double _mutationRate = 0.2;

  @override
  void initState() {
    super.initState();
    if (widget.availableStrategies.isNotEmpty) {
      _selectedStrategy = widget.availableStrategies.first;
    }
  }

  Future<void> _runEvolution() async {
    if (_selectedStrategy == null) return;
    setState(() {
      _isRunning = true;
      _bestFitnessHistory = [];
      _avgFitnessHistory = [];
      _bestParams = null;
      _bestResult = null;
      _currentGen = 0;
    });

    final config = OptimizationConfig(
      populationSize: _popSize,
      generations: _generations,
      mutationRate: _mutationRate,
    );
    final optimizer = GeneticOptimizer(config: config);

    final stream = optimizer.evolve(
      _selectedStrategy!,
      widget.history,
    );

    await for (final update in stream) {
      if (!mounted) break;
      setState(() {
        _currentGen = update.number;
        _bestFitnessHistory.add(update.bestFitness);
        _avgFitnessHistory.add(update.averagePnL);
        _bestParams = update.bestParameters
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        _bestResult = update.bestResult;
      });
    }

    if (mounted) {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 840,
            height: 620,
            decoration: BoxDecoration(
                color: VxColors.background.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                      color: VxColors.neonCyan.withValues(alpha: 0.05),
                      blurRadius: 40)
                ]),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    children: [
                      _buildSidebar(),
                      const VerticalDivider(color: Colors.white24, width: 1),
                      Expanded(child: _buildMainView()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(VxSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: VxColors.neonCyan, size: 20),
              const SizedBox(width: 12),
              VxText.heading3("EVOLUTIONARY_TRACTOR // GENETIC_CORE",
                  color: Colors.white),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 20),
            onPressed: widget.onClose,
          )
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(VxSpacing.lg),
      color: Colors.white.withValues(alpha: 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VxText.monoBold("GENOME_CONFIG", fontSize: 10, color: Colors.white38),
          const SizedBox(height: 20),
          DropdownButtonFormField<Strategy>(
            value: _selectedStrategy,
            dropdownColor: VxColors.surface,
            style: const TextStyle(
                fontFamily: 'RobotoMono', color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: "STRATEGY_TARGET",
              labelStyle: TextStyle(color: Colors.white24, fontSize: 10),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white10)),
            ),
            items: widget.availableStrategies
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: _isRunning
                ? null
                : (val) => setState(() => _selectedStrategy = val),
          ),
          const SizedBox(height: 32),
          _buildSlider("POPULATION_SIZE", _popSize.toDouble(), 10, 100,
              (v) => setState(() => _popSize = v.toInt())),
          _buildSlider("GENERATION_DEPTH", _generations.toDouble(), 5, 50,
              (v) => setState(() => _generations = v.toInt())),
          _buildSlider("MUTATION_CHANCE", _mutationRate, 0.0, 1.0,
              (v) => setState(() => _mutationRate = v)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runEvolution,
              style: ElevatedButton.styleFrom(
                backgroundColor: VxColors.neonCyan.withValues(alpha: 0.8),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.bolt),
              label: VxText.bodyBold(
                  _isRunning ? "EVOLVING..." : "BEGIN_EVOLUTION"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            VxText.mono(label, fontSize: 9, color: Colors.white24),
            VxText.monoBold(
                value is int ? value.toString() : value.toStringAsFixed(2),
                fontSize: 10,
                color: VxColors.neonCyan),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 1,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
            activeTrackColor: VxColors.neonCyan,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: _isRunning ? null : onChanged,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMainView() {
    if (_bestFitnessHistory.isEmpty && !_isRunning) {
      return Center(
        child: VxText.body("AWAITING_GENETIC_SEQUENCE",
            color: Colors.white10, fontSize: 12),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VxSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VxText.heading3("FITNESS_EVOLUTION (GEN $_currentGen)",
                  color: Colors.white),
              if (_isRunning)
                SizedBox(
                    width: 120,
                    height: 2,
                    child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        color: VxColors.neonCyan)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
                color: Colors.white.withValues(alpha: 0.01)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _EvolutionChartPainter(
                    _bestFitnessHistory, _avgFitnessHistory),
              ),
            ),
          ),
          const SizedBox(height: 32),
          VxText.heading3("CHAMPION_SPECIES", color: VxColors.neonGreen),
          const SizedBox(height: 16),
          if (_bestParams != null) _buildChampionCard(),
        ],
      ),
    );
  }

  Widget _buildChampionCard() {
    final result = _bestResult;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VxColors.neonGreen.withValues(alpha: 0.03),
        border: Border.all(color: VxColors.neonGreen.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: _bestParams!.entries
                .map((e) => Expanded(
                      child: _MetricTile(
                          label: e.key.toUpperCase(),
                          value: e.value.toStringAsFixed(3)),
                    ))
                .toList(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          ),
          Row(
            children: [
              Expanded(
                  child: _MetricTile(
                      label: "RETURN %",
                      value: result?.metrics.totalReturnPercent
                              .toStringAsFixed(2) ??
                          "0")),
              Expanded(
                  child: _MetricTile(
                      label: "WIN_RATE",
                      value:
                          "${((result?.metrics.winRate ?? 0) * 100).toStringAsFixed(1)}%")),
              Expanded(
                  child: _MetricTile(
                      label: "PROFIT_FACTOR",
                      value: result?.metrics.profitFactor.toStringAsFixed(2) ??
                          "0")),
              Expanded(
                  child: _MetricTile(
                      label: "MAX_DRAWDOWN",
                      value: result?.metrics.maxDrawdownPercent
                              .toStringAsFixed(0) ??
                          "0")),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VxText.mono(label, fontSize: 8, color: Colors.white24),
        const SizedBox(height: 4),
        VxText.monoBold(value, fontSize: 15, color: Colors.white70),
      ],
    );
  }
}

class _EvolutionChartPainter extends CustomPainter {
  final List<double> best;
  final List<double> avg;
  _EvolutionChartPainter(this.best, this.avg);

  @override
  void paint(Canvas canvas, Size size) {
    if (best.isEmpty) return;

    final bestPaint = Paint()
      ..color = VxColors.neonCyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final avgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double maxVal = best.reduce(max);
    double minVal = avg.reduce(min);
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final bestPath = Path();
    final avgPath = Path();

    double xStep = size.width / (best.length == 1 ? 1 : best.length - 1);

    for (int i = 0; i < best.length; i++) {
      double x = i * xStep;
      double yBest =
          size.height - (best[i] - minVal) / (maxVal - minVal) * size.height;
      double yAvg =
          size.height - (avg[i] - minVal) / (maxVal - minVal) * size.height;

      if (i == 0) {
        bestPath.moveTo(x, yBest);
        avgPath.moveTo(x, yAvg);
      } else {
        bestPath.lineTo(x, yBest);
        avgPath.lineTo(x, yAvg);
      }
    }

    canvas.drawPath(avgPath, avgPaint);
    canvas.drawPath(bestPath, bestPaint);

    // Add glow to best path
    final glowPaint = Paint()
      ..color = VxColors.neonCyan.withValues(alpha: 0.1)
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bestPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'dart:ui';
import '../engine/optimizer_controller.dart';
import '../engine/strategy/strategy_engine.dart';
import '../engine/chart_controller.dart';
import '../engine/execution_manager.dart';
import '../engine/risk_manager.dart';
import '../domain/symbol_info.dart';
import '../domain/candle_model.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';

class OptimizerPanel extends StatefulWidget {
  final List<Strategy> availableStrategies;
  final SymbolInfo currentSymbol;
  final List<Candle> history;
  final VoidCallback onClose;
  final ChartController chartController;
  final ExecutionManager executionManager;
  final RiskManager riskManager;

  const OptimizerPanel({
    super.key,
    required this.availableStrategies,
    required this.currentSymbol,
    required this.history,
    required this.onClose,
    required this.chartController,
    required this.executionManager,
    required this.riskManager,
  });

  @override
  State<OptimizerPanel> createState() => _OptimizerPanelState();
}

class _OptimizerPanelState extends State<OptimizerPanel> {
  final OptimizerController _controller = OptimizerController();
  Strategy? _selectedStrategy;
  bool _isRunning = false;
  List<OptimizationResult> _results = [];
  int _permutationsCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.availableStrategies.isNotEmpty) {
      _selectedStrategy = widget.availableStrategies.first;
    }
  }

  Future<void> _runOptimization() async {
    if (_selectedStrategy == null) return;

    setState(() {
      _isRunning = true;
      _results = [];
      _permutationsCount = 0;
    });

    final stream = _controller.run(
        strategy: _selectedStrategy!,
        symbol: widget.currentSymbol,
        history: widget.history);

    await for (final result in stream) {
      if (!mounted) break;
      setState(() {
        _results.add(result);
        _permutationsCount++;
        // Sort descending by Expectancy
        _results.sort((a, b) => b.result.metrics.totalReturnPercent
            .compareTo(a.result.metrics.totalReturnPercent));
      });
    }

    if (mounted) {
      setState(() {
        _isRunning = false;
      });
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
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 640),
            decoration: BoxDecoration(
                color: VxColors.background.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: VxColors.neonMagenta.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                      color: VxColors.neonMagenta.withValues(alpha: 0.1),
                      blurRadius: 40)
                ]),
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
                          const Icon(Icons.bolt,
                              color: VxColors.neonMagenta, size: 20),
                          const SizedBox(width: 12),
                          VxText.heading3("QUANT_ENGINE // OPTIMIZER",
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
                          isExpanded: true,
                          value: _selectedStrategy,
                          dropdownColor: VxColors.surface,
                          style: const TextStyle(
                              fontFamily: 'RobotoMono', color: Colors.white),
                          decoration: InputDecoration(
                              labelText: "STRATEGY_TARGET",
                              labelStyle: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.white10)),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: VxColors.neonMagenta)),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.02)),
                          items: widget.availableStrategies.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: VxText.mono(s.name, fontSize: 13),
                            );
                          }).toList(),
                          onChanged: _isRunning
                              ? null
                              : (val) =>
                                  setState(() => _selectedStrategy = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isRunning ? null : _runOptimization,
                        icon: _isRunning
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.flash_on),
                        label: VxText.monoBold(_isRunning
                            ? "SCANNING ($_permutationsCount)"
                            : "RUN OPTIMIZATION"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                VxColors.neonMagenta.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 22),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                      )
                    ],
                  ),
                ),

                // Param Info
                if (_selectedStrategy != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: VxSpacing.lg),
                    child: VxText.mono(
                      "PARAMS: ${_selectedStrategy!.parameters.map((p) => "${p.name} [${p.min}-${p.max}]").join(", ")}",
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),

                // Leaderboard
                Expanded(
                  child: _results.isEmpty
                      ? Center(
                          child: VxText.body("AWAITING_SIGNAL_PROCESSING",
                              color: Colors.white10, fontSize: 12))
                      : _buildLeaderboard(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VxSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 40,
            horizontalMargin: 16,
            columnSpacing: 24,
            columns: [
              DataColumn(
                  label: VxText.monoBold("RANK",
                      fontSize: 10, color: Colors.white54)),
              DataColumn(
                  label: VxText.monoBold("PARAMS",
                      fontSize: 10, color: Colors.white54)),
              DataColumn(
                  label: VxText.monoBold("WIN_RATE",
                      fontSize: 10, color: Colors.white54)),
              DataColumn(
                  label: VxText.monoBold("RETURN %",
                      fontSize: 10, color: Colors.white54)),
              DataColumn(
                  label: VxText.monoBold("PROFIT_FACTOR",
                      fontSize: 10, color: Colors.white54)),
              DataColumn(
                  label: VxText.monoBold("TRADES",
                      fontSize: 10, color: Colors.white54)),
            ],
            rows: _results.asMap().entries.map((entry) {
              final index = entry.key;
              final res = entry.value;
              final resultData = res.result;
              final isTop = index == 0;

              return DataRow(
                cells: [
                  DataCell(VxText.monoBold("#${index + 1}",
                      color: isTop ? VxColors.neonGreen : Colors.white60,
                      fontSize: 11)),
                  DataCell(VxText.mono(
                      res.params.entries
                          .map((e) => "${e.key}:${e.value}")
                          .join(", "),
                      fontSize: 10,
                      color: Colors.white38)),
                  DataCell(VxText.mono(
                      "${(resultData.metrics.winRate * 100).toStringAsFixed(1)}%",
                      fontSize: 11)),
                  DataCell(VxText.monoBold(
                      resultData.metrics.totalReturnPercent.toStringAsFixed(2),
                      color: VxColors.neonCyan,
                      fontSize: 11)),
                  DataCell(VxText.mono(
                      resultData.metrics.profitFactor.toStringAsFixed(2),
                      fontSize: 11)),
                  DataCell(VxText.mono("${resultData.metrics.totalTrades}",
                      fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

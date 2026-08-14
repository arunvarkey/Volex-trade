import 'package:flutter/material.dart';
import 'dart:ui';
import '../engine/auto_tuner_controller.dart';
import '../engine/regime_service.dart';
import '../engine/strategy/strategy_engine.dart';
import '../domain/symbol_info.dart';
import '../domain/candle_model.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';

class AutoTuningPanel extends StatefulWidget {
  final AutoTunerController controller;
  final List<Strategy> strategies;
  final SymbolInfo currentSymbol;
  final List<Candle> history;
  final VoidCallback onClose;

  const AutoTuningPanel({
    super.key,
    required this.controller,
    required this.strategies,
    required this.currentSymbol,
    required this.history,
    required this.onClose,
  });

  @override
  State<AutoTuningPanel> createState() => _AutoTuningPanelState();
}

class _AutoTuningPanelState extends State<AutoTuningPanel> {
  @override
  void initState() {
    super.initState();
    widget.controller.updates.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 740,
            height: 520,
            decoration: BoxDecoration(
                color: VxColors.background.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: VxColors.neonMagenta.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                      color: VxColors.neonMagenta.withValues(alpha: 0.05),
                      blurRadius: 40)
                ]),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    children: [
                      _buildSidebar(),
                      const VerticalDivider(color: Colors.white10, width: 1),
                      Expanded(child: _buildEventList()),
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
          border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology,
                  color: VxColors.neonMagenta, size: 20),
              const SizedBox(width: 12),
              VxText.heading3("AUTONOMIC_CALIBRATION // BRAIN_STATUS",
                  color: Colors.white),
            ],
          ),
          IconButton(
              icon: const Icon(Icons.close, color: Colors.white38, size: 20),
              onPressed: widget.onClose),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final regime = widget.controller.currentRegime;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(VxSpacing.lg),
      color: Colors.white.withValues(alpha: 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VxText.monoBold("CURRENT_REGIME",
              fontSize: 10, color: Colors.white38),
          const SizedBox(height: 16),
          _StatusChip(
            label: regime?.tag ?? "DETECTING...",
            color: regime?.trend == TrendRegime.trend
                ? VxColors.neonCyan
                : Colors.orange,
            icon: Icons.radar,
          ),
          const SizedBox(height: 32),
          VxText.monoBold("REALTIME_METRICS",
              fontSize: 10, color: Colors.white38),
          const SizedBox(height: 12),
          _MetricRow(
              label: "regime_efficiency",
              value: "${(regime?.adx ?? 0).toStringAsFixed(1)}%"),
          _MetricRow(
              label: "volatility_ratio",
              value: "${(regime?.atrRatio ?? 0).toStringAsFixed(2)}x"),
          const Spacer(),
          ElevatedButton(
            onPressed: widget.controller.isTuning
                ? null
                : () {
                    // Trigger tuning for first enabled strategy
                    if (widget.strategies.isNotEmpty) {
                      widget.controller.tuneStrategy(
                          strategy: widget.strategies.first,
                          symbol: widget.currentSymbol,
                          history: widget.history);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonMagenta.withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: widget.controller.isTuning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : VxText.bodyBold("FORCE_TUNE_CYCLE"),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = widget.controller.history;
    if (events.isEmpty) {
      return Center(
        child: VxText.body("AWAITING_CALIBRATION_CYCLES",
            color: Colors.white10, fontSize: 12),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(VxSpacing.lg),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(
                color: event.accepted
                    ? VxColors.neonGreen.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VxText.monoBold("${event.strategyId} @ ${event.regimeTag}",
                      fontSize: 10, color: Colors.white70),
                  VxText.mono(
                      event.timestamp.toString().split('.')[0].split(' ')[1],
                      fontSize: 9,
                      color: Colors.white24),
                ],
              ),
              const SizedBox(height: 10),
              VxText.body(event.reason,
                  color: event.accepted
                      ? VxColors.neonGreen.withValues(alpha: 0.8)
                      : Colors.redAccent.withValues(alpha: 0.8),
                  fontSize: 11),
              if (event.accepted) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: VxText.mono(
                      "NEW_GENOME: ${event.newParams.entries.map((e) => "${e.key}: ${e.value.toStringAsFixed(3)}").join(', ')}",
                      fontSize: 9,
                      color: Colors.white38),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 10),
          VxText.monoBold(label, fontSize: 11, color: color),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VxText.mono(label, fontSize: 10, color: Colors.white38),
          VxText.monoBold(value, fontSize: 10, color: Colors.white70),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import '../engine/execution_manager.dart';
import '../engine/chart_controller.dart';
import '../engine/auto_tuner_controller.dart';
import '../engine/risk_manager.dart';
import '../engine/regime_service.dart';
import '../core/performance_monitor.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';

class HudOverlay extends StatelessWidget {
  final ChartController controller;
  final ExecutionManager executionManager;
  final AutoTunerController autoTuner;
  final ValueNotifier<double> fpsNotifier;
  final bool isConnected;

  const HudOverlay({
    super.key,
    required this.controller,
    required this.executionManager,
    required this.autoTuner,
    required this.fpsNotifier,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 48,
      left: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(VxSpacing.md),
            decoration: BoxDecoration(
              color: VxColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.terminal,
                        color: VxColors.neonCyan, size: 14),
                    const SizedBox(width: 8),
                    VxText.monoBold("VOLEX_SYSTEM_V4",
                        color: Colors.white, fontSize: 11),
                    const SizedBox(width: 12),
                    // Connection Dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: isConnected
                              ? VxColors.neonGreen
                              : VxColors.neonRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isConnected
                                      ? VxColors.neonGreen
                                      : VxColors.neonRed)
                                  .withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]),
                    )
                  ],
                ),
                const SizedBox(height: 12),

                // Divider
                Container(
                  height: 1,
                  width: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      VxColors.neonCyan.withOpacity(0.3),
                      Colors.transparent,
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Metrics
                AnimatedBuilder(
                  animation: Listenable.merge([controller, executionManager]),
                  builder: (context, _) {
                    final price = controller.allCandles.isNotEmpty
                        ? controller.allCandles.last.close.toStringAsFixed(2)
                        : "---";
                    final ghostEnd =
                        controller.ghost?.endPrice.toStringAsFixed(2) ?? "---";
                    final zoneCount = controller.zones.length;

                    final equity = executionManager.totalEquityUsdt;
                    final balance = executionManager.totalEstimatedBalanceUsdt;
                    final unrealized = executionManager.totalUnrealizedPnl;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row("PRICE", price, Colors.white),
                        _row("GHOST", ghostEnd, VxColors.neonCyan),
                        _row("ZONES", "$zoneCount", VxColors.neonMagenta),
                        const SizedBox(height: 6),
                        _row(
                            "EQUITY",
                            "\$${equity.toStringAsFixed(2)}",
                            unrealized >= 0
                                ? VxColors.neonGreen
                                : VxColors.neonRed),
                        _row("WALLET", "\$${balance.toStringAsFixed(2)}",
                            Colors.white.withOpacity(0.7)),
                      ],
                    );
                  },
                ),

                // FPS & Paint
                ValueListenableBuilder<double>(
                  valueListenable: fpsNotifier,
                  builder: (context, fps, _) {
                    final paint = PerformanceMonitor().getMetric('paint');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row("FPS", fps.toStringAsFixed(0), Colors.white24),
                        _row("PAINT", "${paint.toStringAsFixed(1)}ms",
                            Colors.white24),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Execution Stats
                AnimatedBuilder(
                  animation: executionManager,
                  builder: (context, _) {
                    final isLive = executionManager.isLiveMode;
                    final isReadOnly = executionManager.isReadOnly;
                    final liveMode = executionManager.liveExecutionMode;

                    String modeText = "SIMULATION";
                    Color modeColor = VxColors.neonGreen;

                    if (isLive) {
                      if (isReadOnly) {
                        modeText = "PRO: OBSERVER";
                        modeColor = VxColors.neonCyan;
                      } else {
                        switch (liveMode) {
                          case LiveExecutionMode.manualOnly:
                            modeText = "PRO: MANUAL";
                            modeColor = VxColors.neonRed;
                            break;
                          case LiveExecutionMode.autoCapped:
                            modeText = "PRO: CAPPED";
                            modeColor = VxColors.warning;
                            break;
                          case LiveExecutionMode.fullAuto:
                            modeText = "PRO: AUTONOMOUS";
                            modeColor = VxColors.neonMagenta;
                            break;
                        }
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row("MODE", modeText, modeColor),
                        if (isLive)
                          StreamBuilder<bool>(
                              stream: RiskManager().safetyStream,
                              initialData: RiskManager().isLocked,
                              builder: (context, snapshot) {
                                final isLocked = snapshot.data ?? false;
                                final riskStatus = RiskManager().getStatus();
                                final aggRisk =
                                    riskStatus['aggregateRisk'] as double;

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isLocked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(
                                            top: 4, bottom: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              VxColors.neonRed.withOpacity(0.1),
                                          border: Border.all(
                                              color: VxColors.neonRed
                                                  .withOpacity(0.5)),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: VxText.monoBold("LOCK_ENGAGED",
                                            color: VxColors.neonRed,
                                            fontSize: 9),
                                      ),
                                    _row(
                                        "RISK",
                                        "\$${aggRisk.toStringAsFixed(0)}",
                                        aggRisk > (isReadOnly ? 4000 : 80)
                                            ? VxColors.neonRed
                                            : Colors.white70),
                                  ],
                                );
                              }),
                        StreamBuilder(
                          stream: autoTuner.updates,
                          builder: (context, snapshot) {
                            final regime = autoTuner.currentRegime;
                            final tag = regime?.tag ?? "DETECTING...";
                            final color = regime?.trend == TrendRegime.trend
                                ? VxColors.neonCyan
                                : VxColors.warning;
                            return _row("REGIME", tag, color);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, [Color color = Colors.white]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            child: VxText.mono(label, color: Colors.white24, fontSize: 9),
          ),
          VxText.monoBold(value, color: color, fontSize: 10),
        ],
      ),
    );
  }
}

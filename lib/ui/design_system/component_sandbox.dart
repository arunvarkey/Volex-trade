import 'package:flutter/material.dart';
import 'vx_colors.dart';
import 'vx_typography.dart';
import 'vx_spacing.dart';
import 'vx_card.dart';
import 'vx_status_badge.dart';
import 'vx_metric_gauge.dart';
import 'vx_strategy_tile.dart';
import 'vx_log_list.dart';
import 'vx_health_score.dart';
import 'vx_toolbar.dart'; // Import toolbar

class ComponentSandbox extends StatelessWidget {
  const ComponentSandbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: VxToolbar(
        title: VxText.title("Design System Sandbox"),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: VxColors.neonCyan),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VxSpacing.screenMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section: Atoms (Colors) ---
            const _SectionHeader("Atoms: Palette"),
            const Wrap(
              spacing: VxSpacing.sm,
              runSpacing: VxSpacing.sm,
              children: [
                _ColorBox("Cyan", VxColors.neonCyan),
                _ColorBox("Magenta", VxColors.neonMagenta),
                _ColorBox("Green", VxColors.neonGreen),
                _ColorBox("Red", VxColors.neonRed),
                _ColorBox("Purple", VxColors.neonPurple),
                _ColorBox("Background", VxColors.background),
                _ColorBox("Surface", VxColors.surface),
              ],
            ),

            const SizedBox(height: VxSpacing.sectionGap),

            // --- Section: Typography ---
            const _SectionHeader("Atoms: Typography"),
            VxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VxText.title("Title: The Quick Brown Fox"),
                  VxText.subtitle("Subtitle: Jumps over the lazy dog"),
                  VxText.body(
                      "Body: Efficient markets hypothesis is often debated."),
                  VxText.caption("Caption: Data valid as of 12:00 PM"),
                  VxText.micro("MICRO: SYSTEM STATUS OK"),
                  const SizedBox(height: 8),
                  VxText.mono("Mono: 123.456789 BTC"),
                ],
              ),
            ),

            const SizedBox(height: VxSpacing.sectionGap),

            // --- Section: Components (Metric Gauges) ---
            const _SectionHeader("Components: Gauges"),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                VxMetricGauge(
                    label: "Win Rate",
                    value: 0.65,
                    displayValue: "65%",
                    color: VxColors.neonGreen),
                VxMetricGauge(
                    label: "Drawdown",
                    value: 0.12,
                    displayValue: "-12%",
                    color: VxColors.neonRed),
                VxMetricGauge(
                    label: "Efficiency",
                    value: 0.88,
                    displayValue: "88%",
                    color: VxColors.neonCyan),
              ],
            ),

            const SizedBox(height: VxSpacing.sectionGap),

            // --- Section: Badges ---
            const _SectionHeader("Components: Badges"),
            const Wrap(
              spacing: VxSpacing.sm,
              children: [
                VxStatusBadge(label: "Active", style: VxBadgeStyle.success),
                VxStatusBadge(label: "Paused", style: VxBadgeStyle.warning),
                VxStatusBadge(label: "Stopped", style: VxBadgeStyle.danger),
                VxStatusBadge(label: "Syncing", style: VxBadgeStyle.info),
                VxStatusBadge(label: "Idle", style: VxBadgeStyle.neutral),
                VxStatusBadge(
                    label: "Outline", style: VxBadgeStyle.info, outline: true),
              ],
            ),

            const SizedBox(height: VxSpacing.sectionGap),

            // --- Section: Scores ---
            const _SectionHeader("Components: Health Score"),
            const Row(
              children: [
                VxHealthScore(score: 95),
                SizedBox(width: 8),
                VxHealthScore(score: 65),
                SizedBox(width: 8),
                VxHealthScore(score: 30),
              ],
            ),

            const SizedBox(height: VxSpacing.sectionGap),

            // --- Section: Strategy Tiles ---
            const _SectionHeader("Components: Strategy Tiles"),
            VxStrategyTile(
              name: "Mean Reversion Alpha",
              status: VxBadgeStyle.success,
              statusLabel: "RUNNING",
              metrics: const {"PnL": "+12.5%", "Win": "68%"},
              onTap: () {},
            ),
            const SizedBox(height: VxSpacing.sm),
            VxStrategyTile(
              name: "Trend Follower V2",
              status: VxBadgeStyle.warning,
              statusLabel: "PAUSED",
              metrics: const {"PnL": "-2.1%", "Win": "45%"},
              onTap: () {},
            ),

            const SizedBox(height: VxSpacing.sectionGap),

            // --- Section: Logs ---
            const _SectionHeader("Components: Logs"),
            SizedBox(
              height: 150,
              child: VxCard(
                padding: const EdgeInsets.all(8),
                child: VxLogList(
                  logs: [
                    VxLogEntry(
                        timestamp: DateTime.now(),
                        message: "Strategy initialized successfully.",
                        severity: VxLogSeverity.success),
                    VxLogEntry(
                        timestamp: DateTime.now(),
                        message: "Connecting to Binance stream...",
                        severity: VxLogSeverity.info),
                    VxLogEntry(
                        timestamp: DateTime.now(),
                        message: "Warn: Latency spike detected (150ms).",
                        severity: VxLogSeverity.warning),
                    VxLogEntry(
                        timestamp: DateTime.now(),
                        message:
                            "Error: Order rejected due to insufficient margin.",
                        severity: VxLogSeverity.error),
                    VxLogEntry(
                        timestamp: DateTime.now(),
                        message: "Retrying connection...",
                        severity: VxLogSeverity.info),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VxSpacing.md),
      child: VxText.subtitle(title, color: VxColors.neonPurple),
    );
  }
}

class _ColorBox extends StatelessWidget {
  final String name;
  final Color color;
  const _ColorBox(this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: VxText.micro(name,
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
    );
  }
}

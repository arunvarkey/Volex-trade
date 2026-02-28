import 'package:flutter/material.dart';
import 'vx_card.dart';
import 'vx_colors.dart';
import 'vx_typography.dart';
import 'vx_spacing.dart';
import 'vx_status_badge.dart';

class VxStrategyTile extends StatelessWidget {
  final String name;
  final VxBadgeStyle status;
  final String statusLabel; // e.g. "ACTIVE", "PAUSED"
  final Map<String, String> metrics; // e.g. {"PnL": "+5%", "Win": "60%"}
  final VoidCallback? onTap;
  final bool isSelected;

  const VxStrategyTile({
    super.key,
    required this.name,
    required this.status,
    required this.statusLabel,
    required this.metrics,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return VxCard(
      onTap: onTap,
      child: Row(
        children: [
          // Icon / Logo (Active Border if selected)
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? VxColors.neonCyan.withOpacity(0.2)
                  : VxColors.primaryGradient.colors.first.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected
                      ? VxColors.neonCyan
                      : VxColors.neonCyan.withOpacity(0.3),
                  width: isSelected ? 2 : 1),
            ),
            child: const Icon(Icons.show_chart,
                color: VxColors.neonCyan, size: 20),
          ),
          const SizedBox(width: VxSpacing.md),

          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VxText.body(name, color: Colors.white, maxLines: 1),
                const SizedBox(height: 4),
                VxStatusBadge(label: statusLabel, style: status),
              ],
            ),
          ),

          // Mini Metrics
          ...metrics.entries.map((e) => Padding(
                padding: const EdgeInsets.only(left: VxSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    VxText.micro(
                        e.key == "PnL" ? "IMPACT" : e.key.toUpperCase()),
                    VxText.monoBold(e.value,
                        color: e.value.startsWith("-")
                            ? VxColors.neonRed
                            : VxColors.neonGreen),
                  ],
                ),
              )),

          const SizedBox(width: VxSpacing.sm),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}

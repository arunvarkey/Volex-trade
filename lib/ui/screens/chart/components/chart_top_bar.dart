import 'package:flutter/material.dart';
import '../../../design_system/vx_colors.dart';
import '../../../design_system/vx_typography.dart';
import '../../../widgets/vx_holographic_card.dart';

class ChartTopBar extends StatelessWidget {
  final String symbol;
  final double price;
  final VoidCallback onSymbolTap;
  final bool isReplayMode;
  final VoidCallback onReplayTap;

  const ChartTopBar({
    super.key,
    required this.symbol,
    required this.price,
    required this.onSymbolTap,
    this.isReplayMode = false,
    required this.onReplayTap,
  });

  @override
  Widget build(BuildContext context) {
    return VxHolographicCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 0,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (Navigator.canPop(context))
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white70, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            else
              const Icon(Icons.hub_outlined,
                  color: VxColors.neonCyan, size: 20),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onSymbolTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: VxColors.neonCyan.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Text(
                      symbol,
                      style: VxTypography.body
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down,
                        color: VxColors.neonCyan, size: 16),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // [NEW] Visual Backtesting Toggle
            IconButton(
              onPressed: onReplayTap,
              icon: Icon(
                Icons.history_toggle_off,
                color: isReplayMode ? VxColors.neonPurple : Colors.white54,
                size: 20,
              ),
              tooltip: "Time Machine Check",
            ),
            Container(
                width: 1,
                height: 24,
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 4)),
            IconButton(
              onPressed: () => _showHelpDialog(context),
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Text(
                    "?",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reading the chart",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Each bar shows price movement in one period.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              color: VxColors.success,
              title: "Green Candle",
              desc: "Price went up during the period.",
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              color: VxColors.danger,
              title: "Red Candle",
              desc: "Price went down during the period.",
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              color: Colors.white38,
              title: "Wicks",
              desc:
                  "The thin lines show the highest and lowest prices reached.",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it",
                style: TextStyle(color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
      {required Color color, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(desc,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../design_system/vx_colors.dart';
import '../../../design_system/vx_typography.dart';

class ChartStatsOverlay extends StatelessWidget {
  final String symbol;
  final double currentPrice;
  final double change24h;
  final double high24h;
  final double low24h;
  final double volume24h;

  const ChartStatsOverlay({
    super.key,
    required this.symbol,
    required this.currentPrice,
    required this.change24h,
    this.high24h = 0.0,
    this.low24h = 0.0,
    this.volume24h = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = change24h >= 0;
    final chgColor = isPos ? VxColors.success : VxColors.danger;

    // A single compact stats strip. The live price already lives in the top
    // bar and the chart's OHLC legend, so we don't repeat a giant price here —
    // that duplicate used to overlap the chart header.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VxColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chgColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${isPos ? '+' : ''}${change24h.toStringAsFixed(2)}%',
              style: VxTypography.caption.copyWith(
                color: chgColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _stat('24h H', '\$${high24h.toStringAsFixed(high24h >= 1 ? 2 : 4)}'),
          const SizedBox(width: 14),
          _stat('24h L', '\$${low24h.toStringAsFixed(low24h >= 1 ? 2 : 4)}'),
          const SizedBox(width: 14),
          _stat('Vol', _formatVolume(volume24h)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: VxTypography.caption.copyWith(
            color: VxColors.textTertiary,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            color: VxColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: VxTypography.mono,
          ),
        ),
      ],
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    }
    return volume.toStringAsFixed(0);
  }
}

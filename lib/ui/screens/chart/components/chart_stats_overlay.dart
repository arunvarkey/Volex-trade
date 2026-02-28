import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${currentPrice.toStringAsFixed(currentPrice >= 1 ? 2 : 4)}',
              style: VxTypography.hero.copyWith(
                fontFamily: GoogleFonts.spaceMono().fontFamily,
                fontSize: 28,
                letterSpacing: -1.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPos ? VxColors.success : VxColors.danger)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPos ? '+' : ''}${change24h.toStringAsFixed(2)}%',
                  style: VxTypography.caption.copyWith(
                    color: isPos ? VxColors.success : VxColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              label: "24h High",
              value: high24h.toStringAsFixed(high24h >= 1 ? 2 : 4),
              color: VxColors.success,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              label: "24h Low",
              value: low24h.toStringAsFixed(low24h >= 1 ? 2 : 4),
              color: VxColors.danger,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              label: "24h Volume",
              value: _formatVolume(volume24h),
              color: VxColors.neonCyan,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      {required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: VxColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VxColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: VxTypography.caption.copyWith(
              color: VxColors.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label == "24h Volume" ? value : '\$ $value',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: GoogleFonts.spaceMono().fontFamily,
            ),
          ),
        ],
      ),
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

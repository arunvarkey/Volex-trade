import 'package:flutter/material.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import '../../models/prediction_models.dart';

Color categoryColor(MarketCategory category) {
  switch (category) {
    case MarketCategory.crypto:
      return VxColors.neonYellow;
    case MarketCategory.macro:
      return VxColors.neonCyan;
    case MarketCategory.politics:
      return VxColors.neonPurple;
    case MarketCategory.tech:
      return VxColors.info;
    case MarketCategory.culture:
      return VxColors.neonMagenta;
  }
}

/// A card in the horizontal "trending mentions" feed.
class BuzzCard extends StatelessWidget {
  final MentionBuzz buzz;
  final VoidCallback onTap;
  const BuzzCard({super.key, required this.buzz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sentimentColor =
        buzz.bullish ? VxColors.neonGreen : VxColors.neonRed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VxColors.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sentimentColor.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(buzz.avatarEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    buzz.author,
                    style: VxTypography.bodySmall.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  buzz.bullish
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: sentimentColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                '"${buzz.quote}"',
                style: VxTypography.bodySmall.copyWith(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.white70,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.forum_rounded,
                    size: 12, color: VxColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${_compact(buzz.mentions)} mentions',
                  style: VxTypography.caption.copyWith(fontSize: 10),
                ),
                const Spacer(),
                Text(buzz.timeAgo,
                    style: VxTypography.caption.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// A row in the event-markets list.
class MarketRow extends StatelessWidget {
  final EventMarket market;
  final VoidCallback onTap;
  const MarketRow({super.key, required this.market, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = categoryColor(market.category);
    final bool up = market.change24h >= 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VxColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cat.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${market.category.emoji} ${market.category.label}',
                    style: VxTypography.caption.copyWith(
                        fontSize: 9.5, color: cat, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 18,
                    color: up ? VxColors.neonGreen : VxColors.neonRed),
                Text(
                  '${market.change24h.abs()}%',
                  style: VxTypography.caption.copyWith(
                    fontSize: 11,
                    color: up ? VxColors.neonGreen : VxColors.neonRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              market.question,
              style: VxTypography.body
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ProbabilityBar(yesPrice: market.yesPrice),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Vol \$${_compactMoney(market.volume)}',
                    style: VxTypography.caption.copyWith(fontSize: 10)),
                const Spacer(),
                Text('Closes ${market.closesLabel}',
                    style: VxTypography.caption.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _compactMoney(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }
}

/// The Yes/No implied-probability bar used on market rows and detail views.
class ProbabilityBar extends StatelessWidget {
  final int yesPrice; // 1..99
  const ProbabilityBar({super.key, required this.yesPrice});

  @override
  Widget build(BuildContext context) {
    final yes = yesPrice.clamp(1, 99);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Expanded(
                flex: yes,
                child: Container(height: 10, color: VxColors.neonGreen),
              ),
              Expanded(
                flex: 100 - yes,
                child: Container(height: 10, color: VxColors.neonRed),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('YES $yes¢',
                style: VxTypography.caption.copyWith(
                    fontSize: 11,
                    color: VxColors.neonGreen,
                    fontWeight: FontWeight.w700)),
            Text('NO ${100 - yes}¢',
                style: VxTypography.caption.copyWith(
                    fontSize: 11,
                    color: VxColors.neonRed,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

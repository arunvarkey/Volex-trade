import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/domain/mini_ticker.dart';
import 'package:volex_terminal/services/haptic_service.dart';
import 'package:volex_terminal/services/market_ticker_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_coin_icon.dart';
import 'ticker_format.dart';

/// Dense live watchlist — symbol, name, 24h range bar, monospace price and
/// a red/green 24h change chip. Tap a row to open its chart.
class VxMarketList extends StatefulWidget {
  const VxMarketList({super.key});

  @override
  State<VxMarketList> createState() => _VxMarketListState();
}

class _VxMarketListState extends State<VxMarketList> {
  final MarketTickerService _service = MarketTickerService.instance;

  @override
  void initState() {
    super.initState();
    _service.start();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final tickers = _service.tickers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MARKETS',
                    style: VxTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: VxColors.textTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'LIVE • 24H',
                    style: VxTypography.caption.copyWith(
                      fontSize: 9.5,
                      color: VxColors.neonGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: VxColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: tickers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: VxColors.neonCyan),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < tickers.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Colors.white10),
                            _MarketRow(ticker: tickers[i]),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MarketRow extends StatelessWidget {
  final MiniTicker ticker;
  const _MarketRow({required this.ticker});

  @override
  Widget build(BuildContext context) {
    final up = ticker.changePercent >= 0;
    final color = up ? VxColors.neonGreen : VxColors.neonRed;
    final base = baseAsset(ticker.symbol);
    final name = MarketTickerService.names[ticker.symbol] ?? base;

    // Position of last price within the 24h low-high range (0..1).
    final range = ticker.highPrice - ticker.lowPrice;
    final rangePos = range <= 0
        ? 0.5
        : ((ticker.closePrice - ticker.lowPrice) / range).clamp(0.0, 1.0);

    return InkWell(
      onTap: () {
        HapticService.instance.light();
        context.push('/chart?symbol=${ticker.symbol}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // Asset badge
            VxCoinIcon(ticker.symbol, size: 34),
            const SizedBox(width: 12),
            // Symbol + name + volume
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(base,
                          style: VxTypography.body.copyWith(
                              fontSize: 14.5, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4),
                      Text('/USDT',
                          style: VxTypography.caption
                              .copyWith(fontSize: 9.5, color: Colors.white30)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$name • Vol ${formatQuoteVolume(ticker.quoteVolume)}',
                    style: VxTypography.caption
                        .copyWith(fontSize: 10, color: VxColors.textTertiary),
                  ),
                ],
              ),
            ),
            // 24h range bar
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('24H RANGE',
                      style: VxTypography.caption
                          .copyWith(fontSize: 7, color: Colors.white24)),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: rangePos == 0 ? 0.02 : rangePos,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Price + change chip
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatPrice(ticker.closePrice),
                    style: VxTypography.price.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${up ? '+' : ''}${ticker.changePercent.toStringAsFixed(2)}%',
                    style: VxTypography.price
                        .copyWith(fontSize: 10.5, color: color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:volex_terminal/domain/mini_ticker.dart';
import 'package:volex_terminal/services/market_ticker_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_coin_icon.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'ticker_format.dart';

/// A continuously scrolling tape of live prices — the classic trading
/// terminal marquee.
class VxTickerTape extends StatefulWidget {
  const VxTickerTape({super.key});

  @override
  State<VxTickerTape> createState() => _VxTickerTapeState();
}

class _VxTickerTapeState extends State<VxTickerTape> {
  static const int _repeats = 40; // long enough that wrap-around is rare
  final MarketTickerService _service = MarketTickerService.instance;
  final ScrollController _controller = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _service.start();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted || !_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) return;
      final next = _controller.offset + 0.8;
      if (next >= max) {
        _controller.jumpTo(0);
      } else {
        _controller.jumpTo(next);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final tickers = _service.tickers;
        if (tickers.isEmpty) return const SizedBox(height: 34);
        return Container(
          height: 34,
          decoration: const BoxDecoration(
            color: VxColors.surface,
            border: Border(
              top: BorderSide(color: Colors.white10, width: 0.5),
              bottom: BorderSide(color: Colors.white10, width: 0.5),
            ),
          ),
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tickers.length * _repeats,
            itemBuilder: (context, i) =>
                _TapeItem(ticker: tickers[i % tickers.length]),
          ),
        );
      },
    );
  }
}

class _TapeItem extends StatelessWidget {
  final MiniTicker ticker;
  const _TapeItem({required this.ticker});

  @override
  Widget build(BuildContext context) {
    final up = ticker.changePercent >= 0;
    final color = up ? VxColors.neonGreen : VxColors.neonRed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VxCoinIcon(ticker.symbol, size: 16),
          const SizedBox(width: 6),
          Text(
            baseAsset(ticker.symbol),
            style: VxTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatPrice(ticker.closePrice),
            style: VxTypography.price.copyWith(fontSize: 11.5),
          ),
          const SizedBox(width: 5),
          Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16, color: color),
          Text(
            '${ticker.changePercent.abs().toStringAsFixed(2)}%',
            style: VxTypography.price.copyWith(fontSize: 10.5, color: color),
          ),
        ],
      ),
    );
  }
}

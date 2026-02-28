import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/terminal_settings_provider.dart';

import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';
import '../design_system/vx_card.dart';
import '../../data/market_data_repository.dart';
import '../../domain/candle_model.dart';
import '../providers/dashboard_provider.dart';
import '../../engine/execution_manager.dart';
import 'trade/trade_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // 1. Total Balance Header
          _CockpitHeader(),

          const SizedBox(height: 32),

          // 2. Strategy Status Pill
          Center(child: _StatusPill()),

          const SizedBox(height: 48),

          // 3. Watchlist / Markets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VxText.subtitle("MARKETS", color: Colors.white54),
              const Icon(Icons.sort, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 16),
          _MarketList(),

          const SizedBox(height: 120), // Bottom padding for FAB
        ],
      ),
    );
  }
}

class _CockpitHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        return Column(
          children: [
            VxText.body("TOTAL PORTFOLIO VALUE", color: Colors.white54),
            const SizedBox(height: 8),
            Text(
              "\$${dashboard.totalBalanceUsdt.toStringAsFixed(2)}",
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 8),
            // PnL Chip (Mocked for V1, but could be wired to dailyLoss)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (dashboard.dailyPnL >= 0
                        ? VxColors.neonGreen
                        : VxColors.neonRed)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      dashboard.dailyPnL >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: dashboard.dailyPnL >= 0
                          ? VxColors.neonGreen
                          : VxColors.neonRed,
                      size: 12),
                  const SizedBox(width: 4),
                  Text(
                      "${dashboard.dailyPnL >= 0 ? '+' : ''}${((dashboard.dailyPnL / 10000.0) * 100).toStringAsFixed(2)}% (\$${dashboard.dailyPnL.toStringAsFixed(2)})",
                      style: TextStyle(
                          color: dashboard.dailyPnL >= 0
                              ? VxColors.neonGreen
                              : VxColors.neonRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ExecutionManager>(
      builder: (context, manager, _) {
        final isLive = manager.isLiveMode;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: VxColors.surface,
            borderRadius: BorderRadius.circular(30),
            border:
                Border.all(color: isLive ? VxColors.neonCyan : Colors.white10),
            boxShadow: [
              if (isLive)
                BoxShadow(
                    color: VxColors.neonCyan.withOpacity(0.2), blurRadius: 16)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isLive ? VxColors.neonCyan : Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isLive ? "SYSTEM: ACTIVE" : "SYSTEM: IDLE",
                style: TextStyle(
                  color: isLive ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarketList extends StatelessWidget {
  final List<String> markets = ["BTC/USDT", "ETH/USDT", "SOL/USDT"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: markets.map((symbol) => _MarketTile(symbol: symbol)).toList(),
    );
  }
}

class _MarketTile extends StatelessWidget {
  final String symbol;
  const _MarketTile({required this.symbol});

  @override
  Widget build(BuildContext context) {
    // Determine if we show charts or just open Trade Sheet
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: VxCard(
        onTap: () {
          // Pro Mode Logic Check
          final isPro = context.read<TerminalSettingsProvider>().isProMode;
          if (isPro) {
            context.push('/chart?symbol=$symbol');
          } else {
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      color: Colors.transparent,
                      child: TradeSheet(symbol: symbol),
                    ));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.currency_bitcoin,
                    color: Colors.white), // Generic for now
              ),
              const SizedBox(width: 16),
              // Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VxText.bodyBold(symbol, color: Colors.white),
                  VxText.caption("Binance Spot", color: Colors.white38),
                ],
              ),
              const Spacer(),
              // Price (Mocked/Connected)
              StreamBuilder<Candle>(
                stream: MarketDataRepository().updatesStream,
                builder: (context, snapshot) {
                  // Filter for symbol in real app, here assuming default stream is BTC
                  // In a real list we need multiple streams.
                  // Simplification: Only BTC updates live, others static for V1 mock
                  String price = "---";
                  if (symbol.startsWith("BTC")) {
                    price = snapshot.hasData
                        ? snapshot.data!.close.toStringAsFixed(2)
                        : "95,000.00";
                  } else if (symbol.startsWith("ETH")) {
                    price = "2,450.00";
                  } else {
                    price = "145.00";
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      VxText.bodyBold(price),
                      const Text("+1.2%",
                          style: TextStyle(
                              color: VxColors.neonGreen, fontSize: 12)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

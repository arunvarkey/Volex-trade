import 'package:flutter/material.dart';
import '../navigation/vx_navigation_helper.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../../engine/execution_manager.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_action_center.dart';
import '../sheets/vx_trade_sheet.dart';
import '../../data/market_data_repository.dart';

/// The "Cockpit" - Simplified Home Screen
class VxCockpit extends StatefulWidget {
  const VxCockpit({super.key});

  @override
  State<VxCockpit> createState() => _VxCockpitState();
}

class _VxCockpitState extends State<VxCockpit> {
  @override
  Widget build(BuildContext context) {
    // Consume Data
    final dashboard = Provider.of<DashboardProvider>(context);

    // Initial Snapshot Trigger (if empty)
    if (dashboard.watchlistMap.isEmpty) {
      // We could trigger a fetch here if needed, but repository handles streams.
    }

    return Scaffold(
      backgroundColor: VxColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top: Total Balance
            _buildBalanceHeader(dashboard),

            const SizedBox(height: 24),

            // Middle: Strategy Status
            _buildStrategyStatus(dashboard),

            const SizedBox(height: 24),

            // Bottom: Watchlist / Markets
            Expanded(child: _buildWatchlist(dashboard)),
          ],
        ),
      ),
      floatingActionButton: const VxActionCenter(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBalanceHeader(DashboardProvider dashboard) {
    final em = context.watch<ExecutionManager>();
    final dailyPnL = em.todayPnL;
    final totalBalance = dashboard.totalBalanceUsdt;
    final prevBalance = totalBalance - dailyPnL;
    final dailyPnLPercent =
        prevBalance > 0 ? (dailyPnL / prevBalance) * 100 : 0.0;
    final isLoss = dailyPnL < 0;
    final isNeutral = dailyPnL == 0;

    return Center(
      child: Column(
        children: [
          const Text(
            'TOTAL BALANCE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNeutral
                    ? Icons.trending_flat
                    : (isLoss ? Icons.trending_down : Icons.trending_up),
                color: isNeutral
                    ? Colors.white54
                    : (isLoss ? VxColors.neonRed : Colors.green),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isLoss ? '' : '+'}${dailyPnL.toStringAsFixed(2)} (${dailyPnLPercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: isNeutral
                      ? Colors.white54
                      : (isLoss ? VxColors.neonRed : Colors.green),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyStatus(DashboardProvider dashboard) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VxColors.neonPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Animated Status Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dashboard.riskColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dashboard.riskColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dashboard.riskStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active: ${dashboard.activeStrategyName} • Drawdown: ${(dashboard.currentDrawdown * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildWatchlist(DashboardProvider dashboard) {
    // If empty, show fallback list or spinner
    // For now we rely on the provider stream.
    // If the provider has data, we use it. If not, we show "Connecting..."

    if (dashboard.watchlistMap.isEmpty) {
      // Fallback or Loading
      return const Center(
          child: CircularProgressIndicator(color: VxColors.neonCyan));
    }

    final tickers = dashboard.watchlistList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WATCHLIST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              // Search/Add
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white54, size: 20),
                onPressed: () => showSearch(
                  context: context,
                  delegate: MarketSearchDelegate(
                      (symbol, price) => _openTradeSheet(symbol, price)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tickers.length,
            itemBuilder: (context, index) {
              final ticker = tickers[index];
              return _MarketTile(
                symbol: ticker.symbol,
                price: ticker.closePrice,
                changePercent: ticker.changePercent,
                onTap: () => _openTradeSheet(ticker.symbol, ticker.closePrice),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openTradeSheet(String symbol, double price) {
    // Switch Repository Stream to this symbol for the chart
    MarketDataRepository().switchSymbol(symbol);

    VxTradeSheet.show(
      context,
      symbol: symbol,
      currentPrice: price,
      candles: [], // Will load async in sheet via stream if we update sheet too
      onExpand: () {
        // Navigate to Analyst Tab via Helper
        // We verify Pro Mode first? Ideally Helper or Navigator handles permission or UI just works
        // Assuming Pro Mode is active if this is clicked (or we check provider)
        // For V1, we just switch.

        // Circular dependency risk if we check ProMode here without context access in helper?
        // We will just switch. MainNavigator handles effective index.
        VxNavigationHelper.navigateToAnalyst();
      },
    );
  }
}

class _MarketTile extends StatelessWidget {
  final String symbol;
  final double price;
  final double changePercent;
  final VoidCallback onTap;

  const _MarketTile({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent >= 0;
    final changeColor = isPositive ? VxColors.neonGreen : VxColors.neonRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Symbol Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      symbol.substring(0, 1),
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Symbol
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price & Change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MarketSearchDelegate extends SearchDelegate {
  final Function(String, double) onSelect;
  final List<String> _markets = [
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
    'BNBUSDT',
    'ADAUSDT',
    'XRPUSDT',
    'DOGEUSDT',
    'AVAXUSDT'
  ];

  MarketSearchDelegate(this.onSelect);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: VxColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: VxColors.surface,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white38),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _markets
        .where((m) => m.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final symbol = results[index];
        return ListTile(
          leading: const Icon(Icons.show_chart, color: VxColors.neonCyan),
          title: Text(symbol,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          onTap: () {
            close(context, null);
            // Mock price for search result (would fetch real in prod)
            onSelect(symbol, 50000.0);
          },
        );
      },
    );
  }
}

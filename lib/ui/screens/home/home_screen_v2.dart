import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/ui/sheets/smart_order_sheet.dart';
import 'package:volex_terminal/ui/providers/dashboard_provider.dart';
import 'package:volex_terminal/data/i_market_data_repository.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/ui/widgets/mode_indicator_banner.dart';
import 'package:volex_terminal/engine/notifications/notification_bus.dart';
import 'package:volex_terminal/ui/widgets/quantum_switcher.dart';
import 'package:volex_terminal/services/haptic_service.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/ui/widgets/market_ticker/vx_ticker_tape.dart';
import 'package:volex_terminal/ui/widgets/market_ticker/vx_market_list.dart';
import 'package:volex_terminal/ui/widgets/journey_strip.dart';

class HomeScreenV2 extends StatelessWidget {
  const HomeScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Mode indicator banner
            Consumer<DashboardProvider>(
              builder: (context, provider, _) => ModeIndicatorBanner(
                mode: provider.userMode,
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBar(context),
                    const VxTickerTape(),
                    _buildBalanceSection(context),
                    const JourneyStrip(),
                    _buildQuickActions(context),
                    const VxMarketList(),
                    _buildQuickTradeSection(context),
                    _buildYourStrategiesSection(context),
                    _buildLearningCTA(context),
                    _buildPredictionsCTA(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) greeting = 'Good afternoon';
    if (hour >= 17) greeting = 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: VxTypography.bodySmall
                  .copyWith(color: VxColors.textSecondary),
              children: [
                TextSpan(text: '$greeting, '),
                const TextSpan(
                  text: 'Trader',
                  style: TextStyle(
                    color: VxColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildIconButton(
                icon: Icons.search_rounded,
                onPressed: () => QuantumSwitcher.show(context, (symbol) {
                  context.push('/chart?symbol=$symbol');
                }),
              ),
              const SizedBox(width: 8),
              _buildNotificationButton(context),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.person_outline_rounded,
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: VxColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: VxColors.border),
        ),
        child: Icon(icon, size: 18, color: VxColors.textSecondary),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return StreamBuilder<int>(
      stream: getIt<NotificationBus>().unreadCountStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return InkWell(
          onTap: () => context.push('/notifications'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VxColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: VxColors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    size: 18, color: VxColors.textSecondary),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: VxColors.danger,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: VxColors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceSection(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final dailyPnL = dashboard.dailyPnL;
        final isPositive = dailyPnL >= 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: InkWell(
            onTap: () => context.push('/portfolio'),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SIMULATED BALANCE',
                      style: VxTypography.caption.copyWith(
                        color: VxColors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: VxColors.neonCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PAPER',
                        style: VxTypography.caption.copyWith(
                          color: VxColors.neonCyan,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${dashboard.totalBalanceUsdt.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: VxTypography.hero,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${dailyPnL == 0 ? '' : (dailyPnL > 0 ? '+' : '-')}\$${dailyPnL.abs().toStringAsFixed(2)} today',
                      style: TextStyle(
                        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dailyPnL == 0
                            ? VxColors.textTertiary
                            : (isPositive ? VxColors.success : VxColors.danger),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dailyPnL == 0
                      ? 'Place your first trade to get started'
                      : 'Portfolio performance is tracking correctly',
                  style: VxTypography.caption
                      .copyWith(color: VxColors.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Builder',
              subtitle: 'Create a strategy with AI',
              iconBgColor: const Color(0x1F63B3ED),
              onTap: () => context.push('/ai-strategy'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              icon: Icons.science_rounded,
              title: 'Backtest',
              subtitle: 'Test against real history',
              iconBgColor: const Color(0x1FB794F4),
              onTap: () => context.push('/lab'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              icon: Icons.sensors_rounded,
              title: 'Signals',
              subtitle: 'AI trade ideas',
              iconBgColor: const Color(0x1F34D399),
              onTap: () => context.push('/signals'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTradeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK TRADE',
                style: VxTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: VxColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/market-scanner'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'All Markets →',
                  style: VxTypography.caption.copyWith(
                    color: VxColors.neonCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StreamBuilder<Candle>(
            stream:
                getIt<IMarketDataRepository>().getStreamForSymbol('BTCUSDT'),
            builder: (context, snapshot) {
              final price = snapshot.hasData ? snapshot.data!.close : 68895.0;
              final priceChange = snapshot.hasData
                  ? ((snapshot.data!.close - snapshot.data!.open) /
                          snapshot.data!.open) *
                      100
                  : 1.24;
              final isPositive = priceChange >= 0;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: VxColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: VxColors.border),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticService.instance.light();
                        context.push('/chart?symbol=BTCUSDT');
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: VxColors.success.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.currency_bitcoin_rounded,
                                    color: VxColors.success,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BTC / USDT',
                                    style: VxTypography.body
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${isPositive ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                                    style: VxTypography.caption.copyWith(
                                      color: isPositive
                                          ? VxColors.success
                                          : VxColors.danger,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '\$${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: VxTypography.price.copyWith(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _TradeButton(
                            label: 'BUY / LONG',
                            color: VxColors.success,
                            onPressed: () =>
                                _showOrderDialog(context, OrderSide.buy, price),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TradeButton(
                            label: 'SELL / SHORT',
                            color: VxColors.danger,
                            onPressed: () => _showOrderDialog(
                                context, OrderSide.sell, price),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYourStrategiesSection(BuildContext context) {
    final exec = context.watch<ExecutionManager>();
    final manualPnL = exec.totalPnL;
    final manualTrades = exec.positions.where((p) => !p.isOpen).length;
    final balance = exec.balance;
    final manualPnLPercent =
        balance > 0 ? (manualPnL / (balance - manualPnL)) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR PERFORMANCE',
                style: VxTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: VxColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/activity'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All →',
                  style: VxTypography.caption.copyWith(
                    color: VxColors.neonCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _StrategyCard(
                icon: '🛠️',
                iconColor: VxColors.neonCyan,
                name: 'Manual Trading',
                status: 'Active · $manualTrades trades completed',
                pnl: manualPnL,
                pnlPercent: manualPnLPercent,
                onTap: () => context.push('/activity'),
              ),
              const SizedBox(height: 8),
              _StrategyCard(
                icon: '🤖',
                iconColor: VxColors.success,
                name: 'AI Signal Sentinel',
                status: 'Idle · Listening for signals',
                pnl: 0.00,
                pnlPercent: 0.00,
                onTap: () => context.push('/signals'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearningCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: InkWell(
        onTap: () => context.push('/learn'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [VxColors.surfaceBright, VxColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: VxColors.neonCyan.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: VxColors.neonCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New to trading?',
                      style: VxTypography.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Start free lessons — learn step by step, zero risk',
                      style: VxTypography.bodySmall.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: VxColors.neonCyan, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionsCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: InkWell(
        onTap: () => context.go('/predictions'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VxColors.neonPurple.withOpacity(0.18),
                VxColors.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: VxColors.neonPurple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: VxColors.neonPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🔮', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buzz & Predictions',
                      style: VxTypography.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Trade politics, crypto & events on sentiment — virtual',
                      style: VxTypography.bodySmall.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: VxColors.neonPurple, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDialog(
      BuildContext context, OrderSide side, double currentPrice) {
    HapticService.instance.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartOrderSheet(
        symbol: 'BTCUSDT',
        currentPrice: currentPrice,
        isBuy: side == OrderSide.buy,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.instance.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: VxColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VxColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                  child: Icon(
                icon,
                size: 16,
                color: iconBgColor.withOpacity(0.95),
              )),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: VxTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: VxColors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: VxTypography.caption.copyWith(
                color: VxColors.textTertiary,
                fontSize: 10.5,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _TradeButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Center(
          child: Text(
            label,
            style: VxTypography.button.copyWith(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String name;
  final String status;
  final double pnl;
  final double pnlPercent;
  final VoidCallback onTap;

  const _StrategyCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.status,
    required this.pnl,
    required this.pnlPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = pnl >= 0;

    return InkWell(
      onTap: () {
        HapticService.instance.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VxColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VxColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: VxTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: VxColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const _PulseDot(),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: VxTypography.caption.copyWith(
                          color: VxColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? VxColors.success : VxColors.danger,
                  ),
                ),
                Text(
                  '${isPositive ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                  style: VxTypography.caption
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: VxColors.neonCyan,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

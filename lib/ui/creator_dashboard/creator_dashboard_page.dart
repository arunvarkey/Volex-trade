import 'package:flutter/material.dart';
import '../../engine/analytics/analytics_aggregator.dart';
import '../../engine/analytics/analytics_models.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';
import '../design_system/vx_spacing.dart';

class CreatorDashboardPage extends StatefulWidget {
  final String creatorId;

  const CreatorDashboardPage({super.key, required this.creatorId});

  @override
  State<CreatorDashboardPage> createState() => _CreatorDashboardPageState();
}

class _CreatorDashboardPageState extends State<CreatorDashboardPage> {
  late AnalyticsAggregator _aggregator;
  late RevenueAnalytics _revenue;
  late StrategyPerformanceMetrics _topStrategyMetrics;
  late SubscriberAnalytics _topStrategySubs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _aggregator = AnalyticsAggregator();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final revenue = await _aggregator.getRevenueAnalytics(widget.creatorId);
    final metrics = await _aggregator.getPerformanceMetrics('strat_1');
    final subs = await _aggregator.getSubscriberAnalytics('strat_1');

    if (mounted) {
      setState(() {
        _revenue = revenue;
        _topStrategyMetrics = metrics;
        _topStrategySubs = subs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: VxColors.background,
        body:
            Center(child: CircularProgressIndicator(color: VxColors.neonCyan)),
      );
    }

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: VxText.heading2("CREATOR_DASHBOARD", color: Colors.white),
        backgroundColor: Colors.black45,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: VxColors.neonCyan),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VxSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildRevenueSection(),
            const SizedBox(height: 40),
            VxText.heading3("STRATEGY_PERFORMANCE // ELITE_FEED",
                color: Colors.white),
            const SizedBox(height: 16),
            _buildPerformanceGrid(),
            const SizedBox(height: 40),
            VxText.heading3("AUDIENCE_INSIGHTS // SUBSCRIBER_GROWTH",
                color: Colors.white),
            const SizedBox(height: 16),
            _buildSubscriberSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
            radius: 28,
            backgroundColor: VxColors.neonCyan,
            child: Icon(Icons.person, color: Colors.black, size: 28)),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VxText.heading1("WELCOME_BACK, CREATOR", color: Colors.white),
            const SizedBox(height: 4),
            VxText.body("QUANT_TERMINAL_ANALYTICS // LIVE_SYNC",
                color: Colors.white24),
          ],
        )
      ],
    );
  }

  Widget _buildRevenueSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VxColors.neonGreen.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
                color: VxColors.neonGreen.withOpacity(0.02), blurRadius: 40)
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
              "MONTHLY_REVENUE",
              "\$${_revenue.monthlyRevenue.toStringAsFixed(2)}",
              VxColors.neonGreen),
          _buildMetric("LIFETIME_REVENUE",
              "\$${_revenue.lifetimeRevenue.toStringAsFixed(0)}", Colors.white),
          _buildMetric(
              "PENDING_PAYOUT",
              "\$${_revenue.pendingPayouts.toStringAsFixed(2)}",
              Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildCard(
            "WIN_RATE",
            "${(_topStrategyMetrics.winRate * 100).toStringAsFixed(1)}%",
            VxColors.neonCyan),
        _buildCard(
            "AVG_RETURN",
            "${(_topStrategyMetrics.avgReturn * 100).toStringAsFixed(2)}%",
            VxColors.neonCyan),
        _buildCard(
            "SHARPE_RATIO",
            _topStrategyMetrics.sharpeEstimate.toStringAsFixed(2),
            Colors.purpleAccent),
        _buildCard(
            "MAX_DRAWDOWN",
            "${_topStrategyMetrics.maxDrawdown.toStringAsFixed(1)}%",
            VxColors.neonMagenta),
      ],
    );
  }

  Widget _buildSubscriberSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetric("ACTIVE_SUBSCRIBERS",
                  "${_topStrategySubs.activeSubscribers}", Colors.white70),
              const SizedBox(height: 20),
              _buildMetric(
                  "NEW_SUBS_30D",
                  "+${_topStrategySubs.newSubscribersLast30Days}",
                  VxColors.neonGreen),
            ],
          ),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: VxColors.neonCyan.withOpacity(0.3), width: 2)),
            child: Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VxText.monoBold("PRO", fontSize: 12, color: VxColors.neonCyan),
                VxText.mono("20%", fontSize: 10, color: Colors.white38),
              ],
            )),
          )
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        VxText.monoBold(value, fontSize: 24, color: color),
        const SizedBox(height: 6),
        VxText.mono(label, color: Colors.white24, fontSize: 11),
      ],
    );
  }

  Widget _buildCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VxText.monoBold(value, fontSize: 22, color: color),
          const SizedBox(height: 8),
          VxText.mono(label, color: Colors.white24, fontSize: 11),
        ],
      ),
    );
  }
}

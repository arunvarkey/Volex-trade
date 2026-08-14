import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../ui/design_system/vx_colors.dart';
import '../../../features/subscriptions/services/subscription_service.dart';
import '../ai_strategy/services/strategy_repository.dart';
import '../../../engine/marketplace/marketplace_service.dart';
import '../../../engine/marketplace/models/strategy_listing.dart';
import '../../../services/profile_service.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:intl/intl.dart';

class MyStrategiesScreen extends StatefulWidget {
  const MyStrategiesScreen({super.key});

  @override
  State<MyStrategiesScreen> createState() => _MyStrategiesScreenState();
}

class _MyStrategiesScreenState extends State<MyStrategiesScreen> {
  final _repository = GetIt.I<StrategyRepository>();
  final _subscription = GetIt.I<SubscriptionService>();
  List<GeneratedStrategy> _strategies = [];

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  void _loadStrategies() {
    setState(() {
      _strategies = _repository.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final limit = _subscription.maxStrategies;
    final count = _strategies.length;

    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      appBar: AppBar(
        backgroundColor: VxColors.deepBlack,
        title: Text(
          'MY STRATEGIES ($count/$limit)',
          style: const TextStyle(
            color: VxColors.neonCyan,
            letterSpacing: 0.3,
            fontSize: 16,
          ),
        ),
        actions: [
          if (count < limit)
            IconButton(
              icon: const Icon(Icons.add, color: VxColors.neonGreen),
              onPressed: () => context
                  .push('/simulator/templates')
                  .then((_) => _loadStrategies()),
            ),
        ],
      ),
      body: _strategies.isEmpty ? _buildEmptyState() : _buildStrategyList(),
      floatingActionButton: _strategies.isNotEmpty && count < limit
          ? FloatingActionButton.extended(
              onPressed: () => context
                  .push('/simulator/templates')
                  .then((_) => _loadStrategies()),
              backgroundColor: VxColors.neonGreen,
              foregroundColor: VxColors.deepBlack,
              label: const Text('Create Strategy',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 100, color: Colors.grey[800]),
          const SizedBox(height: 24),
          Text(
            'No strategies yet',
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first AI-powered strategy',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context
                .push('/simulator/templates')
                .then((_) => _loadStrategies()),
            icon: const Icon(Icons.add),
            label: const Text('Create Strategy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonGreen,
              foregroundColor: VxColors.deepBlack,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _strategies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final strategy = _strategies[index];
        return _buildStrategyCard(strategy);
      },
    );
  }

  Widget _buildStrategyCard(GeneratedStrategy strategy) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VxColors.neonCyan.withValues(alpha: 0.05),
            VxColors.neonCyan.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strategy.name.toUpperCase(),
                  style: const TextStyle(
                    color: VxColors.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: VxColors.neonRed),
                onPressed: () => _confirmDelete(strategy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Template: ${strategy.templateId}',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Created: ${_formatDate(strategy.createdAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            '${strategy.symbol} • ${strategy.timeframe}',
            style: TextStyle(
                color: Colors.grey[500], fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _backtest(strategy),
                  icon: const Icon(Icons.science, size: 16),
                  label: const Text('Backtest'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VxColors.neonGreen,
                    side: const BorderSide(color: VxColors.neonGreen),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startPaperTrading(strategy),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Paper Trade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VxColors.neonCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _publish(strategy),
              icon: const Icon(Icons.publish_outlined, size: 16),
              label: const Text('Publish to Marketplace'),
              style: TextButton.styleFrom(foregroundColor: VxColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _confirmDelete(GeneratedStrategy strategy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.deepBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'DELETE STRATEGY?',
          style: TextStyle(
            color: VxColors.neonRed,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${strategy.name}"?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _repository.delete(strategy.id);
              Navigator.pop(context);
              _loadStrategies();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Strategy deleted'),
                  backgroundColor: VxColors.neonRed,
                ),
              );
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: VxColors.neonRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _backtest(GeneratedStrategy strategy) {
    context.push('/lab/backtest/config', extra: strategy);
  }

  StrategyCategory _categoryFor(String? templateId) {
    switch (templateId) {
      case 'rsi_mean_reversion':
        return StrategyCategory.meanReversion;
      case 'breakout':
        return StrategyCategory.breakout;
      case 'ma_crossover':
      case 'macd_trend':
        return StrategyCategory.trendFollowing;
      default:
        return StrategyCategory.aiExperimental;
    }
  }

  Future<void> _publish(GeneratedStrategy strategy) async {
    final now = DateTime.now();
    // Paper-only, free, unverified: no real money changes hands and no
    // performance is claimed until the strategy is independently verified.
    final listing = StrategyListing(
      id: strategy.id,
      authorId: 'me',
      authorName: GetIt.I<ProfileService>().displayName,
      title: strategy.name,
      description: strategy.description,
      category: _categoryFor(strategy.templateId),
      monthlyPrice: 0,
      tier: MarketplaceTier.free,
      totalReturn: 0,
      winRate: 0,
      maxDrawdown: 0,
      verified: false,
      createdAt: now,
      lastUpdated: now,
    );
    try {
      await GetIt.I<MarketplaceService>().publishStrategy(listing);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not publish — try again.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Published to Marketplace (free · paper-only · unverified)'),
        backgroundColor: VxColors.neonGreen,
      ),
    );
  }

  void _startPaperTrading(GeneratedStrategy strategy) {
    context.push('/chart?symbol=${strategy.symbol}');
  }
}

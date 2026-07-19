import 'package:flutter/material.dart';
import '../../../engine/marketplace/marketplace_service.dart';
import '../../../engine/marketplace/models/strategy_listing.dart';
import '../../../core/service_locator.dart';
import '../../design_system/vx_colors.dart';
import 'strategy_details_screen.dart';
import 'package:volex_terminal/ui/wizard/smart_strategy_wizard.dart';
import 'leaderboard_screen.dart';
import '../../design_system/vx_toolbar.dart';
import '../../design_system/vx_typography.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _marketplace = getIt<MarketplaceService>();
  List<StrategyListing> _featured = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _marketplace.getFeaturedStrategies();
    if (mounted) {
      setState(() {
        _featured = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: VxColors.background,
        appBar: VxToolbar(
          title: VxText.title('Marketplace'),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
          ],
          bottom: const TabBar(
            indicatorColor: VxColors.accent,
            labelColor: VxColors.accent,
            unselectedLabelColor: VxColors.neutral500,
            tabs: [
              Tab(text: 'Browse'),
              Tab(text: 'Leaderboard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBrowseTab(),
            const LeaderboardScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: VxColors.accent,
          foregroundColor: VxColors.neutral900,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const SmartStrategyWizard(),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Featured Strategies'),
              const SizedBox(height: 12),
              _buildFeaturedCarousel(),
              const SizedBox(height: 24),
              _buildSectionHeader('Top Rated'),
              const SizedBox(height: 12),
              ..._featured.map((s) => _buildStrategyCard(s)),
            ],
          );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: VxColors.neutral100,
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    // Simplified carousel for prototype
    if (_featured.isEmpty) return const SizedBox();
    final top = _featured.first;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VxColors.primary700, VxColors.primary900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: VxColors.neutral900.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('FEATURED',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Text(top.title,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(top.authorName,
              style: const TextStyle(color: VxColors.neutral400)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up, color: VxColors.positive, size: 16),
              const SizedBox(width: 4),
              Text('+${top.totalReturn}%',
                  style: const TextStyle(
                      color: VxColors.positive, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StrategyDetailsScreen(strategy: top),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.accent,
                  foregroundColor: VxColors.neutral900,
                ),
                child: const Text('View'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStrategyCard(StrategyListing s) {
    return Card(
      color: VxColors.neutral800,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: VxColors.neutral700,
            child:
                Text(s.title[0], style: const TextStyle(color: Colors.white))),
        title:
            Text(s.title, style: const TextStyle(color: VxColors.neutral100)),
        subtitle: Text(
            'Return: +${s.totalReturn}%  •  Win Rate: ${(s.winRate * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: VxColors.neutral400)),
        trailing: Text('\$${s.monthlyPrice}',
            style: const TextStyle(
                color: VxColors.accent, fontWeight: FontWeight.bold)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StrategyDetailsScreen(strategy: s),
            ),
          );
        },
      ),
    );
  }
}

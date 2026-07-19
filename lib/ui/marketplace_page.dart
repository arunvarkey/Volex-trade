import 'package:flutter/material.dart';
import '../engine/strategy/strategy_registry.dart';
import 'strategy_card.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';
import '../core/app_logger.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final StrategyRegistry _registry = StrategyRegistry();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: VxText.heading2("STRATEGY_MARKETPLACE", color: Colors.white),
        backgroundColor: Colors.black45,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(VxSpacing.lg),
            child: TextField(
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'RobotoMono'),
              decoration: InputDecoration(
                hintText: "SEARCH_GENOMES...",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: VxColors.neonCyan, size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.02),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: VxColors.neonCyan)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),

          // Strategy Grid
          Expanded(
            child: AnimatedBuilder(
              animation: _registry,
              builder: (context, child) {
                final allStrategies = _registry.allStrategies;
                final filtered = allStrategies.where((s) {
                  return s.name.toLowerCase().contains(_searchQuery) ||
                      s.tags.any((t) => t.toLowerCase().contains(_searchQuery));
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                      child: VxText.body("ZERO_MATCHES_IN_GRID",
                          color: Colors.white10));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(VxSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final meta = filtered[index];
                    return StrategyCard(
                      metadata: meta,
                      onTap: () {
                        AppLogger.info("Selected strategy: ${meta.name}");
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

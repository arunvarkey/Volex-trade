import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_strategy_tile.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';
import 'package:volex_terminal/ui/design_system/vx_status_badge.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';

enum SortOption { nameAsc, nameDesc, activeFirst }

class StrategyListView extends StatefulWidget {
  final String? selectedId;
  final Function(String) onSelect;

  const StrategyListView({super.key, this.selectedId, required this.onSelect});

  @override
  State<StrategyListView> createState() => _StrategyListViewState();
}

class _StrategyListViewState extends State<StrategyListView> {
  SortOption _currentSort = SortOption.nameAsc;

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<StrategyEngine>();
    // Create a modifiable copy for sorting
    final strategies = List<Strategy>.from(engine.allStrategies);

    // Apply Sorting
    switch (_currentSort) {
      case SortOption.nameAsc:
        strategies.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        strategies.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.activeFirst:
        strategies.sort((a, b) {
          if (a.isEnabled && !b.isEnabled) return -1;
          if (!a.isEnabled && b.isEnabled) return 1;
          return a.name.compareTo(b.name); // Fallback to name
        });
        break;
    }

    return Container(
      color: VxColors.background,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(VxSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VxText.subtitle("ALGORITHMS", color: Colors.white),
                PopupMenuButton<SortOption>(
                  icon: const Icon(Icons.sort, color: Colors.white54),
                  tooltip: "Sort Strategies",
                  onSelected: (val) => setState(() => _currentSort = val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: SortOption.nameAsc,
                      child: Text("Name (A-Z)"),
                    ),
                    const PopupMenuItem(
                      value: SortOption.nameDesc,
                      child: Text("Name (Z-A)"),
                    ),
                    const PopupMenuItem(
                      value: SortOption.activeFirst,
                      child: Text("Active First"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: strategies.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: VxSpacing.md),
                    itemCount: strategies.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: VxSpacing.sm),
                    itemBuilder: (context, index) {
                      final s = strategies[index];
                      final isSelected = s.id == widget.selectedId;

                      // Map Strategy State to UI
                      final bool isGhost = s.id == 'ghost_trend_v1';

                      return VxStrategyTile(
                        name: s.name,
                        status: s.isEnabled
                            ? VxBadgeStyle.success
                            : VxBadgeStyle.info,
                        statusLabel: s.isEnabled ? "ACTIVE" : "IDLE",
                        metrics: {
                          "Ref": isGhost ? "GENETIC" : "STABLE",
                          "Score": isGhost
                              ? "94"
                              : "88", // Hardcoded for now till we have real score engine
                        },
                        isSelected: isSelected,
                        onTap: () => widget.onSelect(s.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: VxText.body("No strategies registered", color: Colors.white24),
    );
  }
}

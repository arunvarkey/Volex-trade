import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_toolbar.dart';
import 'package:volex_terminal/ui/screens/strategies/tabs/overview_tab.dart';
import 'tabs/parameters_tab.dart';
import 'tabs/activity_tab.dart';

class StrategyDetailView extends StatelessWidget {
  final String strategyId;
  final bool isBackEnabled;

  const StrategyDetailView(
      {super.key, required this.strategyId, this.isBackEnabled = false});

  @override
  Widget build(BuildContext context) {
    final executionManager = context.watch<ExecutionManager>();
    final engine = context.watch<StrategyEngine>();
    final strategy = engine.allStrategies.firstWhere((s) => s.id == strategyId,
        orElse: () => engine.allStrategies.first);
    final isRunning = executionManager.isStrategyRunning(strategy.id);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: VxColors.background,
        appBar: isBackEnabled
            ? VxToolbar(
                title: VxText.subtitle("STRATEGY: ${strategy.name}",
                    overflow: TextOverflow.ellipsis),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  _buildControlButtons(context, executionManager, isRunning),
                ],
              )
            : AppBar(
                // Minimal header for desktop split view
                backgroundColor: VxColors.surface,
                elevation: 0,
                title: VxText.subtitle("STRATEGY: $strategyId",
                    overflow: TextOverflow.ellipsis),
                automaticallyImplyLeading: false,
                actions: [
                  _buildControlButtons(context, executionManager, isRunning),
                ],
              ),
        body: Column(
          children: [
            // Validation Banner
            if (strategy.validationStatus == ValidationStatus.failed)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: VxColors.neonRed.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: VxColors.neonRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VxText.body(strategy.validationMessage,
                          color: VxColors.neonRed),
                    ),
                  ],
                ),
              ),

            if (strategy.validationStatus == ValidationStatus.experimental)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: VxColors.neonCyan.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.science, color: VxColors.neonCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VxText.body(strategy.validationMessage,
                          color: VxColors.neonCyan),
                    ),
                  ],
                ),
              ),

            // Tab Bar
            Container(
              color: VxColors.surface,
              child: const TabBar(
                indicatorColor: VxColors.neonCyan,
                labelColor: VxColors.neonCyan,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: "OVERVIEW"),
                  Tab(text: "PARAMETERS"),
                  Tab(text: "ACTIVITY"),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  OverviewTab(strategyId: strategy.id),
                  ParametersTab(strategyId: strategy.id),
                  const ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(
      BuildContext context, ExecutionManager manager, bool isRunning) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: isRunning ? "Strategy running" : "Start strategy",
          icon: isRunning
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VxColors.neonGreen))
              : const Icon(Icons.play_arrow, color: VxColors.neonGreen),
          onPressed: isRunning
              ? null
              : () async {
                  await manager.startStrategy(strategyId);
                  if (!context.mounted) return;
                  _notify(context, 'Strategy activated — paper trading');
                },
        ),
        IconButton(
          tooltip: "Stop strategy",
          icon: Icon(Icons.stop,
              color: isRunning ? VxColors.neonRed : Colors.white12),
          onPressed: isRunning
              ? () async {
                  await manager.stopStrategy(strategyId);
                  if (!context.mounted) return;
                  _notify(context, 'Strategy stopped');
                }
              : null,
        ),
      ],
    );
  }

  void _notify(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: VxColors.surfaceBright,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

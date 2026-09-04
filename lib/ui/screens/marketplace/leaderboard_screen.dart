import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_ui_widgets.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No ranking is shown until there are real, verified results to rank.
    // This screen used to list invented strategies with invented returns
    // (e.g. "+312.5%") as though they were genuine top performers — exactly
    // the kind of inflated number that destroys trust in a learning tool.
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: VxToolbar(
        title: VxText.heading3('Top Strategies'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.leaderboard_outlined,
                  size: 44, color: VxColors.textTertiary),
              const SizedBox(height: 16),
              VxText.subtitle('No ranked strategies yet'),
              const SizedBox(height: 8),
              VxText.body(
                'The leaderboard ranks strategies on verified backtest and '
                'paper-trading results. It stays empty until there are real '
                'results to rank — we will not show invented performance '
                'numbers here.',
                color: VxColors.textSecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

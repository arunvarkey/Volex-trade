import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_ui_widgets.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Leaderboard Data
    final topList = [
      _LeaderboardEntry(1, 'Golden Cross Alpha', 312.5, 2.4, 0.58),
      _LeaderboardEntry(2, 'Volex AI Scalper', 88.2, 1.8, 0.45),
      _LeaderboardEntry(3, 'Safe Harbor Yield', 12.4, 4.1, 0.98),
      _LeaderboardEntry(4, 'Quantum Momentum', 11.1, 1.2, 0.52),
      _LeaderboardEntry(5, 'Swing Kings', -2.3, 0.8, 0.40),
    ];

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: VxToolbar(
        title: VxText.heading3('Top Strategies'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: topList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = topList[index];
          return _buildLeaderboardItem(context, entry);
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, _LeaderboardEntry entry) {
    final isPositive = entry.returnPct >= 0;
    return VxCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            VxText.heading3(
              '#${entry.rank}',
              color: entry.rank <= 3 ? VxColors.accent : VxColors.neutral500,
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VxText.body(entry.name),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMetric('Sharpe', entry.sharpe.toStringAsFixed(1)),
                      const SizedBox(width: 12),
                      _buildMetric(
                          'Win Rate', '${(entry.winRate * 100).toInt()}%'),
                    ],
                  ),
                ],
              ),
            ),
            // Return
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VxText.heading3(
                  '${isPositive ? "+" : ""}${entry.returnPct}%',
                  color: isPositive ? VxColors.positive : VxColors.negative,
                ),
                VxText.caption('Total Return'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Row(
      children: [
        VxText.caption('$label: ', color: VxColors.neutral500),
        VxText.caption(value, color: VxColors.neutral200),
      ],
    );
  }
}

class _LeaderboardEntry {
  final int rank;
  final String name;
  final double returnPct;
  final double sharpe;
  final double winRate;

  _LeaderboardEntry(
      this.rank, this.name, this.returnPct, this.sharpe, this.winRate);
}

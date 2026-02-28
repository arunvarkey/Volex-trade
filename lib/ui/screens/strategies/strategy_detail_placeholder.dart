import 'package:flutter/material.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_typography.dart';
import '../../design_system/vx_card.dart';

class StrategyDetailPlaceholder extends StatelessWidget {
  const StrategyDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: VxText.subtitle("Strategy Details", color: Colors.white),
        backgroundColor: VxColors.surface,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: VxCard(
          title: VxText.title("Select a Strategy"),
          description: "Details will appear here.",
          child: const SizedBox(height: 100),
        ),
      ),
    );
  }
}

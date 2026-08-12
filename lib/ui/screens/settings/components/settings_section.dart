import 'package:flutter/material.dart';
import '../../../design_system/vx_card.dart';
import '../../../design_system/vx_typography.dart';
import '../../../design_system/vx_colors.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const SettingsSection(
      {super.key, required this.title, this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return VxCard(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: VxColors.neonCyan),
            const SizedBox(width: 8)
          ],
          VxText.subtitle(title, color: Colors.white),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

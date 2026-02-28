import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_typography.dart';
import '../../design_system/vx_spacing.dart';
import 'package:volex_terminal/ui/screens/strategies/optimizer_screen.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: "Strategies",
            icon: Icons.play_arrow,
            color: VxColors.neonGreen,
            onTap: () => context.go('/strategies'),
          ),
        ),
        const SizedBox(width: VxSpacing.md),
        Expanded(
          child: _ActionButton(
            label: "Stop All",
            icon: Icons.stop,
            color: VxColors.neonRed,
            onTap: () {
              context.read<ExecutionManager>().stopAllStrategy();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("STOP SIGNAL SENT TO ALL STRATEGIES")),
              );
            },
          ),
        ),
        const SizedBox(width: VxSpacing.md),
        Expanded(
          child: _ActionButton(
            label: "Optimizer",
            icon: Icons.biotech,
            color: VxColors.neonMagenta,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OptimizerScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: VxSpacing.md),
        Expanded(
          child: _ActionButton(
            label: "Scanner",
            icon: Icons.radar,
            color: VxColors.neonCyan,
            onTap: () => context.pushNamed('scanner'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              VxText.micro(label, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

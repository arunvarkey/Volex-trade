import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';

/// Simulation disclaimer badge for all trading screens
/// Required for compliance - shows this is educational only
class SimulationBadge extends StatelessWidget {
  const SimulationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VxColors.neonGreen.withOpacity(0.15),
        border: Border.all(color: VxColors.neonGreen.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: VxColors.neonGreen,
            size: 14,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              '⚠️ EDUCATIONAL SIMULATION - No real money at risk',
              style: TextStyle(
                color: VxColors.neonGreen,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

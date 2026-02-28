import 'package:flutter/material.dart';
import '../design_system/vx_colors.dart';
import '../../services/user_mode_service.dart';

class ModeIndicatorBanner extends StatelessWidget {
  final UserMode mode;

  const ModeIndicatorBanner({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == UserMode.pro) {
      return const SizedBox.shrink(); // Invisible in Pro Mode
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        color: VxColors.warning,
        border: Border(
          bottom: BorderSide(
            color: VxColors.warning,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            color: VxColors.deepBlack,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'EXPLORER MODE - SIMULATED TRADING',
            style: TextStyle(
              color: VxColors.deepBlack,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

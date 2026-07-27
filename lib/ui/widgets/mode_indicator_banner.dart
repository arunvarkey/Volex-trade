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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: VxColors.warning.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: VxColors.warning.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: VxColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Paper trading · simulated funds',
            style: TextStyle(
              color: VxColors.warning.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../ui/design_system/vx_colors.dart';
import '../../../../ui/design_system/vx_typography.dart';

class RiskBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onAcknowledge;

  const RiskBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: VxColors.neonRed.withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: Colors.white24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VxText.heading3(title, color: Colors.white),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onAcknowledge,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Acknowledge Risk',
            ),
          ],
        ),
      ),
    );
  }
}

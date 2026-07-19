// lib/ui/widgets/mode_indicator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/core/config/app_mode_service.dart';
import 'package:volex_terminal/core/config/app_mode.dart';

class ModeIndicator extends StatelessWidget {
  const ModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final appMode = context.watch<AppModeService>();
    final mode = appMode.currentMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: mode.themeColor.withValues(alpha: 0.2),
        border: Border.all(color: mode.themeColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: mode.themeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            mode.displayName.toUpperCase(),
            style: TextStyle(
              color: mode.themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

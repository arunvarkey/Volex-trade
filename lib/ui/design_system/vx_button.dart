import 'package:flutter/material.dart';
import 'vx_colors.dart';

class VxButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isOutline;

  const VxButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isOutline = false,
  });

  factory VxButton.primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return VxButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: VxColors.neonCyan,
      foregroundColor: Colors.black,
    );
  }

  factory VxButton.outline({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return VxButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: Colors.transparent,
      foregroundColor: VxColors.neonCyan,
      isOutline: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: isOutline ? 0 : 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isOutline
              ? BorderSide(color: foregroundColor, width: 1.5)
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

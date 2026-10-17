import 'package:flutter/material.dart';
import 'vx_colors.dart';
import 'vx_eyebrow.dart';

enum VxBadgeStyle {
  success,
  warning,
  danger,
  info,
  neutral,
}

class VxStatusBadge extends StatelessWidget {
  final String label;
  final VxBadgeStyle style;
  final bool outline;

  const VxStatusBadge({
    super.key,
    required this.label,
    this.style = VxBadgeStyle.neutral,
    this.outline = false,
  });

  Color get _color {
    switch (style) {
      case VxBadgeStyle.success:
        return VxColors.success;
      case VxBadgeStyle.warning:
        return VxColors.warning;
      case VxBadgeStyle.danger:
        return VxColors.danger;
      case VxBadgeStyle.info:
        return VxColors.info;
      case VxBadgeStyle.neutral:
        return VxColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : color.withValues(alpha: 0.15),
        borderRadius:
            BorderRadius.circular(4), // Slightly rounded rect like a code tag
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      // A badge is the textbook case for capitals: one or two words the
      // user scans rather than reads. VxEyebrow sets them, and hands the
      // screen reader the words instead of the letters.
      child: VxEyebrow(label, color: color, fontSize: 10),
    );
  }
}

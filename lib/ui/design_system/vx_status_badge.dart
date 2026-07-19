import 'package:flutter/material.dart';
import 'vx_colors.dart';
import 'vx_typography.dart';

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
      child: VxText.micro(
        label.toUpperCase(),
        color: color,
        // using micro style but maybe we want a bespoke badge style
      ),
    );
  }
}

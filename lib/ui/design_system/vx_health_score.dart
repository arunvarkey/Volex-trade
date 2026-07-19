import 'package:flutter/material.dart';
import 'vx_colors.dart';
import 'vx_typography.dart';

class VxHealthScore extends StatelessWidget {
  final double score; // 0.0 to 100.0
  final double size;

  const VxHealthScore({super.key, required this.score, this.size = 40});

  Color get _color {
    if (score >= 80) return VxColors.success;
    if (score >= 50) return VxColors.warning;
    return VxColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 2),
        color: _color.withValues(alpha: 0.1),
      ),
      child: Center(
        child: VxText.monoBold(
          score.toInt().toString(),
          color: _color,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

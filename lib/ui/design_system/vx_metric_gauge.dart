import 'package:flutter/material.dart';
import 'vx_colors.dart';
import 'vx_typography.dart';
import 'vx_spacing.dart';

class VxMetricGauge extends StatelessWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final String displayValue;
  final Color? color;
  final bool animate;

  const VxMetricGauge({
    super.key,
    required this.label,
    required this.value,
    required this.displayValue,
    this.color,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? VxColors.neonCyan;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Center(
                child: VxText.monoBold(
                  displayValue,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VxSpacing.sm),
        VxText.micro(label.toUpperCase(), color: VxColors.textSecondary),
      ],
    );
  }
}

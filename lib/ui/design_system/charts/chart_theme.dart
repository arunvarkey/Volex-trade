import 'package:flutter/material.dart';
import '../vx_colors.dart';

class ChartTheme {
  // Singleton Default
  static const ChartTheme cyberpunk = ChartTheme(
    gridColor: Colors.white10,
    axisLabelColor: Colors.white54,
    lineColor: VxColors.neonCyan,
    candleUpColor: VxColors.neonGreen,
    candleDownColor: VxColors.neonRed,
    gradientColors: [
      Color(0x3300FFFF), // Cyan with opacity
      Color(0x0000FFFF), // Cyan transparent
    ],
    crosshairColor: Colors.white,
    backgroundColor: Colors.black,
    strokeWidth: 2.0,
    candleWidth: 8.0,
  );

  final Color gridColor;
  final Color axisLabelColor;
  final Color lineColor;
  final Color candleUpColor;
  final Color candleDownColor;
  final List<Color> gradientColors;
  final Color crosshairColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double candleWidth;

  const ChartTheme({
    required this.gridColor,
    required this.axisLabelColor,
    required this.lineColor,
    required this.candleUpColor,
    required this.candleDownColor,
    required this.gradientColors,
    required this.crosshairColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.candleWidth,
  });
}

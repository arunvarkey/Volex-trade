import 'package:flutter/material.dart';
import '../design_system/vx_colors.dart';

class TerminalTimeframeBar extends StatelessWidget {
  final String currentTimeframe;
  final Function(String) onTimeframeSelected;

  const TerminalTimeframeBar({
    super.key,
    required this.currentTimeframe,
    required this.onTimeframeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final timeframes = ['1m', '5m', '15m', '1h', '4h', '1d'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: VxColors.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: timeframes.map((tf) {
          final isSelected = tf == currentTimeframe;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => onTimeframeSelected(tf),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? VxColors.neonCyan.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? Border.all(color: VxColors.neonCyan.withOpacity(0.5))
                      : null,
                ),
                child: Text(
                  tf.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? VxColors.neonCyan : Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

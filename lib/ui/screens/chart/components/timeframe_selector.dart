import 'package:flutter/material.dart';
import '../../../design_system/vx_colors.dart';
import '../../../design_system/vx_typography.dart';
import '../../../widgets/vx_holographic_card.dart';

class TimeframeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const TimeframeSelector(
      {super.key, required this.selected, required this.onSelected});

  final List<String> timeframes = const [
    '1m',
    '5m',
    '15m',
    '1h',
    '4h',
    '1d',
    '1w'
  ];

  @override
  Widget build(BuildContext context) {
    return VxHolographicCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      borderRadius: 0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: timeframes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tf = timeframes[index];
          final isSelected = tf == selected;
          return GestureDetector(
            onTap: () => onSelected(tf),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? VxColors.neonCyan.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? VxColors.neonCyan.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  tf.toUpperCase(),
                  style: VxTypography.caption.copyWith(
                    color: isSelected ? VxColors.neonCyan : Colors.white38,
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.normal,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

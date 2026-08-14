import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// A quiet, one-line compliance note for anywhere trades or signals appear.
///
/// Volex is a simulator, not a broker or an advisor — this keeps that explicit
/// and consistent (no financial-advice ambiguity) without shouting.
class VxDisclaimer extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const VxDisclaimer({
    super.key,
    this.text = 'Educational simulation — not financial advice.',
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 13, color: VxColors.textTertiary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: VxTypography.caption.copyWith(
                color: VxColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

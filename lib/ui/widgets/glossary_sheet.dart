import 'package:flutter/material.dart';

import 'package:volex_terminal/core/glossary.dart';
import 'package:volex_terminal/services/haptic_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// A bottom sheet that explains one trading term — child-simple first, then
/// the engineer detail. Opened from any [InfoLabel] or by calling [show].
class GlossarySheet {
  const GlossarySheet._();

  static void show(BuildContext context, String termId) {
    final entry = Glossary.of(termId);
    if (entry == null) return;
    HapticService.instance.light();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: VxColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: VxColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(entry.term,
                          style: VxTypography.h2
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _label('IN PLAIN TERMS'),
                const SizedBox(height: 6),
                Text(
                  entry.simple,
                  style: VxTypography.bodyLarge.copyWith(height: 1.4),
                ),
                const SizedBox(height: 20),
                _label('THE DETAIL'),
                const SizedBox(height: 6),
                Text(
                  entry.detail,
                  style: VxTypography.bodySmall.copyWith(
                    color: VxColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VxColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _label(String text) => Text(
        text,
        style: VxTypography.caption.copyWith(
          color: VxColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      );
}

/// A label that carries a small "?" and opens the glossary for [termId].
///
/// Drop it in anywhere a jargon label appears (metric titles, indicator
/// names). It's opt-in — nothing happens until the user taps it, so it never
/// gets in the way.
class InfoLabel extends StatelessWidget {
  final String text;
  final String termId;
  final TextStyle? style;

  const InfoLabel({
    super.key,
    required this.text,
    required this.termId,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final resolved =
        style ?? VxTypography.caption.copyWith(color: VxColors.textSecondary);
    final iconColor = resolved.color ?? VxColors.textSecondary;
    return GestureDetector(
      onTap: () => GlossarySheet.show(context, termId),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: resolved),
          const SizedBox(width: 3),
          Icon(Icons.help_outline_rounded,
              size: (resolved.fontSize ?? 12) + 2,
              color: iconColor.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

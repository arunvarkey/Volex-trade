import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';

class VxToolbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showProToggle;
  final PreferredSizeWidget? bottom;

  const VxToolbar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showProToggle = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final toolbar = Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: VxSpacing.md,
        right: VxSpacing.md,
      ),
      decoration: BoxDecoration(
        color: VxColors.background.withValues(alpha: 0.8), // Slightly opaque
        border:
            Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: VxSpacing.md),
          ],
          Expanded(
              child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white), child: title)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );

    if (bottom != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          toolbar,
          bottom!,
        ],
      );
    }
    return toolbar;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

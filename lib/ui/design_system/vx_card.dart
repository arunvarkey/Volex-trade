import 'package:flutter/material.dart';
import 'dart:ui';
import 'vx_colors.dart';
import 'vx_spacing.dart';
import 'vx_typography.dart';

class VxCard extends StatefulWidget {
  final Widget child;
  final Widget? title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final String? description;
  final bool animateOnHover;

  const VxCard({
    super.key,
    required this.child,
    this.title,
    this.description,
    this.action,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.animateOnHover = false,
  });

  @override
  State<VxCard> createState() => _VxCardState();
}

class _VxCardState extends State<VxCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool canAnimate = widget.animateOnHover || widget.onTap != null;

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            VxColors.surface.withOpacity(_isHovered ? 0.8 : 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isHovered
              ? VxColors.neonCyan.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isHovered
                ? VxColors.neonCyan.withOpacity(0.1)
                : Colors.black.withOpacity(0.2),
            blurRadius: _isHovered ? 24 : 16,
            offset: Offset(0, _isHovered ? 12 : 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding:
                widget.padding ?? const EdgeInsets.all(VxSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null || widget.action != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.title != null) Expanded(child: widget.title!),
                      if (widget.action != null) widget.action!,
                    ],
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 4),
                    VxText.caption(widget.description ?? '',
                        color: Colors.white38),
                  ],
                  const SizedBox(height: VxSpacing.md),
                ],
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );

    Widget result = cardContent;

    if (canAnimate) {
      result = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: result,
        ),
      );
    }

    if (widget.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: VxColors.neonCyan.withOpacity(0.1),
          highlightColor: VxColors.neonCyan.withOpacity(0.05),
          child: result,
        ),
      );
    }

    return result;
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../design_system/vx_colors.dart';

/// A premium, volumetric glass card for the Holographic Command aesthetic.
class VxHolographicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? borderColor;
  final bool hasGlow;

  const VxHolographicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.borderColor,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: VxColors.glassSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? VxColors.holographicBorder,
              width: 1.2,
            ),
            boxShadow: hasGlow
                ? [
                    BoxShadow(
                      color: VxColors.primaryGlow,
                      blurRadius: 20,
                      spreadRadius: -5,
                    )
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Subtle Top Highlight (Volumetric effect)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

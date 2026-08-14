import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HapticIntensity { light, medium, heavy }

class HapticScaleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final HapticIntensity intensity;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const HapticScaleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.intensity = HapticIntensity.light,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  });

  @override
  State<HapticScaleButton> createState() => _HapticScaleButtonState();
}

class _HapticScaleButtonState extends State<HapticScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    _controller.forward();
    _playHaptic();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    _controller.reverse();
  }

  void _playHaptic() {
    switch (widget.intensity) {
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case HapticIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: widget.onPressed == null
                    ? Colors.grey.withValues(alpha: 0.3)
                    : widget.backgroundColor ?? Theme.of(context).primaryColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  color:
                      Colors.black, // Default contrast text for primary buttons
                ),
                child: Center(child: widget.child),
              ),
            ),
          );
        },
      ),
    );
  }
}

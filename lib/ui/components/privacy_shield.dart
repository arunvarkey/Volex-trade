import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_icons.dart';

/// Wraps the application to provide automatic visual obfuscation
/// when the app goes into the background (Multitasking view).
/// This prevents sensitive data from being seen in the OS app switcher.
class PrivacyShield extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PrivacyShield({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<PrivacyShield>
    with WidgetsBindingObserver {
  bool _shouldBlur = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;

    setState(() {
      // Blur on inactive (iOS Control Center/Notification Shade) or paused (Background)
      _shouldBlur = state != AppLifecycleState.resumed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Privacy Overlay
        if (_shouldBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: VxColors.background.withOpacity(0.8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        VxIcons
                            .shieldOk, // Assumes VxIcons has this, or use Icons.security
                        size: 64,
                        color: VxColors.neonCyan,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'VOLEX SECURE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          decoration: TextDecoration
                              .none, // Since we might be above MaterialApp
                          fontFamily: 'Roboto', // Default fallback
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

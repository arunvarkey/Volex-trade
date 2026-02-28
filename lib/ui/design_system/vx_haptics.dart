import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Premium Haptic Feedback utility for Volex Terminal.
/// Provides tactical responses for different UI interactions.
class VxHaptics {
  /// Light impact for standard interactions (taps, toggles)
  static Future<void> light() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact for significant actions (confirmations, success)
  static Future<void> medium() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact for serious events (errors, alerts)
  static Future<void> heavy() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }

  /// Success feedback pattern
  static Future<void> success() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Error feedback pattern
  static Future<void> error() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }

  /// Warning feedback pattern
  static Future<void> warning() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }
}

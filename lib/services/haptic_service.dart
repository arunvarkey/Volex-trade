import 'package:flutter/services.dart';
import 'package:volex_terminal/core/app_logger.dart';

/// Centralized service for multisensory feedback.
///
/// High-fidelity haptics distinguish between soft UI interactions
/// and heavy execution events.
class HapticService {
  static final HapticService _instance = HapticService._();
  static HapticService get instance => _instance;

  HapticService._();

  /// Light tap for basic UI interactions (Tabs, Buttons)
  Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium feedback for parameter adjustments (Sliders, Toggles)
  Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy feedback for disruptive or high-value actions (Deleting, Deploying)
  Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Distinctive sequence for a successful trade execution
  Future<void> successPulse() async {
    AppLogger.debug('Haptics: Success Pulse');
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Distinctive sequence for an alert or warning
  Future<void> warning() async {
    AppLogger.debug('Haptics: Warning');
    await HapticFeedback.vibrate();
  }

  /// Confirm a selection or state change
  Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}

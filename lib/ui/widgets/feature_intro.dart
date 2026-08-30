import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// A short plain-English answer to "what is this screen, and when would I use
/// it?", shown at the top of a feature until the user dismisses it.
///
/// Volex has a lot of tools whose names only mean something if you already
/// know the thing they are named after — Optimizer, Scanner, Backtest Lab,
/// Script Editor. Someone arriving at one of those screens for the first time
/// met a title, a set of controls, and no explanation of what any of it was
/// for. A glossary helps with individual words, but it cannot tell you why a
/// whole screen exists.
///
/// The card is deliberately quiet: it is not a modal, nothing is blocked
/// behind it, and dismissing it is permanent per feature. Every screen that
/// uses one also keeps an "i" button in its app bar, so the explanation can
/// always be brought back — a beginner who dismissed it too early should not
/// have to reinstall the app to read it again.
class FeatureIntro extends StatefulWidget {
  /// Stable id for the feature; used as the dismissal key.
  final String featureId;

  /// What this screen is, in one sentence a beginner can follow.
  final String what;

  /// When someone would actually use it.
  final String when;

  /// The honest caveat, where there is one worth stating up front.
  final String? caution;

  final IconData icon;

  const FeatureIntro({
    super.key,
    required this.featureId,
    required this.what,
    required this.when,
    this.caution,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  /// Opens the same explanation as a sheet, for the app-bar "i" button.
  static void show(
    BuildContext context, {
    required String title,
    required String what,
    required String when,
    String? caution,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: VxColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
              Text(title,
                  style: VxTypography.h2.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              _heading('WHAT THIS IS'),
              const SizedBox(height: 6),
              Text(what, style: VxTypography.bodyLarge.copyWith(height: 1.4)),
              const SizedBox(height: 20),
              _heading('WHEN TO USE IT'),
              const SizedBox(height: 6),
              Text(
                when,
                style: VxTypography.bodySmall.copyWith(
                  color: VxColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (caution != null) ...[
                const SizedBox(height: 20),
                _heading('WORTH KNOWING'),
                const SizedBox(height: 6),
                Text(
                  caution,
                  style: VxTypography.bodySmall.copyWith(
                    color: VxColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
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
      ),
    );
  }

  static Widget _heading(String text) => Text(
        text,
        style: VxTypography.caption.copyWith(
          color: VxColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      );

  @override
  State<FeatureIntro> createState() => _FeatureIntroState();
}

class _FeatureIntroState extends State<FeatureIntro> {
  static const String _prefix = 'feature_intro_dismissed_';

  // Starts hidden and appears once we know it has not been dismissed, so a
  // returning user never sees it flash in and out on every visit.
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool('$_prefix${widget.featureId}') ?? false;
      if (mounted && !dismissed) setState(() => _visible = true);
    } catch (_) {
      // Preferences are unavailable in some test and first-run contexts.
      // An explainer is not worth failing a screen over; just stay hidden.
    }
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix${widget.featureId}', true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: VxColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VxColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 20, color: VxColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.what,
                  style: VxTypography.bodySmall.copyWith(
                    color: VxColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.when,
                  style: VxTypography.caption.copyWith(
                    color: VxColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (widget.caution != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.caution!,
                    style: VxTypography.caption.copyWith(
                      color: VxColors.neonYellow.withValues(alpha: 0.85),
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _dismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: VxColors.textTertiary,
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

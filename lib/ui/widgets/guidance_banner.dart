import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// A quiet, in-context "what to do here + why" hint.
///
/// Design contract — guide, never nag:
///  - one short line, subtle styling (no modal, never blocks the UI)
///  - a dismiss (x); once dismissed it never shows again (persisted per [id])
///  - renders nothing until we know it hasn't been dismissed (no fl‑then‑hide flicker)
///
/// Give every placement a unique, stable [id] (e.g. 'learn_intro').
///
/// For a screen whose *purpose* needs explaining rather than its controls —
/// where one line cannot do it, and the reader will want the explanation back
/// later — use FeatureIntro instead. It carries a what/when/caution structure
/// and stays reachable from an app-bar button after dismissal.
class GuidanceBanner extends StatefulWidget {
  final String id;
  final String text;
  final IconData icon;

  const GuidanceBanner({
    super.key,
    required this.id,
    required this.text,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  @override
  State<GuidanceBanner> createState() => _GuidanceBannerState();
}

class _GuidanceBannerState extends State<GuidanceBanner> {
  static const _prefix = 'guidance_dismissed_';
  bool _loaded = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool('$_prefix${widget.id}') ?? false;
      if (mounted) {
        setState(() {
          _dismissed = dismissed;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix${widget.id}', true);
    } catch (_) {
      // Non-fatal: worst case the hint reappears next launch.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: VxColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 18, color: VxColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.text,
              style: VxTypography.bodySmall.copyWith(
                color: VxColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _dismiss,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 16, color: VxColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

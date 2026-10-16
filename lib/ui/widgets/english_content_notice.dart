import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/core/localisation_coverage.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// Tells a non-English user that the lessons are in English, before they
/// find out by opening one.
///
/// Renders nothing at all for English, and nothing once dismissed, so it
/// costs the default case nothing.
///
/// The alternative designs were both worse. Dropping Spanish and Hindi from
/// `supportedLocales` would make the app honest by making it smaller, and
/// the translated navigation is genuinely useful. Saying nothing leaves the
/// user to discover it on lesson one, which is the moment they decide
/// whether this app was built for them.
class EnglishContentNotice extends StatefulWidget {
  const EnglishContentNotice({super.key});

  @override
  State<EnglishContentNotice> createState() => _EnglishContentNoticeState();
}

class _EnglishContentNoticeState extends State<EnglishContentNotice> {
  static const String _prefsKey = 'english_content_notice_dismissed_v1';

  bool _loading = true;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var dismissed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      dismissed = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      // Showing it twice is a far smaller failure than hiding it.
    }
    if (mounted) {
      setState(() {
        _dismissed = dismissed;
        _loading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (_) {
      // Non-fatal.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dismissed) return const SizedBox.shrink();

    final language = Localizations.localeOf(context).languageCode;
    if (!LocalisationCoverage.needsEnglishContentNotice(language)) {
      return const SizedBox.shrink();
    }

    final items = LocalisationCoverage.englishOnlyContentItems;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.translate_rounded,
              size: 18, color: VxColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The lessons are in English',
                  style: VxTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: VxColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Menus and navigation are translated, but all $items '
                  'lessons, questions and definitions are written in English '
                  'for now. We would rather say so than machine-translate an '
                  'explanation of risk and get it subtly wrong.',
                  style: VxTypography.caption.copyWith(
                    color: VxColors.textSecondary,
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded,
                size: 16, color: VxColors.textTertiary),
            onPressed: _dismiss,
          ),
        ],
      ),
    );
  }
}

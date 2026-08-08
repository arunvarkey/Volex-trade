import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/l10n/app_localizations.dart';

/// Verifies the gen-l10n wiring: every supported locale loads and key strings
/// resolve to non-empty values (catches a missing translation or a broken
/// delegate before it ships).
void main() {
  testWidgets('all supported locales load and resolve key strings',
      (tester) async {
    // We ship at least English, Spanish and Hindi.
    expect(AppLocalizations.supportedLocales.length, greaterThanOrEqualTo(3));

    for (final locale in AppLocalizations.supportedLocales) {
      late AppLocalizations l10n;
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox.shrink();
        }),
      ));
      await tester.pump();

      expect(l10n.navHome, isNotEmpty, reason: '$locale navHome');
      expect(l10n.signalsTitle, isNotEmpty, reason: '$locale signalsTitle');
      expect(l10n.marketsTitle, isNotEmpty, reason: '$locale marketsTitle');
      expect(l10n.disclaimerEducational, isNotEmpty,
          reason: '$locale disclaimerEducational');
    }
  });
}

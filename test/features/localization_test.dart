import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/l10n/app_localizations.dart';

/// Verifies the gen-l10n wiring: the locale loads and key strings resolve to
/// non-empty values, catching a missing key or a broken delegate.
///
/// The app ships English only, deliberately. It briefly declared Spanish and
/// Hindi with 28 strings translated against 436 English lessons, questions
/// and definitions — a Hindi navigation bar around an English app, which
/// brings in installs on a promise the app does not keep.
///
/// The ARB machinery is kept rather than unwound. The strings are already
/// extracted, it keeps every piece of user-facing copy in one file where it
/// can be read and edited as a whole, and adding a language later becomes
/// translation work rather than another extraction pass.
void main() {
  testWidgets('the supported locale loads and resolves key strings',
      (tester) async {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        ['en'],
        reason: 'adding a locale here without translating the content is the '
            'mistake this app already made once');

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

      // The screens extracted most recently, including a placeholder form —
      // a broken placeholder signature fails to compile, but an empty value
      // would only show up here.
      expect(l10n.menuTitle, isNotEmpty, reason: '$locale menuTitle');
      expect(l10n.homeQuickTrade, isNotEmpty, reason: '$locale homeQuickTrade');
      expect(l10n.academyProgress(3, 21), contains('21'),
          reason: '$locale academyProgress should interpolate its arguments');
      expect(l10n.dailyIntro(5), contains('5'),
          reason: '$locale dailyIntro should interpolate its argument');
    }
  });
}

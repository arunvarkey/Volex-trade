import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/core/localisation_coverage.dart';
import 'package:volex_terminal/l10n/app_localizations.dart';
import 'package:volex_terminal/ui/widgets/english_content_notice.dart';

/// Guards the claim the app makes about what language it is in.
///
/// The app declares Spanish and Hindi. Twenty-eight strings are genuinely
/// translated; every lesson, question and definition is English. That gap is
/// fine as long as the user is told — and catastrophic as a silent promise,
/// because the install happens on it and the uninstall takes a rating.
///
/// These tests exist so the telling cannot be quietly removed, and so the
/// coverage record cannot drift away from what is actually shipped.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the coverage record', () {
    test('matches the locales the app actually declares', () {
      final declared = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toSet();

      expect(LocalisationCoverage.translatedInterfaceLocales, declared,
          reason: 'the record and supportedLocales have drifted apart — one '
              'of them is now lying to somebody');
    });

    test('counts content from the content, not from a number in a comment',
        () {
      // Written down, this figure would be wrong within a month. The point
      // of computing it is that adding a lesson cannot silently shrink the
      // claim.
      expect(LocalisationCoverage.englishOnlyContentItems, greaterThan(300),
          reason: 'the Daily bank alone is 300+; a smaller total means the '
              'count stopped seeing some of the content');
    });

    test('is honest that only English has content', () {
      expect(LocalisationCoverage.contentLocales, {'en'});
      expect(LocalisationCoverage.needsEnglishContentNotice('hi'), isTrue);
      expect(LocalisationCoverage.needsEnglishContentNotice('es'), isTrue);
      expect(LocalisationCoverage.needsEnglishContentNotice('en'), isFalse,
          reason: 'an English speaker should never see a notice about '
              'English content');
    });
  });

  group('the notice', () {
    Future<void> pump(WidgetTester tester, Locale locale) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: EnglishContentNotice()),
      ));
      await tester.pumpAndSettle();
    }

    // The widget deliberately says "English" twice — once in the heading and
    // once in the body — so matching on the word alone would be ambiguous.
    final heading = find.text('The lessons are in English');

    testWidgets('appears for Hindi', (tester) async {
      await pump(tester, const Locale('hi'));
      expect(heading, findsOneWidget);
    });

    testWidgets('appears for Spanish', (tester) async {
      await pump(tester, const Locale('es'));
      expect(heading, findsOneWidget);
    });

    testWidgets('stays out of the way in English', (tester) async {
      await pump(tester, const Locale('en'));
      expect(heading, findsNothing,
          reason: 'it costs the default case nothing');
    });

    testWidgets('names how much content is affected', (tester) async {
      await pump(tester, const Locale('hi'));
      final count = LocalisationCoverage.englishOnlyContentItems;
      expect(find.textContaining('$count'), findsOneWidget,
          reason: 'a number is checkable; "some content" is not');
    });

    testWidgets('can be dismissed and stays dismissed', (tester) async {
      await pump(tester, const Locale('hi'));
      expect(heading, findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(heading, findsNothing);

      // A fresh key forces a new State, so this reads the preference back
      // rather than reusing the instance that just set it — otherwise the
      // test would pass without persistence working at all.
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('hi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: EnglishContentNotice(key: UniqueKey())),
      ));
      await tester.pumpAndSettle();
      expect(heading, findsNothing,
          reason: 'a notice that returns every launch is nagging, not '
              'informing');
    });
  });
}

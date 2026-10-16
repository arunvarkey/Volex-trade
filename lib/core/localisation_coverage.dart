import 'package:volex_terminal/core/glossary.dart';
import 'package:volex_terminal/features/academy/data/academy_curriculum.dart';
import 'package:volex_terminal/features/academy/data/academy_quizzes.dart';
import 'package:volex_terminal/features/daily/data/daily_question_bank.dart';

/// What is actually translated, stated so it cannot quietly become a lie.
///
/// ## The problem this exists to stop
///
/// The app declares Spanish and Hindi in `supportedLocales`, and 28 strings
/// are genuinely translated into both. Everything else — every screen label,
/// and all of the teaching content — is hardcoded English. A Hindi speaker
/// who installs because the store says Hindi gets a Hindi navigation bar
/// wrapped around an English app.
///
/// That is the same defect this codebase has been removing everywhere else:
/// claiming something the code does not do. It is also worse than shipping
/// English only, because the install happened on a promise and the
/// uninstall takes a rating with it.
///
/// ## Why the content is not machine-translated
///
/// Translating the interface is a formatting problem. Translating the
/// Academy is not. These lessons explain stop placement, position sizing and
/// expectancy to people who are about to risk money on the strength of them,
/// and a mistranslated explanation of risk does not read as awkward — it
/// teaches the wrong thing, confidently, to someone with no way to check.
///
/// The correct fix is a native speaker who understands trading, reviewing
/// each lesson. Until that exists, the app says so rather than guessing, and
/// [EnglishContentNotice] tells the user up front instead of letting them
/// discover it three screens in.
class LocalisationCoverage {
  LocalisationCoverage._();

  /// Locales whose interface strings are translated.
  static const Set<String> translatedInterfaceLocales = {'en', 'es', 'hi'};

  /// Locales the teaching content exists in. English, and only English.
  static const Set<String> contentLocales = {'en'};

  static bool hasTranslatedInterface(String languageCode) =>
      translatedInterfaceLocales.contains(languageCode);

  /// True when this locale gets a partly translated shell and English
  /// content — the state worth being upfront about.
  static bool needsEnglishContentNotice(String languageCode) =>
      !contentLocales.contains(languageCode);

  /// How many pieces of teaching content are English-only.
  ///
  /// Computed rather than written down, so the figure cannot drift away from
  /// the truth as content is added. Every item here is a separate thing a
  /// translator would have to handle.
  static int get englishOnlyContentItems =>
      AcademyCurriculum.allLessons.length +
      AcademyQuizzes.totalQuestions +
      DailyQuestionBank.all.length +
      Glossary.all.length;
}

import 'package:flutter/material.dart';

/// The kind of content a [LessonBlock] renders as.
enum LessonBlockType {
  /// A section heading inside a lesson.
  heading,

  /// A normal paragraph of explanatory text.
  paragraph,

  /// A bulleted list (uses [LessonBlock.bullets]).
  bullets,

  /// A friendly "pro tip" callout.
  tip,

  /// A caution / risk callout.
  warning,

  /// The single most important thing to remember from the lesson.
  keyTakeaway,

  /// A call-to-action that sends the learner to try something in the app
  /// (uses [LessonBlock.actionLabel] and [LessonBlock.actionRoute]).
  tryIt,
}

/// One renderable piece of a lesson. Kept as a simple typed record so we don't
/// need a markdown dependency and rendering stays fully under our control.
class LessonBlock {
  final LessonBlockType type;
  final String text;
  final List<String> bullets;
  final String? actionLabel;
  final String? actionRoute;

  const LessonBlock({
    required this.type,
    this.text = '',
    this.bullets = const [],
    this.actionLabel,
    this.actionRoute,
  });

  const LessonBlock.heading(this.text)
      : type = LessonBlockType.heading,
        bullets = const [],
        actionLabel = null,
        actionRoute = null;

  const LessonBlock.paragraph(this.text)
      : type = LessonBlockType.paragraph,
        bullets = const [],
        actionLabel = null,
        actionRoute = null;

  const LessonBlock.bullets(this.bullets)
      : type = LessonBlockType.bullets,
        text = '',
        actionLabel = null,
        actionRoute = null;

  const LessonBlock.tip(this.text)
      : type = LessonBlockType.tip,
        bullets = const [],
        actionLabel = null,
        actionRoute = null;

  const LessonBlock.warning(this.text)
      : type = LessonBlockType.warning,
        bullets = const [],
        actionLabel = null,
        actionRoute = null;

  const LessonBlock.keyTakeaway(this.text)
      : type = LessonBlockType.keyTakeaway,
        bullets = const [],
        actionLabel = null,
        actionRoute = null;

  const LessonBlock.tryIt({
    required this.text,
    required String label,
    required String route,
  })  : type = LessonBlockType.tryIt,
        bullets = const [],
        actionLabel = label,
        actionRoute = route;
}

/// A single lesson: a few minutes of reading plus one key takeaway.
class Lesson {
  final String id;
  final String title;
  final String summary;
  final int minutes;
  final List<LessonBlock> blocks;

  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.blocks,
  });
}

/// One multiple-choice question used to check understanding after a lesson.
///
/// Kept deliberately simple (four options, one correct) so the quiz reader can
/// render it without any dependency and the pass/fail logic stays trivial to
/// unit-test.
class QuizQuestion {
  final String prompt;
  final List<String> options;

  /// Index into [options] of the single correct answer.
  final int correctIndex;

  /// Shown after the learner answers, right or wrong, to reinforce the point.
  final String explanation;

  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  bool isCorrect(int chosen) => chosen == correctIndex;
}

/// A themed group of lessons that build on each other.
class AcademyModule {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String level; // e.g. "Beginner", "Intermediate"
  final Color accent;
  final List<Lesson> lessons;

  const AcademyModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.level,
    required this.accent,
    required this.lessons,
  });
}

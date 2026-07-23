import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/academy/data/academy_curriculum.dart';
import 'package:volex_terminal/features/academy/data/academy_quizzes.dart';

void main() {
  test('every lesson has a quiz of exactly 3 questions', () {
    for (final lesson in AcademyCurriculum.allLessons) {
      final questions = AcademyQuizzes.forLesson(lesson.id);
      expect(questions.length, AcademyQuizzes.questionsPerQuiz,
          reason: 'lesson ${lesson.id} should have 3 checkpoint questions');
    }
  });

  test('every question is well-formed', () {
    for (final lesson in AcademyCurriculum.allLessons) {
      for (final q in AcademyQuizzes.forLesson(lesson.id)) {
        expect(q.options.length, greaterThanOrEqualTo(2),
            reason: 'lesson ${lesson.id}: a question needs ≥2 options');
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1),
            reason: 'lesson ${lesson.id}: correctIndex out of range');
        expect(q.prompt.trim(), isNotEmpty);
        expect(q.explanation.trim(), isNotEmpty);
      }
    }
  });

  test('isCorrect matches the correct index', () {
    final q = AcademyQuizzes.forLesson('f1').first;
    expect(q.isCorrect(q.correctIndex), isTrue);
    expect(q.isCorrect((q.correctIndex + 1) % q.options.length), isFalse);
  });

  test('pass threshold is 2 of 3', () {
    expect(AcademyQuizzes.isPass(0), isFalse);
    expect(AcademyQuizzes.isPass(1), isFalse);
    expect(AcademyQuizzes.isPass(2), isTrue);
    expect(AcademyQuizzes.isPass(3), isTrue);
  });

  test('hasQuiz distinguishes known vs unknown lessons', () {
    expect(AcademyQuizzes.hasQuiz('f1'), isTrue);
    expect(AcademyQuizzes.hasQuiz('does-not-exist'), isFalse);
  });
}

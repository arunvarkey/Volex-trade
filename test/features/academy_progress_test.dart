import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/features/academy/data/academy_curriculum.dart';
import 'package:volex_terminal/features/academy/services/academy_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AcademyProgressService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.ensureLoaded();
    await service.resetProgress();
  });

  test('curriculum is non-empty and lesson ids are unique', () {
    expect(AcademyCurriculum.totalLessons, greaterThanOrEqualTo(12));
    final ids = AcademyCurriculum.allLessons.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate lesson id');
  });

  test('fresh state: nothing complete, first lesson is next', () {
    expect(service.completedCount, 0);
    expect(service.overallProgress, 0);
    expect(service.nextLesson?.id, AcademyCurriculum.allLessons.first.id);
  });

  test('markComplete advances progress and nextLesson', () async {
    final first = AcademyCurriculum.allLessons.first;
    final second = AcademyCurriculum.allLessons[1];

    await service.markComplete(first.id);
    expect(service.isComplete(first.id), isTrue);
    expect(service.completedCount, 1);
    expect(service.nextLesson?.id, second.id);
    expect(service.overallProgress,
        closeTo(1 / AcademyCurriculum.totalLessons, 1e-9));
  });

  test('markComplete persists to SharedPreferences', () async {
    final first = AcademyCurriculum.allLessons.first;
    await service.markComplete(first.id);
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getStringList('academy_completed_lessons_v1'), contains(first.id));
  });

  test('lessonAfter walks the curriculum in order and ends with null',
      () {
    final all = AcademyCurriculum.allLessons;
    for (int i = 0; i < all.length - 1; i++) {
      expect(service.lessonAfter(all[i].id)?.id, all[i + 1].id);
    }
    expect(service.lessonAfter(all.last.id), isNull);
    expect(service.lessonAfter('nonexistent'), isNull);
  });

  test('completing everything: nextLesson null, progress 1.0', () async {
    for (final l in AcademyCurriculum.allLessons) {
      await service.markComplete(l.id);
    }
    expect(service.nextLesson, isNull);
    expect(service.overallProgress, 1.0);
    for (final m in AcademyCurriculum.modules) {
      expect(service.isModuleComplete(m), isTrue);
    }
  });
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_curriculum.dart';
import '../models/academy_models.dart';

/// Tracks which Academy lessons a learner has completed.
///
/// Deliberately self-contained: a lazily-loaded singleton backed by
/// SharedPreferences, so it needs no DI wiring in main.dart. UI listens to it
/// via [ChangeNotifier] and rebuilds when progress changes.
class AcademyProgressService extends ChangeNotifier {
  AcademyProgressService._();
  static final AcademyProgressService instance = AcademyProgressService._();

  static const String _prefsKey = 'academy_completed_lessons_v1';

  final Set<String> _completed = <String>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Loads persisted progress once. Safe to call repeatedly.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _completed
        ..clear()
        ..addAll(prefs.getStringList(_prefsKey) ?? const <String>[]);
    } catch (_) {
      // If storage is unavailable we simply start from an empty slate rather
      // than crashing the learning experience.
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  bool isComplete(String lessonId) => _completed.contains(lessonId);

  int get completedCount => _completed.length;

  int get totalCount => AcademyCurriculum.totalLessons;

  /// 0.0 – 1.0 across the whole curriculum.
  double get overallProgress {
    final total = totalCount;
    if (total == 0) return 0;
    return (_completed.length.clamp(0, total)) / total;
  }

  /// How many lessons in [module] are complete.
  int completedInModule(AcademyModule module) =>
      module.lessons.where((l) => _completed.contains(l.id)).length;

  bool isModuleComplete(AcademyModule module) =>
      module.lessons.isNotEmpty &&
      completedInModule(module) == module.lessons.length;

  /// The first not-yet-completed lesson in curriculum order, or null if the
  /// learner has finished everything.
  Lesson? get nextLesson {
    for (final lesson in AcademyCurriculum.allLessons) {
      if (!_completed.contains(lesson.id)) return lesson;
    }
    return null;
  }

  /// The lesson immediately after [lessonId] in curriculum order, or null if it
  /// was the last one.
  Lesson? lessonAfter(String lessonId) {
    final all = AcademyCurriculum.allLessons;
    final idx = all.indexWhere((l) => l.id == lessonId);
    if (idx < 0 || idx + 1 >= all.length) return null;
    return all[idx + 1];
  }

  Future<void> markComplete(String lessonId) async {
    if (_completed.add(lessonId)) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> resetProgress() async {
    _completed.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _completed.toList());
    } catch (_) {
      // Non-fatal: progress stays in memory for this session.
    }
  }
}

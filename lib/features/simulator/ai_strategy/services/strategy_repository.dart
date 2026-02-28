// lib/features/simulator/ai_strategy/services/strategy_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';

class StrategyRepository {
  static const String _boxName = 'strategies';
  late Box<Map> _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<void> save(GeneratedStrategy strategy) async {
    await _box.put(strategy.id, strategy.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  GeneratedStrategy? get(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return GeneratedStrategy.fromJson(Map<String, dynamic>.from(json));
  }

  List<GeneratedStrategy> getAll() {
    return _box.values
        .map((json) =>
            GeneratedStrategy.fromJson(Map<String, dynamic>.from(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }

  List<GeneratedStrategy> getByTemplate(String templateId) {
    return getAll().where((s) => s.templateId == templateId).toList();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}

// lib/features/simulator/strategy_builder/services/template_library.dart
import '../models/strategy_template.dart';
import 'templates/rsi_mean_reversion_template.dart';
import 'templates/ma_crossover_template.dart';
import 'templates/breakout_template.dart';

class TemplateLibrary {
  static final List<StrategyTemplate> _templates = [
    RSIMeanReversionTemplate(),
    MACrossoverTemplate(),
    BreakoutTemplate(),
  ];

  static List<StrategyTemplate> get all => List.unmodifiable(_templates);

  static List<StrategyTemplate> getByCategory(String category) {
    return _templates.where((t) => t.category == category).toList();
  }

  static StrategyTemplate? getById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<String> get categories {
    return _templates.map((t) => t.category).toSet().toList();
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/app_logger.dart';
import 'parameter_models.dart';

class ParameterStorageService {
  static final ParameterStorageService _instance =
      ParameterStorageService._internal();
  factory ParameterStorageService() => _instance;
  ParameterStorageService._internal();

  File? _file;

  Future<File> get _localFile async {
    if (_file != null) return _file!;
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/strategy_parameters.json');
    return _file!;
  }

  Future<void> saveParameters(List<StrategyParameterSet> sets) async {
    final file = await _localFile;
    final jsonList = sets.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<List<StrategyParameterSet>> loadParameters() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => StrategyParameterSet.fromJson(j)).toList();
    } catch (e) {
      AppLogger.error("Error loading parameters: $e");
      return [];
    }
  }

  Future<void> saveParameterSet(StrategyParameterSet set) async {
    final current = await loadParameters();
    // Remove existing for this strategy/user combo
    current.removeWhere(
        (s) => s.strategyId == set.strategyId && s.userId == set.userId);
    current.add(set);
    await saveParameters(current);
  }

  Future<StrategyParameterSet?> getParameterSet(
      String strategyId, String userId) async {
    final all = await loadParameters();
    try {
      return all
          .firstWhere((s) => s.strategyId == strategyId && s.userId == userId);
    } catch (e) {
      return null;
    }
  }
}

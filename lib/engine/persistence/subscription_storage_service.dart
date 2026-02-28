import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../subscription/strategy_subscription.dart';
import '../subscription/creator_revenue_record.dart';
import '../../core/app_logger.dart';

class SubscriptionStorageService {
  static SubscriptionStorageService? _instance;
  factory SubscriptionStorageService() =>
      _instance ??= SubscriptionStorageService._internal();
  SubscriptionStorageService._internal();

  File? _subsFile;
  File? _revenueFile;

  @visibleForTesting
  void reset() {
    _subsFile = null;
    _revenueFile = null;
  }

  Future<File> get _localSubsFile async {
    if (_subsFile != null) return _subsFile!;
    final directory = await getApplicationDocumentsDirectory();
    _subsFile = File('${directory.path}/subscriptions.json');
    return _subsFile!;
  }

  Future<File> get _localRevenueFile async {
    if (_revenueFile != null) return _revenueFile!;
    final directory = await getApplicationDocumentsDirectory();
    _revenueFile = File('${directory.path}/revenue.json');
    return _revenueFile!;
  }

  Future<List<StrategySubscription>> loadSubscriptions() async {
    try {
      final file = await _localSubsFile;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => StrategySubscription.fromJson(j)).toList();
    } catch (e) {
      AppLogger.error("SubStorage: Error loading subs: $e");
      return [];
    }
  }

  Future<void> saveSubscriptions(List<StrategySubscription> subs) async {
    final file = await _localSubsFile;
    final jsonList = subs.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<List<CreatorRevenueRecord>> loadRevenueRecords() async {
    try {
      final file = await _localRevenueFile;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => CreatorRevenueRecord.fromJson(j)).toList();
    } catch (e) {
      AppLogger.error("SubStorage: Error loading revenue: $e");
      return [];
    }
  }

  Future<void> saveRevenueRecords(List<CreatorRevenueRecord> records) async {
    final file = await _localRevenueFile;
    final jsonList = records.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
}

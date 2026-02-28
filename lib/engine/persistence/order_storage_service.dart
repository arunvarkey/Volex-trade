import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:volex_terminal/domain/order.dart';
import '../../core/app_logger.dart';

class OrderStorageService {
  static OrderStorageService? _instance;
  factory OrderStorageService() =>
      _instance ??= OrderStorageService._internal();
  OrderStorageService._internal();

  File? _file;
  Future<void>? _activeLock;

  Future<void> _synchronized(Future<void> Function() action) async {
    final previousTask = _activeLock;
    final completer = Completer<void>();
    _activeLock = completer.future;
    try {
      await previousTask;
      await action();
    } finally {
      completer.complete();
    }
  }

  @visibleForTesting
  void reset() {
    _file = null;
  }

  Future<File> get _localFile async {
    if (_file != null) return _file!;
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/orders.json');
    return _file!;
  }

  /// Loads all orders from storage
  Future<List<Order>> getAllOrders() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => Order.fromJson(j)).toList();
    } catch (e) {
      AppLogger.error("OrderStorage: Error loading orders: $e");
      return [];
    }
  }

  /// Saves a single order (upsert)
  Future<void> saveOrder(Order order) async {
    await _synchronized(() async {
      final file = await _localFile;
      List<Order> currentOrders = await getAllOrders();

      final index = currentOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        currentOrders[index] = order;
      } else {
        currentOrders.add(order);
      }

      final jsonList = currentOrders.map((o) => o.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    });
  }

  /// Overwrite all orders (used by SyncEngine)
  Future<void> saveAllOrders(List<Order> orders) async {
    await _synchronized(() async {
      final file = await _localFile;
      final jsonList = orders.map((o) => o.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    });
  }
}

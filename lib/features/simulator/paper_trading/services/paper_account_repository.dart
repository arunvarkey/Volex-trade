// lib/features/simulator/paper_trading/services/paper_account_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/paper_account.dart';

class PaperAccountRepository {
  static const String _boxName = 'paper_accounts';
  late Box<Map> _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<PaperAccount> getOrCreate(String strategyId) async {
    final existing = _box.get(strategyId);

    if (existing != null) {
      return PaperAccount.fromJson(Map<String, dynamic>.from(existing));
    }

    // Create new account
    final account = PaperAccount(
      id: strategyId,
      initialEquity: 10000.0,
      currentEquity: 10000.0,
      createdAt: DateTime.now(),
    );

    await save(account);
    return account;
  }

  Future<void> save(PaperAccount account) async {
    await _box.put(account.id, account.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<PaperAccount> getAll() {
    return _box.values
        .map((json) => PaperAccount.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}

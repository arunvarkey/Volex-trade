import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/domain/order.dart';
import '../domain/trade_zone.dart';
import '../core/app_logger.dart';

class PersistenceService {
  static const String keyOrders = 'volex_orders_v1';
  static const String keyZones = 'volex_zones_v1';

  final SharedPreferences _prefs;

  PersistenceService(this._prefs);

  static Future<PersistenceService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PersistenceService(prefs);
  }

  // --- ORDERS ---
  String _orderKey(String symbol, bool isLive) =>
      '${keyOrders}_${isLive ? 'live' : 'sim'}_$symbol';

  String _zoneKey(String symbol, bool isLive) =>
      '${keyZones}_${isLive ? 'live' : 'sim'}_$symbol';

  Future<void> saveOrders(List<Order> orders, String symbol,
      {bool isLive = false}) async {
    final List<Map<String, dynamic>> jsonList =
        orders.map((o) => o.toJson()).toList();
    final String jsonString = json.encode(jsonList);
    await _prefs.setString(_orderKey(symbol, isLive), jsonString);
    AppLogger.info(
        'PERSISTENCE: Saved ${orders.length} ${isLive ? 'LIVE' : 'SIM'} orders for $symbol');
  }

  List<Order> loadOrders(String symbol, {bool isLive = false}) {
    final String? jsonString = _prefs.getString(_orderKey(symbol, isLive));
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('PERSISTENCE ERROR (Orders): $e');
      return [];
    }
  }

  // --- ZONES ---

  Future<void> saveZones(List<TradeZone> zones, String symbol,
      {bool isLive = false}) async {
    final List<Map<String, dynamic>> jsonList =
        zones.map((z) => z.toJson()).toList();
    final String jsonString = json.encode(jsonList);
    await _prefs.setString(_zoneKey(symbol, isLive), jsonString);
    AppLogger.info(
        'PERSISTENCE: Saved ${zones.length} ${isLive ? 'LIVE' : 'SIM'} zones for $symbol');
  }

  List<TradeZone> loadZones(String symbol, {bool isLive = false}) {
    final String? jsonString = _prefs.getString(_zoneKey(symbol, isLive));
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => TradeZone.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('PERSISTENCE ERROR (Zones): $e');
      return [];
    }
  }

  Future<void> clearAll(String symbol, {bool isLive = false}) async {
    await _prefs.remove(_orderKey(symbol, isLive));
    await _prefs.remove(_zoneKey(symbol, isLive));
  }
}

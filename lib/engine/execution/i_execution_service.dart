import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/domain/symbol_info.dart';

abstract class IExecutionService {
  List<Order> get orders;
  Future<OrderResult?> placeOrder(Order order);
  Future<void> cancelOrder(String orderId, SymbolInfo symbol);
  void closeAllOrders([double? currentPrice]);
  Future<void> closeOrder(String orderId, [double? currentPrice]);
  bool isStrategyRunning(String id);
  Future<void> startStrategy(String id);
  Future<void> stopStrategy(String id);
  void inject(Order order);
}

class OrderResult {
  final bool success;
  final Order? order;
  final String? message;
  OrderResult({required this.success, this.order, this.message});
}

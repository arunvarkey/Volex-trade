import 'package:volex_terminal/engine/execution/i_execution_service.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/domain/symbol_info.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'execution_simulator.dart';

class SimulatedExecutionService implements IExecutionService {
  final ExecutionSimulator _simulator;

  SimulatedExecutionService(this._simulator);

  @override
  List<Order> get orders => _simulator.orders;

  @override
  Future<OrderResult?> placeOrder(Order order) async {
    _simulator.placeOrder(order);
    return OrderResult(success: true, order: order);
  }

  @override
  Future<void> cancelOrder(String orderId, SymbolInfo symbol) async {
    _simulator.cancelOrder(orderId);
  }

  @override
  void closeAllOrders([double? currentPrice]) {
    _simulator.closeAllOrders(currentPrice);
  }

  @override
  Future<void> closeOrder(String orderId, [double? currentPrice]) async {
    _simulator.closeOrder(orderId, currentPrice);
  }

  @override
  void inject(Order order) {
    _simulator.inject(order);
  }

  @override
  bool isStrategyRunning(String id) => true; // Always running in sim

  @override
  Future<void> startStrategy(String id) async {}

  @override
  Future<void> stopStrategy(String id) async {}
}

class BacktestChartController extends ChartController {
  @override
  void notifyListeners() {}
}

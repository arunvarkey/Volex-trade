import 'package:flutter/foundation.dart';
import 'package:volex_terminal/domain/order.dart';

class StubBinanceExecutionService {
  StubBinanceExecutionService() {
    assert(!kReleaseMode,
        'StubBinanceExecutionService must never be used in release builds (Task 41)');
  }
  Future<BinanceOrderResult> placeMarketOrder({
    required String symbol,
    required OrderSide side,
    required double quantity,
  }) async {
    // Stub for live execution
    return BinanceOrderResult(
      orderId: 'BNB_${DateTime.now().millisecondsSinceEpoch}',
      executedPrice: 50000.0, // Mock price
      executedQuantity: quantity,
    );
  }

  Future<BinanceOrderResult> placeLimitOrder({
    required String symbol,
    required OrderSide side,
    required double quantity,
    required double price,
  }) async {
    return BinanceOrderResult(
      orderId: 'BNB_LIMIT_${DateTime.now().millisecondsSinceEpoch}',
      executedPrice: price,
      executedQuantity: quantity,
    );
  }

  Future<void> cancelOrder(String orderId) async {
    // Stub
  }

  Future<double> getCurrentPrice(String symbol) async {
    return 50000.0;
  }

  Future<BinanceAccountInfo> getAccountInfo() async {
    return BinanceAccountInfo(totalBalance: 5000.0);
  }
}

class BinanceOrderResult {
  final String orderId;
  final double executedPrice;
  final double executedQuantity;

  BinanceOrderResult({
    required this.orderId,
    required this.executedPrice,
    required this.executedQuantity,
  });
}

class BinanceAccountInfo {
  final double totalBalance;
  BinanceAccountInfo({required this.totalBalance});
}

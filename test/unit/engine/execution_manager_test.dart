import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/data/binance/binance_api_service.dart';
import 'package:volex_terminal/engine/risk_manager.dart';
import 'package:volex_terminal/domain/order.dart';

@GenerateMocks([BinanceApiService, RiskManager])
import 'execution_manager_test.mocks.dart';

void main() {
  late ExecutionManager manager;
  late MockBinanceApiService mockApi;
  late MockRiskManager mockRisk;

  setUp(() {
    mockApi = MockBinanceApiService();
    mockRisk = MockRiskManager();

    // Default risk validation to true
    when(mockRisk.validateOrder(
      quantity: anyNamed('quantity'),
      priceUsdt: anyNamed('priceUsdt'),
      strategyId: anyNamed('strategyId'),
      isLive: anyNamed('isLive'),
      isReduction: anyNamed('isReduction'),
    )).thenReturn(true);

    manager = ExecutionManager(
      exchange: mockApi,
      riskManager: mockRisk,
    );
  });

  group('ExecutionManager - Market Orders', () {
    test('executes buy order successfully', () async {
      // Setup mock response
      when(mockApi.placeOrder(
        symbol: anyNamed('symbol'),
        side: 'BUY',
        quantity: 0.001,
        price: anyNamed('price'),
      )).thenAnswer((_) async => Order(
            id: '12345',
            symbol: 'BTCUSDT',
            side: OrderSide.buy,
            type: OrderType.market,
            quantity: 0.1,
            status: OrderStatus.filled,
            filledQuantity: 0.1,
            price: 50000.0,
            filledPrice: 50000.0,
            filledAt: DateTime.now(),
          ));

      // Execute
      final result = await manager.placeMarketOrder(
        symbol: 'BTCUSDT',
        side: OrderSide.buy,
        quantity: 0.001,
        currentPrice: 50000.0,
      );

      // Verify
      expect(result.success, true);
      expect(result.order?.id, '12345');
      expect(result.order?.status, OrderStatus.filled);

      // Verify mock calls
      verify(mockApi.placeOrder(
        symbol: anyNamed('symbol'),
        side: 'BUY',
        quantity: 0.001,
        price: anyNamed('price'),
      )).called(1);

      verify(mockRisk.validateOrder(
        quantity: 0.001,
        priceUsdt: 50000.0,
        isLive: false,
        isReduction: anyNamed('isReduction'),
      )).called(1);
    });

    test('handles exchange failure gracefully', () async {
      when(mockApi.placeOrder(
        symbol: anyNamed('symbol'),
        side: 'BUY',
        quantity: 0.1,
        price: anyNamed('price'),
      )).thenThrow(Exception('Network Error'));

      expect(
        () => manager.placeMarketOrder(
          symbol: 'BTCUSDT',
          side: OrderSide.buy,
          quantity: 0.1,
        ),
        throwsException,
      );

      expect(manager.isExecuting, false); // Should reset state
      expect(manager.lastError, contains('Network Error'));
    });

    test('blocks order if RiskManager validation fails', () async {
      // Risk manager says NO
      when(mockRisk.validateOrder(
        quantity: anyNamed('quantity'),
        priceUsdt: anyNamed('priceUsdt'),
        strategyId: anyNamed('strategyId'),
        isLive: anyNamed('isLive'),
        isReduction: anyNamed('isReduction'),
      )).thenReturn(false);

      expect(
        () => manager.placeMarketOrder(
          symbol: 'BTCUSDT',
          side: OrderSide.buy,
          quantity: 10.0, // Too big
        ),
        throwsException, // "Risk Validation Failed"
      );

      // Verify exchange was NOT called
      verifyNever(mockApi.placeOrder(
        symbol: anyNamed('symbol'),
        side: anyNamed('side'),
        quantity: anyNamed('quantity'),
      ));
    });
  });

  group('ExecutionManager - Limit Orders', () {
    test('delegates limit order to placeMarketOrder (MVP behavior)', () async {
      when(mockApi.placeOrder(
        symbol: anyNamed('symbol'),
        side: 'SELL',
        quantity: 0.5,
        price: anyNamed('price'),
      )).thenAnswer((_) async => Order(
            id: 'LIMIT_123',
            symbol: 'BTCUSDT',
            side: OrderSide.sell,
            type: OrderType.market,
            quantity: 0.5,
            status: OrderStatus.filled,
            filledQuantity: 0.5,
            price: 55000.0,
            filledPrice: 55000.0,
            filledAt: DateTime.now(),
          ));

      final result = await manager.placeLimitOrder(
        symbol: 'BTCUSDT',
        side: OrderSide.sell,
        quantity: 0.5,
        limitPrice: 55000.0,
      );

      expect(result.success, true);
      verify(mockApi.placeOrder(
        symbol: anyNamed('symbol'),
        side: 'SELL',
        quantity: 0.5,
        price: anyNamed('price'),
      )).called(1);
    });
  });
}

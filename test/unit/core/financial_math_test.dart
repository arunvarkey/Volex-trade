import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/core/financial_math.dart';

void main() {
  group('FinancialMath', () {
    // ============================================
    // 1. CONVERSION UTILITIES
    // ============================================
    group('Conversion Utilities', () {
      test('dollarsToCents converts correctly', () {
        expect(FinancialMath.dollarsToCents(100.50), 10050);
        expect(FinancialMath.dollarsToCents(0.99), 99);
        expect(FinancialMath.dollarsToCents(0.00), 0);
        expect(FinancialMath.dollarsToCents(1234.56), 123456);
      });

      test('dollarsToCents throws on invalid input', () {
        expect(() => FinancialMath.dollarsToCents(-5.0), throwsArgumentError);
        expect(() => FinancialMath.dollarsToCents(double.infinity),
            throwsArgumentError);
        expect(() => FinancialMath.dollarsToCents(double.nan),
            throwsArgumentError);
      });

      test('centsToDollars converts correctly', () {
        expect(FinancialMath.centsToDollars(10050), 100.50);
        expect(FinancialMath.centsToDollars(99), 0.99);
        expect(FinancialMath.centsToDollars(0), 0.0);
      });

      test('centsToDollars handles negative input', () {
        expect(FinancialMath.centsToDollars(-100), -1.0);
      });

      test('formatCents formats correctly', () {
        expect(FinancialMath.formatCents(10050), '\$100.50');
        expect(FinancialMath.formatCents(99), '\$0.99');
        expect(FinancialMath.formatCents(500, showSymbol: false), '5.00');
        expect(FinancialMath.formatCents(123456), '\$1234.56');
      });

      test('parseDollars parses correctly', () {
        expect(FinancialMath.parseDollars('\$100.50'), 10050);
        expect(FinancialMath.parseDollars('100.50'), 10050);
        expect(FinancialMath.parseDollars('\$ 1,234.56'), 123456);
        expect(FinancialMath.parseDollars('0.99'), 99);
      });

      test('parseDollars throws on invalid format', () {
        expect(() => FinancialMath.parseDollars('abc'), throwsArgumentError);
        expect(() => FinancialMath.parseDollars(''), throwsArgumentError);
      });
    });

    // ============================================
    // 2. ARITHMETIC OPERATIONS
    // ============================================
    group('Arithmetic Operations', () {
      test('add works correctly', () {
        expect(FinancialMath.add(100, 50), 150);
        expect(FinancialMath.add(0, 50), 50);
      });

      test('subtract works correctly', () {
        expect(FinancialMath.subtract(100, 50), 50);
        expect(FinancialMath.subtract(50, 50), 0);
      });

      test('subtract handles negative result correctly', () {
        expect(FinancialMath.subtract(50, 100), -50);
      });

      test('multiply works correctly', () {
        expect(FinancialMath.multiply(10000, 0.05), 500); // 5% of 100
        expect(FinancialMath.multiply(100, 1.5), 150);
        expect(FinancialMath.multiply(100, 0), 0);
      });

      test('percentage works correctly', () {
        expect(FinancialMath.percentage(10000, 5.0), 500);
        expect(FinancialMath.percentage(200, 50.0), 100);
      });

      test('percentage throws on invalid percent', () {
        expect(() => FinancialMath.percentage(100, -1), throwsArgumentError);
        expect(() => FinancialMath.percentage(100, 101), throwsArgumentError);
      });

      test('divide works correctly', () {
        expect(FinancialMath.divide(100, 2), 50);
        expect(FinancialMath.divide(100, 3), 33); // Rounds correctly
      });

      test('divide throws on non-positive divisor', () {
        expect(() => FinancialMath.divide(100, 0), throwsArgumentError);
        expect(() => FinancialMath.divide(100, -1), throwsArgumentError);
      });
    });

    // ============================================
    // 3. TRADING CALCULATIONS
    // ============================================
    group('Trading Calculations', () {
      test('calculateOrderCost works correctly', () {
        // 0.5 units * $100 = $50 (5000 cents)
        expect(
            FinancialMath.calculateOrderCost(
                quantity: 0.5, pricePerUnit: 100.0),
            5000);
        // 2.0 units * $50.25 = $100.50 (10050 cents)
        expect(
            FinancialMath.calculateOrderCost(
                quantity: 2.0, pricePerUnit: 50.25),
            10050);
      });

      test('calculateOrderCost throws on invalid input', () {
        expect(
            () => FinancialMath.calculateOrderCost(
                quantity: 0, pricePerUnit: 100),
            throwsArgumentError);
        expect(
            () =>
                FinancialMath.calculateOrderCost(quantity: 1, pricePerUnit: 0),
            throwsArgumentError);
      });

      test('calculatePnL works for LONG positions', () {
        // Buy 1.0 @ 50,000, Sell @ 55,000 -> +5,000 profit (500,000 cents)
        expect(
          FinancialMath.calculatePnL(
            quantity: 1.0,
            entryPrice: 50000.0,
            exitPrice: 55000.0,
            isLong: true,
          ),
          500000,
        );

        // Buy 1.0 @ 50,000, Sell @ 45,000 -> -5,000 loss (-500,000 cents)
        expect(
          FinancialMath.calculatePnL(
            quantity: 1.0,
            entryPrice: 50000.0,
            exitPrice: 45000.0,
            isLong: true,
          ),
          -500000,
        );
      });

      test('calculatePnL works for SHORT positions', () {
        // Sell 1.0 @ 50,000, Buy @ 45,000 -> +5,000 profit (500,000 cents)
        expect(
          FinancialMath.calculatePnL(
            quantity: 1.0,
            entryPrice: 50000.0,
            exitPrice: 45000.0,
            isLong: false,
          ),
          500000,
        );

        // Sell 1.0 @ 50,000, Buy @ 55,000 -> -5,000 loss (-500,000 cents)
        expect(
          FinancialMath.calculatePnL(
            quantity: 1.0,
            entryPrice: 50000.0,
            exitPrice: 55000.0,
            isLong: false,
          ),
          -500000,
        );
      });

      test('hasSufficientBalance checks correctly', () {
        expect(
            FinancialMath.hasSufficientBalance(
                balanceCents: 100, orderCostCents: 50),
            true);
        expect(
            FinancialMath.hasSufficientBalance(
                balanceCents: 50, orderCostCents: 100),
            false);
        expect(
            FinancialMath.hasSufficientBalance(
                balanceCents: 50, orderCostCents: 50),
            true);
      });

      test('calculateRemainingBalance works correctly', () {
        expect(
            FinancialMath.calculateRemainingBalance(
                balanceCents: 100, orderCostCents: 40),
            60);
      });

      test('calculateRemainingBalance throws if insufficient', () {
        expect(
            () => FinancialMath.calculateRemainingBalance(
                balanceCents: 40, orderCostCents: 100),
            throwsArgumentError);
      });
    });

    // ============================================
    // 4. RISK CALCULATIONS
    // ============================================
    group('Risk Calculations', () {
      test('calculatePositionSize calculates correctly', () {
        // Account: $10,000 (1,000,000 cents)
        // Risk: 1% ($100 risk)
        // Entry: $100
        // Stop Loss: $90 (Risk per share = $10)
        // Quantity = Risk Amount / Risk Per Share = $100 / $10 = 10 shares
        // Total Order Cost = 10 shares * $100 entry = $1,000 (100,000 cents)

        final cost = FinancialMath.calculatePositionSize(
          accountBalanceCents: 1000000,
          riskPercentage: 1.0,
          entryPrice: 100.0,
          stopLossPrice: 90.0,
        );

        expect(cost, 100000);
      });

      test('calculateDrawdownPercent works correctly', () {
        // Peak: $100, Current: $90 -> 10% drawdown
        expect(
            FinancialMath.calculateDrawdownPercent(
                peakBalanceCents: 10000, currentBalanceCents: 9000),
            10.0);

        // Peak: $100, Current: $110 -> -10% drawdown (profit) but logical logic handles diff
        // Usually drawdown is positive number representing loss from peak
        expect(
            FinancialMath.calculateDrawdownPercent(
                peakBalanceCents: 10000, currentBalanceCents: 10000),
            0.0);
      });

      test('calculateROI works correctly', () {
        // Init: $100, Current: $150 -> 50% ROI
        expect(
            FinancialMath.calculateROI(
                initialBalanceCents: 10000, currentBalanceCents: 15000),
            50.0);

        // Init: $100, Current: $50 -> -50% ROI
        expect(
            FinancialMath.calculateROI(
                initialBalanceCents: 10000, currentBalanceCents: 5000),
            -50.0);
      });
    });

    // ============================================
    // 5. AGGREGATION & UTILS
    // ============================================
    group('Aggregation & Utils', () {
      test('sum works correctly', () {
        expect(FinancialMath.sum([10, 20, 30]), 60);
        expect(FinancialMath.sum([]), 0);
      });

      test('average works correctly', () {
        expect(FinancialMath.average([10, 20, 30]), 20);
        expect(FinancialMath.average([10, 20]), 15);
      });

      test('max/min works correctly', () {
        expect(FinancialMath.max(10, 20), 20);
        expect(FinancialMath.min(10, 20), 10);
      });

      test('isValidCents checks range', () {
        expect(FinancialMath.isValidCents(100), true);
        expect(FinancialMath.isValidCents(-1), false);
        expect(FinancialMath.isValidCents(1000000000000000), false); // Too huge
      });
    });
  });

  group('shouldTriggerProtectiveExit', () {
    // Long: entry 100, stop 98, target 104.
    test('long stops out at or below the stop', () {
      bool at(double price) => FinancialMath.shouldTriggerProtectiveExit(
          isLong: true, price: price, stopLoss: 98, takeProfit: 104);
      expect(at(99), false); // still inside the range
      expect(at(98), true); // exactly at the stop
      expect(at(97.5), true); // through the stop
    });

    test('long takes profit at or above the target', () {
      bool at(double price) => FinancialMath.shouldTriggerProtectiveExit(
          isLong: true, price: price, stopLoss: 98, takeProfit: 104);
      expect(at(103.9), false);
      expect(at(104), true);
      expect(at(110), true);
    });

    // Short is the mirror image: stop 102 (above), target 96 (below).
    test('short stops out at or above the stop', () {
      bool at(double price) => FinancialMath.shouldTriggerProtectiveExit(
          isLong: false, price: price, stopLoss: 102, takeProfit: 96);
      expect(at(101), false);
      expect(at(102), true);
      expect(at(105), true);
    });

    test('short takes profit at or below the target', () {
      bool at(double price) => FinancialMath.shouldTriggerProtectiveExit(
          isLong: false, price: price, stopLoss: 102, takeProfit: 96);
      expect(at(96.5), false);
      expect(at(96), true);
      expect(at(90), true);
    });

    test('a long is not closed by short-side levels (direction not flipped)', () {
      // Price well above entry must NOT look like a stop-out for a long.
      expect(
          FinancialMath.shouldTriggerProtectiveExit(
              isLong: true, price: 103, stopLoss: 98),
          false);
      // ...but the same price does stop out a short with a stop at 102.
      expect(
          FinancialMath.shouldTriggerProtectiveExit(
              isLong: false, price: 103, stopLoss: 102),
          true);
    });

    test('no levels set, or a non-positive price, never triggers', () {
      expect(
          FinancialMath.shouldTriggerProtectiveExit(isLong: true, price: 100),
          false);
      expect(
          FinancialMath.shouldTriggerProtectiveExit(
              isLong: true, price: 0, stopLoss: 98, takeProfit: 104),
          false);
    });
  });
}

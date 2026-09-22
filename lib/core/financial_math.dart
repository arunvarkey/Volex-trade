/// Financial mathematics utilities using fixed-point arithmetic
/// All monetary values are stored as integers (cents) to avoid floating-point precision errors
class FinancialMath {
  // Private constructor to prevent instantiation
  FinancialMath._();

  // ============================================
  // CONVERSION UTILITIES
  // ============================================

  /// Converts a dollar amount (double) to cents (int) for safe fixed-point arithmetic.
  ///
  /// This method is strictly checked to prevent overflow and invalid values.
  ///
  /// Example:
  /// ```dart
  /// FinancialMath.dollarsToCents(100.50); // Returns 10050
  /// ```
  ///
  /// Throws [ArgumentError] if:
  /// * [dollars] is NaN or Infinite.
  /// * [dollars] is negative.
  /// * [dollars] exceeds $10 billion (prevent overflow).
  static int dollarsToCents(double dollars) {
    if (dollars.isNaN || dollars.isInfinite) {
      throw ArgumentError('Invalid dollar amount: $dollars');
    }
    if (dollars < 0) {
      throw ArgumentError('Dollar amount cannot be negative: $dollars');
    }
    if (dollars > 10000000000) {
      // Max $10 billion
      throw ArgumentError('Dollar amount exceeds maximum: $dollars');
    }
    return (dollars * 100).round();
  }

  /// Convert cents to dollars (for display)
  /// Example: 10050 cents -> 100.50
  static double centsToDollars(int cents) {
    return cents / 100.0;
  }

  /// Format cents as dollar string
  /// Example: 10050 cents -> "$100.50"
  static String formatCents(int cents, {bool showSymbol = true}) {
    final dollars = centsToDollars(cents);
    final formatted = dollars.toStringAsFixed(2);
    return showSymbol ? '\$$formatted' : formatted;
  }

  /// Parse dollar string to cents
  /// Example: "$100.50" or "100.50" -> 10050 cents
  static int parseDollars(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\$,\s]'), '');
    final dollars = double.tryParse(cleaned);
    if (dollars == null) {
      throw ArgumentError('Invalid dollar format: $input');
    }
    return dollarsToCents(dollars);
  }

  // ============================================
  // ARITHMETIC OPERATIONS
  // ============================================

  /// Add two monetary amounts (in cents)
  static int add(int cents1, int cents2) {
    final result = cents1 + cents2;
    if (result < 0) {
      throw ArgumentError('Addition resulted in negative value');
    }
    return result;
  }

  /// Subtract monetary amounts (in cents)
  static int subtract(int cents1, int cents2) {
    return cents1 - cents2; // Can legitimately be negative for PnL
  }

  /// Separate method for balance checks:
  static int safeSubtractBalance(int balanceCents, int costCents) {
    if (costCents > balanceCents) {
      throw ArgumentError(
          'Subtraction resulted in negative balance. Insufficient funds for cost: $costCents from balance: $balanceCents');
    }
    return balanceCents - costCents;
  }

  /// Multiply cents by a factor (for percentage calculations)
  /// Example: 10000 cents * 0.05 = 500 cents (5%)
  static int multiply(int cents, double factor) {
    if (factor < 0) {
      throw ArgumentError('Factor cannot be negative: $factor');
    }
    return (cents * factor).round();
  }

  /// Calculate percentage of amount
  /// Example: 10000 cents, 5% -> 500 cents
  static int percentage(int cents, double percent) {
    if (percent < 0 || percent > 100) {
      throw ArgumentError('Percentage must be 0-100: $percent');
    }
    return multiply(cents, percent / 100);
  }

  /// Divide cents (for averaging, etc.)
  static int divide(int cents, int divisor) {
    if (divisor <= 0) {
      throw ArgumentError('Divisor must be positive: $divisor');
    }
    return (cents / divisor).round();
  }

  // ============================================
  // TRADING CALCULATIONS
  // ============================================

  /// Calculate order cost in cents
  /// cost = quantity * price
  static int calculateOrderCost({
    required double quantity,
    required double pricePerUnit,
  }) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be positive: $quantity');
    }
    if (pricePerUnit <= 0) {
      throw ArgumentError('Price must be positive: $pricePerUnit');
    }

    final totalDollars = quantity * pricePerUnit;
    return dollarsToCents(totalDollars);
  }

  /// Calculate profit/loss in cents
  /// pnl = (exitPrice - entryPrice) * quantity for LONG
  /// pnl = (entryPrice - exitPrice) * quantity for SHORT
  static int calculatePnL({
    required double quantity,
    required double entryPrice,
    required double exitPrice,
    required bool isLong,
  }) {
    final priceDiff =
        isLong ? (exitPrice - entryPrice) : (entryPrice - exitPrice);
    final pnlDollars = priceDiff * quantity;

    // PnL can be negative, so we use a different approach
    final pnlCents = (pnlDollars * 100).round();
    return pnlCents;
  }

  /// Calculate position value in cents
  static int calculatePositionValue({
    required double quantity,
    required double currentPrice,
  }) {
    return calculateOrderCost(
      quantity: quantity,
      pricePerUnit: currentPrice,
    );
  }

  /// Check if balance is sufficient for order
  static bool hasSufficientBalance({
    required int balanceCents,
    required int orderCostCents,
  }) {
    return balanceCents >= orderCostCents;
  }

  /// Calculate remaining balance after order
  static int calculateRemainingBalance({
    required int balanceCents,
    required int orderCostCents,
  }) {
    if (!hasSufficientBalance(
      balanceCents: balanceCents,
      orderCostCents: orderCostCents,
    )) {
      throw ArgumentError('Insufficient balance for order');
    }
    return subtract(balanceCents, orderCostCents);
  }

  // ============================================
  // RISK CALCULATIONS
  // ============================================

  // ============================================
  // RISK CALCULATIONS
  // ============================================

  /// Calculates the maximum position size based on a fixed percentage of account risk.
  ///
  /// This ensures that if the [stopLossPrice] is hit, the loss will not exceed
  /// [riskPercentage] of the [accountBalanceCents].
  ///
  /// Formula: `Risk Amount = Balance * Risk %`
  /// `Quantity = Risk Amount / (Entry - StopLoss)`
  /// `Cost = Quantity * Entry`
  ///
  /// Returns the total cost of the order in cents (margin required).
  ///
  /// Throws [ArgumentError] if:
  /// * [riskPercentage] is not between 0 and 100.
  /// * [entryPrice] equals [stopLossPrice] (division by zero risk).
  static int calculatePositionSize({
    required int accountBalanceCents,
    required double riskPercentage,
    required double entryPrice,
    required double stopLossPrice,
  }) {
    if (riskPercentage <= 0 || riskPercentage > 100) {
      throw ArgumentError('Risk percentage must be 0-100: $riskPercentage');
    }

    // Calculate risk amount in cents
    final riskAmountCents = percentage(accountBalanceCents, riskPercentage);

    // Calculate price risk per unit
    final priceRisk = (entryPrice - stopLossPrice).abs();
    if (priceRisk == 0) {
      throw ArgumentError('Entry and stop loss prices cannot be equal');
    }

    // Calculate quantity
    final riskAmountDollars = centsToDollars(riskAmountCents);
    final quantity = riskAmountDollars / priceRisk;

    // Calculate order cost
    return calculateOrderCost(
      quantity: quantity,
      pricePerUnit: entryPrice,
    );
  }

  /// Calculate maximum drawdown percentage
  static double calculateDrawdownPercent({
    required int peakBalanceCents,
    required int currentBalanceCents,
  }) {
    if (peakBalanceCents <= 0) {
      return 0.0;
    }
    final drawdown = peakBalanceCents - currentBalanceCents;
    return (drawdown / peakBalanceCents) * 100;
  }

  /// Calculate return on investment percentage
  static double calculateROI({
    required int initialBalanceCents,
    required int currentBalanceCents,
  }) {
    if (initialBalanceCents <= 0) {
      return 0.0;
    }
    final profit = currentBalanceCents - initialBalanceCents;
    return (profit / initialBalanceCents) * 100;
  }

  // ============================================
  // VALIDATION
  // ============================================

  /// Validate that a cents value is within acceptable range
  static bool isValidCents(int cents) {
    return cents >= 0 && cents <= 1000000000000; // Max $10 billion
  }

  /// Validate minimum order size (e.g., $0.01)
  static bool meetsMinimumOrderSize(int orderCostCents,
      {int minimumCents = 1}) {
    return orderCostCents >= minimumCents;
  }

  // ============================================
  // COMPARISON
  // ============================================

  /// Compare two cent values
  static int compare(int cents1, int cents2) {
    return cents1.compareTo(cents2);
  }

  /// Get maximum of two cent values
  static int max(int cents1, int cents2) {
    return cents1 > cents2 ? cents1 : cents2;
  }

  /// Get minimum of two cent values
  static int min(int cents1, int cents2) {
    return cents1 < cents2 ? cents1 : cents2;
  }

  // ============================================
  // AGGREGATION
  // ============================================

  /// Sum a list of cent values
  static int sum(List<int> centsList) {
    return centsList.fold(0, (sum, cents) => sum + cents);
  }

  /// Calculate average of cent values
  static int average(List<int> centsList) {
    if (centsList.isEmpty) {
      return 0;
    }
    final total = sum(centsList);
    return divide(total, centsList.length);
  }

  // ============================================
  // PROTECTIVE EXITS
  // ============================================

  /// Whether an open position's stop-loss or take-profit has been reached at
  /// [price].
  ///
  /// The comparison flips with direction — a long stops out *below* entry and
  /// targets *above* it, a short is the mirror image — so this is kept as a
  /// pure function that can be tested directly. Getting it backwards would
  /// either close every position instantly or never close one at all.
  static bool shouldTriggerProtectiveExit({
    required bool isLong,
    required double price,
    double? stopLoss,
    double? takeProfit,
  }) {
    if (price <= 0) return false;
    final hitStop =
        stopLoss != null && (isLong ? price <= stopLoss : price >= stopLoss);
    final hitTarget = takeProfit != null &&
        (isLong ? price >= takeProfit : price <= takeProfit);
    return hitStop || hitTarget;
  }
}

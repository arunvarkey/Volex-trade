import 'package:volex_terminal/core/app_config.dart';

/// Comprehensive input validation framework for security and data integrity
class InputValidator {
  // Private constructor to prevent instantiation
  InputValidator._();

  // ============================================
  // NUMERICAL VALIDATION
  // ============================================

  /// Validate trading amount
  static ValidationResult validateAmount(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Amount cannot be empty');
    }

    final value = double.tryParse(input);
    if (value == null) {
      return ValidationResult.error('Invalid number format');
    }

    if (value.isNaN || value.isInfinite) {
      return ValidationResult.error('Invalid amount value');
    }

    if (value < 0) {
      return ValidationResult.error('Amount cannot be negative');
    }

    if (value == 0) {
      return ValidationResult.error('Amount must be greater than zero');
    }

    // Max $1 billion per trade (safety limit)
    if (value > 1000000000) {
      return ValidationResult.error('Amount exceeds maximum limit');
    }

    // Check for excessive decimal places (max 8 for crypto)
    final parts = input.split('.');
    if (parts.length > 1 && parts[1].length > 8) {
      return ValidationResult.error('Maximum 8 decimal places allowed');
    }

    return ValidationResult.success(value);
  }

  /// Validate price input
  static ValidationResult validatePrice(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Price cannot be empty');
    }

    final value = double.tryParse(input);
    if (value == null) {
      return ValidationResult.error('Invalid price format');
    }

    if (value.isNaN || value.isInfinite) {
      return ValidationResult.error('Invalid price value');
    }

    if (value <= 0) {
      return ValidationResult.error('Price must be greater than zero');
    }

    // Max $10 million per unit (sanity check)
    if (value > 10000000) {
      return ValidationResult.error('Price exceeds reasonable limit');
    }

    return ValidationResult.success(value);
  }

  /// Validate percentage input (0-100)
  static ValidationResult validatePercentage(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Percentage cannot be empty');
    }

    final value = double.tryParse(input);
    if (value == null) {
      return ValidationResult.error('Invalid percentage format');
    }

    if (value < 0 || value > 100) {
      return ValidationResult.error('Percentage must be between 0 and 100');
    }

    return ValidationResult.success(value);
  }

  /// Validate integer input with bounds
  static ValidationResult validateInteger(
    String input, {
    int? min,
    int? max,
  }) {
    if (input.isEmpty) {
      return ValidationResult.error('Value cannot be empty');
    }

    final value = int.tryParse(input);
    if (value == null) {
      return ValidationResult.error('Must be a whole number');
    }

    if (min != null && value < min) {
      return ValidationResult.error('Minimum value is $min');
    }

    if (max != null && value > max) {
      return ValidationResult.error('Maximum value is $max');
    }

    return ValidationResult.success(value);
  }

  // ============================================
  // STRING VALIDATION
  // ============================================

  /// Validate trading symbol (e.g., BTCUSDT)
  static ValidationResult validateSymbol(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Symbol cannot be empty');
    }

    final trimmed = input.trim().toUpperCase();

    if (trimmed.length < 3 || trimmed.length > 20) {
      return ValidationResult.error('Symbol must be 3-20 characters');
    }

    // Only alphanumeric characters allowed
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(trimmed)) {
      return ValidationResult.error(
          'Symbol can only contain letters and numbers');
    }

    // Must contain at least one letter
    if (!RegExp(r'[A-Z]').hasMatch(trimmed)) {
      return ValidationResult.error('Symbol must contain at least one letter');
    }

    return ValidationResult.success(trimmed);
  }

  /// Validate strategy name
  static ValidationResult validateStrategyName(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Strategy name cannot be empty');
    }

    final trimmed = input.trim();

    if (trimmed.length < 3 || trimmed.length > 50) {
      return ValidationResult.error('Name must be 3-50 characters');
    }

    // Allow alphanumeric, spaces, hyphens, underscores
    if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(trimmed)) {
      return ValidationResult.error('Name contains invalid characters');
    }

    return ValidationResult.success(trimmed);
  }

  /// Sanitize user input (remove dangerous characters)
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[<>"' "'" r'`]'), '') // Remove HTML/script chars
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove control chars
        .trim();
  }

  /// Validate API key format
  static ValidationResult validateApiKey(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('API key cannot be empty');
    }

    final trimmed = input.trim();

    if (trimmed.length < 16 || trimmed.length > 500) {
      return ValidationResult.error('Invalid API key length');
    }

    // Only alphanumeric and common special chars
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(trimmed)) {
      return ValidationResult.error('API key contains invalid characters');
    }

    return ValidationResult.success(trimmed);
  }

  // ============================================
  // FINANCIAL VALIDATION
  // ============================================

  /// Validate balance (in cents to avoid float issues)
  static ValidationResult validateBalanceCents(int cents) {
    if (cents < 0) {
      return ValidationResult.error('Balance cannot be negative');
    }

    // Max $10 billion
    if (cents > 1000000000000) {
      return ValidationResult.error('Balance exceeds maximum limit');
    }

    return ValidationResult.success(cents);
  }

  /// Convert dollars to cents safely
  static int dollarsToCents(double dollars) {
    if (!SecureConfig.isValidAmount(dollars)) {
      throw ArgumentError('Invalid dollar amount: $dollars');
    }
    return (dollars * 100).round();
  }

  /// Convert cents to dollars safely
  static double centsToDollars(int cents) {
    if (cents < 0) {
      throw ArgumentError('Cents cannot be negative');
    }
    return cents / 100.0;
  }

  /// Validate order size against balance
  static ValidationResult validateOrderSize({
    required double amount,
    required double price,
    required int balanceCents,
  }) {
    final orderCostCents = dollarsToCents(amount * price);

    if (orderCostCents > balanceCents) {
      return ValidationResult.error('Insufficient balance for this order');
    }

    // Check if order is at least 1 cent
    if (orderCostCents < 1) {
      return ValidationResult.error('Order value too small (minimum \$0.01)');
    }

    return ValidationResult.success(orderCostCents);
  }

  // ============================================
  // DATE/TIME VALIDATION
  // ============================================

  /// Validate date is not in future
  static ValidationResult validatePastDate(DateTime date) {
    final now = DateTime.now().toUtc();
    if (date.isAfter(now)) {
      return ValidationResult.error('Date cannot be in the future');
    }
    return ValidationResult.success(date);
  }

  /// Validate date range
  static ValidationResult validateDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    if (start.isAfter(end)) {
      return ValidationResult.error('Start date must be before end date');
    }

    final duration = end.difference(start);
    if (duration.inDays > 365) {
      return ValidationResult.error('Date range cannot exceed 1 year');
    }

    return ValidationResult.success(duration);
  }

  // ============================================
  // SECURITY VALIDATION
  // ============================================

  /// Check for SQL injection patterns
  static bool containsSqlInjection(String input) {
    final patterns = [
      r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE)\b)",
      r"(--|;|\/\*|\*\/)",
      r"(\bOR\b.*=.*)",
      r"(\bAND\b.*=.*)",
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  /// Check for XSS patterns
  static bool containsXss(String input) {
    final patterns = [
      r"<script",
      r"javascript:",
      r"onerror=",
      r"onload=",
      r"<iframe",
    ];

    final lower = input.toLowerCase();
    for (final pattern in patterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Comprehensive security check
  static ValidationResult validateSecure(String input) {
    if (containsSqlInjection(input)) {
      return ValidationResult.error('Input contains invalid patterns');
    }

    if (containsXss(input)) {
      return ValidationResult.error('Input contains invalid patterns');
    }

    return ValidationResult.success(sanitize(input));
  }

  // ============================================
  // BATCH VALIDATION
  // ============================================

  /// Validate multiple fields at once
  static Map<String, ValidationResult> validateFields(
    Map<String, dynamic> fields,
  ) {
    final results = <String, ValidationResult>{};

    for (final entry in fields.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        results[key] = validateSecure(value);
      } else if (value is num) {
        results[key] = ValidationResult.success(value);
      }
    }

    return results;
  }

  /// Check if all validations passed
  static bool allValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }

  /// Get first error message
  static String? getFirstError(Map<String, ValidationResult> results) {
    for (final result in results.values) {
      if (!result.isValid) {
        return result.error;
      }
    }
    return null;
  }
}

/// Validation result wrapper
class ValidationResult {
  final bool isValid;
  final String? error;
  final dynamic value;

  ValidationResult.success(this.value)
      : isValid = true,
        error = null;

  ValidationResult.error(this.error)
      : isValid = false,
        value = null;

  T getValue<T>() {
    if (!isValid) {
      throw StateError('Cannot get value from invalid result: $error');
    }
    return value as T;
  }

  T? getValueOrNull<T>() {
    return isValid ? value as T : null;
  }
}

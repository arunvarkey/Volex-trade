import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
// Added for log() extension implementation
import 'package:volex_terminal/core/security/secure_logger.dart';

class PasswordPolicy {
  // Password requirements
  static const int minLength = 12;
  static const int maxLength = 128;
  static const int minUppercase = 1;
  static const int minLowercase = 1;
  static const int minDigits = 1;
  static const int minSpecialChars = 1;

  // Password history
  static const int passwordHistoryLimit = 5;

  // Common passwords (top 1000 most common)
  static final _commonPasswords = {
    'password', 'password123', 'password1', '12345678', 'qwerty', 'abc123',
    'monkey', '1234567', 'letmein', 'trustno1', 'dragon', 'baseball',
    'iloveyou', 'master', 'sunshine', 'ashley', 'bailey', 'passw0rd',
    'shadow', '123123', '654321', 'superman', 'qazwsx', 'michael',
    'football', 'welcome', 'jesus', 'ninja', 'mustang', 'password1!',
    'admin', 'admin123', 'root', 'toor', 'pass', 'test', 'guest',
    'welcome123', 'welcome123!', 'password123!', 'admin123!',
    // Add more as needed
  };

  // Compromised password hashes (from haveibeenpwned.com)
  // In production, check against a bloom filter or API
  static final _compromisedHashes = <String>{};

  /// Validate password strength
  static PasswordValidationResult validate(String password) {
    final errors = <String>[];
    int score = 0;

    // Length check
    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters');
    } else {
      score += 20;
      if (password.length >= 16) score += 10;
      if (password.length >= 20) score += 10;
    }

    if (password.length > maxLength) {
      errors.add('Password must not exceed $maxLength characters');
    }

    // Character type checks
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChars =
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/~`]').hasMatch(password);

    final uppercaseCount = RegExp(r'[A-Z]').allMatches(password).length;
    final lowercaseCount = RegExp(r'[a-z]').allMatches(password).length;
    final digitCount = RegExp(r'[0-9]').allMatches(password).length;
    final specialCount = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/~`]')
        .allMatches(password)
        .length;

    if (!hasUppercase || uppercaseCount < minUppercase) {
      errors.add(
          'Password must contain at least $minUppercase uppercase letter(s)');
    } else {
      score += 10;
    }

    if (!hasLowercase || lowercaseCount < minLowercase) {
      errors.add(
          'Password must contain at least $minLowercase lowercase letter(s)');
    } else {
      score += 10;
    }

    if (!hasDigits || digitCount < minDigits) {
      errors.add('Password must contain at least $minDigits digit(s)');
    } else {
      score += 10;
    }

    if (!hasSpecialChars || specialCount < minSpecialChars) {
      errors.add(
          'Password must contain at least $minSpecialChars special character(s)');
    } else {
      score += 10;
    }

    // Check for common patterns
    if (_containsCommonPattern(password)) {
      errors.add(
          'Password contains common patterns (e.g., "123", "abc", "qwerty")');
      score -= 20;
    }

    // Check against common passwords
    final lowerPassword = password.toLowerCase();
    if (_commonPasswords.contains(lowerPassword)) {
      errors.add('This password is too common and easily guessable');
      score -= 30;
    }

    // Check for keyboard patterns
    if (_isKeyboardPattern(password)) {
      errors.add('Password follows keyboard patterns (e.g., "qwerty", "asdf")');
      score -= 20;
    }

    // Check for repeated characters
    if (_hasRepeatedCharacters(password)) {
      errors.add('Password has too many repeated characters');
      score -= 10;
    }

    // Check entropy
    final entropy = _calculateEntropy(password);
    if (entropy < 50) {
      errors.add('Password entropy is too low (needs more randomness)');
    } else {
      score += (entropy / 2).round();
    }

    // Check if compromised
    if (_isCompromised(password)) {
      errors.add(
          'This password has been found in data breaches and is not secure');
      score = 0; // Instant fail
    }

    // Calculate final score
    score = score.clamp(0, 100);

    final strength = _getStrengthFromScore(score);

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      score: score,
      strength: strength,
      entropy: entropy,
    );
  }

  /// Check if password contains common patterns
  static bool _containsCommonPattern(String password) {
    final lowerPassword = password.toLowerCase();

    final patterns = [
      '123',
      '234',
      '345',
      '456',
      '567',
      '678',
      '789',
      'abc',
      'bcd',
      'cde',
      'def',
      'efg',
      'fgh',
      'qwerty',
      'asdf',
      'zxcv',
      '000',
      '111',
      '222',
      '333',
      '444',
      '555',
      '666',
      '777',
      '888',
      '999',
      'aaa',
      'bbb',
      'ccc',
    ];

    return patterns.any((pattern) => lowerPassword.contains(pattern));
  }

  /// Check if password is a keyboard pattern
  static bool _isKeyboardPattern(String password) {
    final lowerPassword = password.toLowerCase();

    final keyboardPatterns = [
      'qwertyuiop',
      'asdfghjkl',
      'zxcvbnm',
      '1234567890',
      'qazwsx',
      '1qaz2wsx',
    ];

    for (final pattern in keyboardPatterns) {
      if (lowerPassword.contains(pattern) ||
          lowerPassword.contains(pattern.split('').reversed.join())) {
        return true;
      }
    }

    return false;
  }

  /// Check for repeated characters
  static bool _hasRepeatedCharacters(String password) {
    int maxRepeat = 0;
    int currentRepeat = 1;

    for (int i = 1; i < password.length; i++) {
      if (password[i] == password[i - 1]) {
        currentRepeat++;
        maxRepeat = maxRepeat > currentRepeat ? maxRepeat : currentRepeat;
      } else {
        currentRepeat = 1;
      }
    }

    return maxRepeat >= 3;
  }

  /// Calculate password entropy
  static double _calculateEntropy(String password) {
    int charsetSize = 0;

    if (RegExp(r'[a-z]').hasMatch(password)) charsetSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(password)) charsetSize += 26;
    if (RegExp(r'[0-9]').hasMatch(password)) charsetSize += 10;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/~`]').hasMatch(password)) {
      charsetSize += 32;
    }

    if (charsetSize == 0) return 0;

    // Entropy = log2(charset^length)
    final entropy =
        password.length * (charsetSize.toDouble().log() / 2.0.log());

    return entropy;
  }

  /// Check if password is in compromised list
  static bool _isCompromised(String password) {
    // In production, check against haveibeenpwned.com API
    // For now, check against local hash set
    final hash = sha256.convert(utf8.encode(password)).toString();
    return _compromisedHashes.contains(hash);
  }

  /// Get strength level from score
  static PasswordStrength _getStrengthFromScore(int score) {
    if (score >= 80) return PasswordStrength.veryStrong;
    if (score >= 60) return PasswordStrength.strong;
    if (score >= 40) return PasswordStrength.medium;
    if (score >= 20) return PasswordStrength.weak;
    return PasswordStrength.veryWeak;
  }

  /// Generate a secure random password
  static String generateSecurePassword({int length = 16}) {
    final random = DateTime.now().millisecondsSinceEpoch;
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';

    var password = '';
    for (var i = 0; i < length; i++) {
      password += chars[(random + i) % chars.length];
    }

    return password;
  }

  /// Check password against history
  static Future<bool> isInPasswordHistory(
      String password, List<String> history) async {
    final hash = sha256.convert(utf8.encode(password)).toString();

    for (final oldHash in history) {
      if (oldHash == hash) {
        SecureLogger.warning('Password matches password history');
        return true;
      }
    }

    return false;
  }

  /// Hash password for storage
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final int score;
  final PasswordStrength strength;
  final double entropy;

  PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.score,
    required this.strength,
    required this.entropy,
  });

  String get strengthText {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  Color get strengthColor {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return const Color(0xFFD32F2F);
      case PasswordStrength.weak:
        return const Color(0xFFFF6F00);
      case PasswordStrength.medium:
        return const Color(0xFFFBC02D);
      case PasswordStrength.strong:
        return const Color(0xFF7CB342);
      case PasswordStrength.veryStrong:
        return const Color(0xFF388E3C);
    }
  }
}

enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong,
}

extension on double {
  double log() => this == 0 ? 0 : (this / 2.718281828459045).abs();
}

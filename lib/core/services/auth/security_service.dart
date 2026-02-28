import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

import '../../app_logger.dart';
import '../../security/secure_storage_service.dart';

/// Unified Security Service
///
/// Consolidates logic from:
/// - SecureAuthService (PIN, Auto-Lock)
/// - DeviceSecurityService (Integrity Checks)
/// - Engine AuthService (Biometrics)
class SecurityService extends ChangeNotifier {
  SecurityService();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _storage = SecureStorageService();

  // --- Auth State ---
  bool _isAuthenticated = false;
  bool _hasSetupPin = false;
  DateTime? _lastActivityTime;
  Timer? _autoLockTimer;

  // --- Security State ---
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Uint8List? _sessionKey; // Memory-safe key

  // --- Device Integrity State ---
  bool _isJailbroken = false;
  bool _isRealDevice = true;
  final List<String> _securityIssues = [];

  // --- Constants ---
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration autoLockTimeout = Duration(minutes: 5);
  static const String pinHashKey = 'secure_pin_hash';
  static const String pinSaltKey = 'secure_pin_salt';

  // --- Getters ---
  bool get isAuthenticated => _isAuthenticated;
  bool get hasSetupPin => _hasSetupPin;
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  Duration? get lockoutRemaining => _lockoutUntil?.difference(DateTime.now());
  bool get isDeviceSecure => !_isJailbroken && _securityIssues.isEmpty;
  List<String> get securityIssues => List.unmodifiable(_securityIssues);

  /// Initializes the security service.
  /// - Checks device integrity
  /// - Loads secure storage for PIN status
  /// - Starts auto-lock timer
  Future<void> initialize() async {
    await _storage.initialize();

    // 1. Device Integrity Check
    await _performSecurityCheck();

    // 2. PIN Status
    final pinHash = await _storage.read(key: pinHashKey);
    _hasSetupPin = pinHash != null;

    // 3. Auto-lock
    _startAutoLockTimer();

    AppLogger.info(
        'SecurityService initialized. Secure: $isDeviceSecure, HasPIN: $_hasSetupPin');
  }

  // ============================================
  // DEVICE INTEGRITY
  // ============================================

  Future<void> _performSecurityCheck() async {
    if (kIsWeb) return;

    try {
      _isJailbroken = await FlutterJailbreakDetection.jailbroken;

      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _isRealDevice = androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _isRealDevice = iosInfo.isPhysicalDevice;
      }

      _securityIssues.clear();
      if (_isJailbroken) _securityIssues.add('Device is jailbroken/rooted');
      if (!_isRealDevice) _securityIssues.add('Running on emulator');

      if (_securityIssues.isNotEmpty) {
        AppLogger.warning('Security Issues Detected: $_securityIssues');
      }
    } catch (e) {
      AppLogger.error('Security check failed', e);
      // Fail open or closed based on policy? For now, log and proceed.
    }
  }

  // ============================================
  // BIOMETRICS
  // ============================================

  Future<bool> get isBiometricAvailable async {
    if (kIsWeb) return false;
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access Volex Terminal',
  }) async {
    if (isLockedOut) return false;
    if (kIsWeb) return false;

    try {
      if (!await isBiometricAvailable) {
        AppLogger.warning('Biometrics not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        _onAuthSuccess();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Biometric auth failed', e);
      return false;
    }
  }

  // ============================================
  // PIN MANAGEMENT
  // ============================================

  Future<bool> setupPin(String pin) async {
    final error = _validatePin(pin);
    if (error != null) throw PinValidationException(error);

    try {
      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);

      await _storage.write(key: pinHashKey, value: hash);
      await _storage.write(key: pinSaltKey, value: salt);

      _hasSetupPin = true;
      notifyListeners();
      return true;
    } catch (e) {
      throw PinValidationException('PIN setup failed: $e');
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (isLockedOut) return false;

    try {
      final storedHash = await _storage.read(key: pinHashKey);
      final salt = await _storage.read(key: pinSaltKey);

      if (storedHash == null || salt == null) return false;

      final inputHash = _hashPin(pin, salt);
      if (_timingSafeEquals(storedHash, inputHash)) {
        _onAuthSuccess();
        return true;
      } else {
        _onAuthFailure();
        return false;
      }
    } catch (e) {
      _onAuthFailure();
      return false;
    }
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: pinHashKey);
    await _storage.delete(key: pinSaltKey);
    _hasSetupPin = false;
    _isAuthenticated = false;
    _clearSessionKey();
    notifyListeners();
  }

  // ============================================
  // SESSION & LOCKING
  // ============================================

  void lock() {
    _isAuthenticated = false;
    _clearSessionKey();
    notifyListeners();
  }

  void recordActivity() {
    _lastActivityTime = DateTime.now();
    _resetAutoLockTimer();
  }

  void _onAuthSuccess() {
    _isAuthenticated = true;
    _failedAttempts = 0;
    _lockoutUntil = null;
    _lastActivityTime = DateTime.now();
    _generateSessionKey();
    _resetAutoLockTimer();
    notifyListeners();
  }

  void _onAuthFailure() {
    _failedAttempts++;
    if (_failedAttempts >= maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(lockoutDuration);
      AppLogger.warning('Locked out for ${lockoutDuration.inMinutes} minutes');
    }
    notifyListeners();
  }

  void _startAutoLockTimer() => _resetAutoLockTimer();

  void _resetAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_lastActivityTime == null) return;
      if (DateTime.now().difference(_lastActivityTime!) > autoLockTimeout &&
          _isAuthenticated) {
        AppLogger.info('Auto-locking due to inactivity');
        lock();
      }
    });
  }

  // ============================================
  // HELPERS
  // ============================================

  String? _validatePin(String pin) {
    // Must be exactly 6 digits
    if (pin.length != 6) return 'PIN must be 6 digits';

    // Must be all numbers
    if (int.tryParse(pin) == null) return 'PIN must be numeric';

    // Reject weak PINs
    if (_isWeakPin(pin)) {
      return 'PIN is too weak (avoid sequences or repeated numbers)';
    }

    return null;
  }

  bool _isWeakPin(String pin) {
    // Reject common patterns
    final weakPins = [
      '000000',
      '111111',
      '222222',
      '333333',
      '444444',
      '555555',
      '666666',
      '777777',
      '888888',
      '999999',
      '123456',
      '654321',
      '012345',
      '543210',
    ];

    if (weakPins.contains(pin)) return true;

    // Reject sequential numbers
    bool isSequential = true;
    for (int i = 0; i < pin.length - 1; i++) {
      if (int.parse(pin[i + 1]) != int.parse(pin[i]) + 1) {
        isSequential = false;
        break;
      }
    }

    return isSequential;
  }

  String _generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString();
  }

  String _hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode(pin + salt)).toString();

  bool _timingSafeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  void _generateSessionKey() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionKey = Uint8List.fromList(
        utf8.encode(sha256.convert(utf8.encode(random)).toString()));
  }

  void _clearSessionKey() {
    if (_sessionKey != null) {
      _sessionKey!.fillRange(0, _sessionKey!.length, 0);
      _sessionKey = null;
    }
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    _clearSessionKey();
    super.dispose();
  }
}

class PinValidationException implements Exception {
  final String message;
  PinValidationException(this.message);
  @override
  String toString() => message;
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => message;
}

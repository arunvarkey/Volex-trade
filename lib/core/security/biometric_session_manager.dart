import 'package:local_auth/local_auth.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricSessionManager {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static DateTime? _lastAuthTime;
  static DateTime? _lastActivityTime;

  // Session timeouts
  static const _sessionTimeout = Duration(minutes: 15); // Re-auth after 15min
  static const _activityTimeout =
      Duration(minutes: 5); // Lock after 5min inactive
  static const _maxFailedAttempts = 3;

  static int _failedAttempts = 0;
  static DateTime? _lockoutUntil;

  /// Check if biometric authentication is available
  static Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      return canCheck && isDeviceSupported;
    } catch (e) {
      SecureLogger.error('Biometric check failed',
          data: {'error': e.toString()});
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      SecureLogger.error('Get available biometrics failed',
          data: {'error': e.toString()});
      return [];
    }
  }

  /// Check if re-authentication is needed
  static bool needsReAuth() {
    // Check if locked out
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remainingSeconds =
          _lockoutUntil!.difference(DateTime.now()).inSeconds;
      SecureLogger.warning('Account locked out',
          data: {'remaining_seconds': remainingSeconds});
      return true;
    }

    // Clear lockout if time has passed
    if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAttempts = 0;
      SecureLogger.info('Lockout period ended');
    }

    // Check session timeout
    if (_lastAuthTime == null) return true;

    final timeSinceAuth = DateTime.now().difference(_lastAuthTime!);
    if (timeSinceAuth > _sessionTimeout) {
      SecureLogger.info('Session timeout - re-auth required');
      return true;
    }

    // Check activity timeout
    if (_lastActivityTime != null) {
      final timeSinceActivity = DateTime.now().difference(_lastActivityTime!);
      if (timeSinceActivity > _activityTimeout) {
        SecureLogger.info('Inactivity timeout - re-auth required');
        return true;
      }
    }

    return false;
  }

  /// Authenticate with biometrics
  static Future<AuthenticationResult> authenticate({
    required String reason,
    bool sensitiveTransaction = false,
  }) async {
    // Check if locked out
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remainingSeconds =
          _lockoutUntil!.difference(DateTime.now()).inSeconds;
      return AuthenticationResult.lockedOut(remainingSeconds);
    }

    // Check if we need re-auth
    if (!needsReAuth() && !sensitiveTransaction) {
      _updateActivity();
      return AuthenticationResult.success();
    }

    // Check if biometrics are available
    if (!await canAuthenticate()) {
      SecureLogger.warning('Biometric authentication not available');
      return AuthenticationResult.notAvailable();
    }

    try {
      SecureLogger.info('Requesting biometric authentication',
          data: {'reason': reason});

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN fallback
          sensitiveTransaction: true,
        ),
      );

      if (authenticated) {
        // Reset failed attempts on success
        _failedAttempts = 0;
        _lastAuthTime = DateTime.now();
        _updateActivity();

        SecureLogger.info('Biometric authentication successful');
        return AuthenticationResult.success();
      } else {
        // Track failed attempt
        _failedAttempts++;

        SecureLogger.warning('Biometric authentication failed', data: {
          'failed_attempts': _failedAttempts,
        });

        // Lock out after max attempts
        if (_failedAttempts >= _maxFailedAttempts) {
          _lockoutUntil =
              DateTime.now().add(Duration(minutes: 5 * _failedAttempts));

          SecureLogger.critical('Maximum authentication attempts exceeded',
              data: {
                'lockout_until': _lockoutUntil!.toIso8601String(),
              });

          // Save lockout to persistent storage
          await _saveLockoutState();

          return AuthenticationResult.maxAttemptsExceeded(
            _lockoutUntil!.difference(DateTime.now()).inSeconds,
          );
        }

        return AuthenticationResult.failed(
            _maxFailedAttempts - _failedAttempts);
      }
    } catch (e) {
      SecureLogger.error('Authentication error', data: {'error': e.toString()});
      return AuthenticationResult.error(e.toString());
    }
  }

  /// Update last activity time (call this on user interactions)
  static void _updateActivity() {
    _lastActivityTime = DateTime.now();
  }

  /// Track user activity (call this frequently during app use)
  static void trackActivity() {
    _updateActivity();
  }

  /// Invalidate current session (logout)
  static Future<void> invalidateSession() async {
    _lastAuthTime = null;
    _lastActivityTime = null;
    _failedAttempts = 0;
    _lockoutUntil = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lockout_until');
    await prefs.remove('failed_attempts');

    SecureLogger.info('Session invalidated');
  }

  /// Save lockout state to persistent storage
  static Future<void> _saveLockoutState() async {
    final prefs = await SharedPreferences.getInstance();

    if (_lockoutUntil != null) {
      await prefs.setString('lockout_until', _lockoutUntil!.toIso8601String());
    }

    await prefs.setInt('failed_attempts', _failedAttempts);
  }

  /// Load lockout state from persistent storage
  static Future<void> loadLockoutState() async {
    final prefs = await SharedPreferences.getInstance();

    final lockoutStr = prefs.getString('lockout_until');
    if (lockoutStr != null) {
      _lockoutUntil = DateTime.parse(lockoutStr);

      // Clear if expired
      if (DateTime.now().isAfter(_lockoutUntil!)) {
        _lockoutUntil = null;
        await prefs.remove('lockout_until');
      }
    }

    _failedAttempts = prefs.getInt('failed_attempts') ?? 0;
  }

  /// Get session status
  static SessionStatus getSessionStatus() {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      return SessionStatus.lockedOut;
    }

    if (_lastAuthTime == null) {
      return SessionStatus.notAuthenticated;
    }

    if (needsReAuth()) {
      return SessionStatus.expired;
    }

    return SessionStatus.active;
  }

  /// Get time until session expires
  static Duration? getTimeUntilExpiry() {
    if (_lastAuthTime == null) return null;

    final expiry = _lastAuthTime!.add(_sessionTimeout);
    final remaining = expiry.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }
}

enum SessionStatus {
  active,
  expired,
  notAuthenticated,
  lockedOut,
}

class AuthenticationResult {
  final bool success;
  final String? errorMessage;
  final int? attemptsRemaining;
  final int? lockoutSeconds;
  final AuthenticationFailureReason? failureReason;

  AuthenticationResult._({
    required this.success,
    this.errorMessage,
    this.attemptsRemaining,
    this.lockoutSeconds,
    this.failureReason,
  });

  factory AuthenticationResult.success() {
    return AuthenticationResult._(success: true);
  }

  factory AuthenticationResult.failed(int attemptsRemaining) {
    return AuthenticationResult._(
      success: false,
      attemptsRemaining: attemptsRemaining,
      failureReason: AuthenticationFailureReason.userCancelled,
      errorMessage:
          'Authentication failed. $attemptsRemaining attempts remaining.',
    );
  }

  factory AuthenticationResult.maxAttemptsExceeded(int lockoutSeconds) {
    return AuthenticationResult._(
      success: false,
      lockoutSeconds: lockoutSeconds,
      failureReason: AuthenticationFailureReason.tooManyAttempts,
      errorMessage:
          'Too many failed attempts. Locked out for ${lockoutSeconds}s.',
    );
  }

  factory AuthenticationResult.lockedOut(int remainingSeconds) {
    return AuthenticationResult._(
      success: false,
      lockoutSeconds: remainingSeconds,
      failureReason: AuthenticationFailureReason.lockedOut,
      errorMessage: 'Account locked. Try again in ${remainingSeconds}s.',
    );
  }

  factory AuthenticationResult.notAvailable() {
    return AuthenticationResult._(
      success: false,
      failureReason: AuthenticationFailureReason.notAvailable,
      errorMessage: 'Biometric authentication not available on this device.',
    );
  }

  factory AuthenticationResult.error(String error) {
    return AuthenticationResult._(
      success: false,
      errorMessage: error,
      failureReason: AuthenticationFailureReason.systemError,
    );
  }
}

enum AuthenticationFailureReason {
  userCancelled,
  tooManyAttempts,
  lockedOut,
  notAvailable,
  systemError,
}

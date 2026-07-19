import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../app_logger.dart';

/// Secure storage service with encryption for sensitive data
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Secure storage for sensitive data (API keys, passwords)
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  // Regular storage for non-sensitive data
  SharedPreferences? _prefs;

  // Encryption key (generated per device, stored in secure storage)
  encrypt.Key? _encryptionKey;
  late encrypt.IV _iv;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize or retrieve encryption key
      await _initializeEncryption();

      _initialized = true;
      AppLogger.info('✅ SecureStorageService initialized');
    } catch (e) {
      AppLogger.error('❌ SecureStorageService initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _initializeEncryption() async {
    // Check if encryption key exists
    String? keyString = await _secureStorage.read(key: '_encryption_key');

    if (keyString == null) {
      // Generate new key
      _encryptionKey = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: '_encryption_key',
        value: base64.encode(_encryptionKey!.bytes),
      );
    } else {
      _encryptionKey = encrypt.Key(base64.decode(keyString));
    }

    // Generate IV (initialization vector) - stored in device
    String? ivString = await _secureStorage.read(key: '_encryption_iv');
    if (ivString == null) {
      _iv = encrypt.IV.fromSecureRandom(16);
      await _secureStorage.write(
        key: '_encryption_iv',
        value: base64.encode(_iv.bytes),
      );
    } else {
      _iv = encrypt.IV(base64.decode(ivString));
    }
  }

  // ============================================
  // SENSITIVE DATA (Encrypted in Secure Storage)
  // ============================================

  /// Store API key (ENCRYPTED)
  Future<void> setApiKey(String key) async {
    _ensureInitialized();

    // Validate input
    if (key.isEmpty || key.length > 500) {
      throw ArgumentError('Invalid API key format');
    }

    // Encrypt before storing
    final encrypted = _encrypt(key);
    await _secureStorage.write(key: 'api_key', value: encrypted);
  }

  /// Retrieve API key (DECRYPTED)
  Future<String?> getApiKey() async {
    _ensureInitialized();

    final encrypted = await _secureStorage.read(key: 'api_key');
    if (encrypted == null) return null;

    return _decrypt(encrypted);
  }

  /// Store API secret (ENCRYPTED)
  Future<void> setApiSecret(String secret) async {
    _ensureInitialized();

    if (secret.isEmpty || secret.length > 500) {
      throw ArgumentError('Invalid API secret format');
    }

    final encrypted = _encrypt(secret);
    await _secureStorage.write(key: 'api_secret', value: encrypted);
  }

  /// Retrieve API secret (DECRYPTED)
  Future<String?> getApiSecret() async {
    _ensureInitialized();

    final encrypted = await _secureStorage.read(key: 'api_secret');
    if (encrypted == null) return null;

    return _decrypt(encrypted);
  }

  /// Check if API credentials are configured
  Future<bool> hasApiCredentials() async {
    _ensureInitialized();

    final key = await getApiKey();
    final secret = await getApiSecret();

    return key != null && key.isNotEmpty && secret != null && secret.isNotEmpty;
  }

  /// Delete API credentials (for logout/reset)
  Future<void> deleteApiCredentials() async {
    _ensureInitialized();

    await _secureStorage.delete(key: 'api_key');
    await _secureStorage.delete(key: 'api_secret');
  }

  /// Store biometric preference
  Future<void> setBiometricEnabled(bool enabled) async {
    _ensureInitialized();
    await _secureStorage.write(
      key: 'biometric_enabled',
      value: enabled.toString(),
    );
  }

  /// Get biometric preference
  Future<bool> getBiometricEnabled() async {
    _ensureInitialized();

    final value = await _secureStorage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  // ============================================
  // GENERIC SECURE ACCESS (For generic usage)
  // ============================================

  /// Write a generic value securely (Encrypted)
  Future<void> write({required String key, required String value}) async {
    _ensureInitialized();
    final encrypted = _encrypt(value);
    await _secureStorage.write(key: key, value: encrypted);
  }

  /// Read a generic value securely (Decrypted)
  Future<String?> read({required String key}) async {
    _ensureInitialized();
    final encrypted = await _secureStorage.read(key: key);
    if (encrypted == null) return null;

    try {
      return _decrypt(encrypted);
    } catch (e) {
      // Fallback for unencrypted legacy values if any
      return encrypted;
    }
  }

  /// Delete a generic value
  Future<void> delete({required String key}) async {
    _ensureInitialized();
    await _secureStorage.delete(key: key);
  }

  // ============================================
  // NON-SENSITIVE DATA (Regular Storage)
  // ============================================

  /// Store execution mode
  Future<void> setExecutionMode(String mode) async {
    _ensureInitialized();

    // Validate
    if (!['paper', 'live'].contains(mode)) {
      throw ArgumentError('Invalid execution mode: $mode');
    }

    await _prefs!.setString('execution_mode', mode);
  }

  /// Get execution mode
  String getExecutionMode() {
    _ensureInitialized();
    return _prefs!.getString('execution_mode') ?? 'paper';
  }

  /// Store active symbol
  Future<void> setActiveSymbol(String symbol) async {
    _ensureInitialized();

    // Validate symbol format
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(symbol)) {
      throw ArgumentError('Invalid symbol format: $symbol');
    }

    await _prefs!.setString('active_symbol', symbol.toUpperCase());
  }

  /// Get active symbol
  String getActiveSymbol() {
    _ensureInitialized();
    return _prefs!.getString('active_symbol') ?? 'BTCUSDT';
  }

  /// Store paper balance (in cents to avoid float issues)
  Future<void> setPaperBalance(int cents) async {
    _ensureInitialized();

    if (cents < 0 || cents > 1000000000000) {
      // Max $10B
      throw ArgumentError('Invalid balance: $cents cents');
    }

    await _prefs!.setInt('paper_balance_cents', cents);
  }

  /// Get paper balance (in cents)
  int getPaperBalance() {
    _ensureInitialized();
    return _prefs!.getInt('paper_balance_cents') ?? 10000000; // Default $100k
  }

  /// Store enabled strategies
  Future<void> setEnabledStrategies(List<String> strategies) async {
    _ensureInitialized();

    // Validate each strategy ID
    for (final id in strategies) {
      if (id.isEmpty || id.length > 50) {
        throw ArgumentError('Invalid strategy ID: $id');
      }
    }

    await _prefs!.setStringList('enabled_strategies', strategies);
  }

  /// Get enabled strategies
  List<String> getEnabledStrategies() {
    _ensureInitialized();
    return _prefs!.getStringList('enabled_strategies') ?? [];
  }

  /// Store last login time (for session management)
  Future<void> setLastLoginTime(DateTime time) async {
    _ensureInitialized();
    await _prefs!.setString('last_login', time.toUtc().toIso8601String());
  }

  /// Get last login time
  DateTime? getLastLoginTime() {
    _ensureInitialized();

    final value = _prefs!.getString('last_login');
    if (value == null) return null;

    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }

  /// Check if session is still valid
  Future<bool> isSessionValid(Duration timeout) async {
    final lastLogin = getLastLoginTime();
    if (lastLogin == null) return false;

    final now = DateTime.now().toUtc();
    return now.difference(lastLogin) < timeout;
  }

  // ============================================
  // ENCRYPTION HELPERS
  // ============================================

  String _encrypt(String plaintext) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  String _decrypt(String ciphertext) {
    final parts = ciphertext.split(':');
    encrypt.IV ivToUse;
    String cipherTextToUse;

    if (parts.length == 2) {
      ivToUse = encrypt.IV(base64.decode(parts[0]));
      cipherTextToUse = parts[1];
    } else {
      // Fallback for old static IV
      ivToUse = _iv;
      cipherTextToUse = ciphertext;
    }

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
    );

    final decrypted = encrypter.decrypt64(cipherTextToUse, iv: ivToUse);
    return decrypted;
  }

  // ============================================
  // SECURITY FEATURES
  // ============================================

  /// Hash a value (for integrity checks, not encryption)
  String hash(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify hash matches
  bool verifyHash(String value, String expectedHash) {
    return hash(value) == expectedHash;
  }

  /// Clear all sensitive data (for logout)
  Future<void> clearSensitiveData() async {
    _ensureInitialized();

    await deleteApiCredentials();
    await _secureStorage.delete(key: 'biometric_enabled');

    AppLogger.info('🔒 Sensitive data cleared');
  }

  /// Clear ALL data (for app reset)
  Future<void> clearAll() async {
    _ensureInitialized();

    await _secureStorage.deleteAll();
    await _prefs!.clear();

    // Reinitialize encryption
    await _initializeEncryption();

    AppLogger.info('♻️ All data cleared');
  }

  // ============================================
  // HELPERS
  // ============================================

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SecureStorageService not initialized');
    }
  }

  // ============================================
  // LEGACY COMPATIBILITY (for existing code)
  // ============================================

  /// Save API credentials (legacy method)
  Future<void> saveApiCredentials(String apiKey, String apiSecret) async {
    await setApiKey(apiKey);
    await setApiSecret(apiSecret);
  }

  /// Get API credentials (legacy method)
  Future<Map<String, String>?> getApiCredentials() async {
    final key = await getApiKey();
    final secret = await getApiSecret();

    if (key == null || secret == null) return null;

    return {
      'apiKey': key,
      'apiSecret': secret,
    };
  }

  /// Clear credentials (legacy method)
  Future<void> clearCredentials() async {
    await deleteApiCredentials();
  }
}

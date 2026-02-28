// lib/core/services/secure_key_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:volex_terminal/core/app_logger.dart';

/// Securely manages critical user credentials (API Keys).
/// Uses Keychain (iOS) and EncryptedSharedPreferences (Android).
class SecureKeyStorage {
  static const _kOpenAiKey = 'openai_api_key';

  // Use a getter for storage to allow mocking or lazy init if needed
  final FlutterSecureStorage _storage;

  SecureKeyStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Stores the OpenAI API Key securely.
  /// Validates format (sk-...) before writing.
  Future<void> storeApiKey(String key) async {
    final cleanKey = key.trim();
    if (!RegExp(r'^sk-[a-zA-Z0-9-]{20,}$').hasMatch(cleanKey) &&
        !cleanKey.startsWith('sk-proj-')) {
      // Note: OpenAI added 'sk-proj-' prefix recently.
      // Weak validation is better than rejecting valid keys.
      // We'll rely on the API call to validate strictly.
      AppLogger.warning('Storing potential non-standard API key format.');
    }

    await _storage.write(key: _kOpenAiKey, value: cleanKey);
    AppLogger.info('API Key stored securely.');
  }

  /// Retrieves the stored API Key.
  Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: _kOpenAiKey);
    } catch (e) {
      AppLogger.error('Failed to read API Key from secure storage', e);
      return null;
    }
  }

  /// Deletes the stored API Key.
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _kOpenAiKey);
    AppLogger.info('API Key deleted from secure storage.');
  }

  /// Checks if an API Key is currently stored.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:typed_data';

class EncryptionKeyService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
  static const _keyName = 'hive_encryption_key';

  /// Get or generate 256-bit encryption key for Hive
  static Future<Uint8List> getEncryptionKey() async {
    // Try to read existing key
    final existingKey = await _secureStorage.read(key: _keyName);

    if (existingKey != null) {
      return base64Decode(existingKey);
    }

    // Generate new 256-bit key
    final key = Hive.generateSecureKey();

    // Store securely
    await _secureStorage.write(
      key: _keyName,
      value: base64Encode(key),
    );

    return Uint8List.fromList(key);
  }

  /// Delete encryption key (critical for "forget me" actions)
  static Future<void> deleteEncryptionKey() async {
    await _secureStorage.delete(key: _keyName);
  }
}

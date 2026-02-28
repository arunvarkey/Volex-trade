import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/core/app_config.dart';

class SecureTradingService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final _localAuth = LocalAuthentication();

  // Store API keys securely
  Future<void> storeApiKeys({
    required String apiKey,
    required String secretKey,
  }) async {
    AppLogger.info('🔐 Storing API keys...');

    // Verify keys first
    final verification = await _verifyApiKeys(apiKey, secretKey);

    if (verification.hasWithdrawalPermission) {
      throw SecurityException(
        '❌ CRITICAL SECURITY ERROR\n\n'
        'Your API key has WITHDRAWAL permission enabled!\n\n'
        'This means anyone with these keys can STEAL your funds.\n\n'
        'REQUIRED ACTIONS:\n'
        '1. Go to Binance.com\n'
        '2. API Management\n'
        '3. Edit this API key\n'
        '4. DISABLE "Enable Withdrawals"\n'
        '5. Come back and try again\n\n'
        'We cannot proceed until this is fixed.',
      );
    }

    if (!verification.canTrade) {
      throw SecurityException(
        'Your API key doesn\'t have trading permission.\n\n'
        'Please enable "Enable Spot & Margin Trading" in Binance.',
      );
    }

    // Store encrypted
    await _storage.write(key: 'binance_api_key', value: apiKey);
    await _storage.write(key: 'binance_secret_key', value: secretKey);

    AppLogger.info('✅ API keys stored securely');
  }

  // Verify API key permissions
  Future<ApiKeyVerification> _verifyApiKeys(
    String apiKey,
    String secretKey,
  ) async {
    try {
      AppLogger.info('🔍 Verifying API key permissions...');

      // Call Binance API
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final queryString = 'timestamp=$timestamp';
      final signature = _generateSignature(queryString, secretKey);

      final response = await http.get(
        Uri.parse(
            '${SecureConfig.binanceApiUrl}/api/v3/account?$queryString&signature=$signature'),
        headers: {'X-MBX-APIKEY': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final permissions =
            (data['permissions'] as List<dynamic>).cast<String>();

        AppLogger.info('✅ API key verified. Permissions: $permissions');

        return ApiKeyVerification(
          canTrade: permissions.contains('SPOT'),
          hasWithdrawalPermission: permissions
              .contains('WITHDRAWALS'), // Check for withdrawals safely
          isValid: true,
        );
      } else {
        final error = json.decode(response.body);
        throw Exception('Invalid API keys: ${error['msg']}');
      }
    } catch (e) {
      AppLogger.error('❌ Error verifying keys: $e');
      rethrow;
    }
  }

  // Execute trade with biometric auth
  Future<TradeResult> executeTrade({
    required String symbol,
    required String side,
    required double quantity,
    required double price,
  }) async {
    if (!SecureConfig.enableLiveTrading) {
      throw StateError('Live trading is disabled in this build');
    }

    AppLogger.info('🚀 Executing trade: $side $quantity $symbol @ $price');

    // 1. Check order value
    final orderValue = quantity * price;

    // 2. Require biometric for large orders
    if (orderValue > 100) {
      AppLogger.info('🔐 Order value > \$100, requiring biometric auth...');

      final canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) {
        return TradeResult.failed('Biometric authentication not available');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Authenticate to place \$${orderValue.toStringAsFixed(2)} order',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (!authenticated) {
        return TradeResult.failed('Authentication required');
      }

      AppLogger.info('✅ Biometric authentication successful');
    }

    // 3. Get keys from secure storage
    final apiKey = await _storage.read(key: 'binance_api_key');
    final secretKey = await _storage.read(key: 'binance_secret_key');

    if (apiKey == null || secretKey == null) {
      return TradeResult.failed('API keys not configured');
    }

    // 4. Create order parameters
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final params = {
      'symbol': symbol.replaceAll('/', ''),
      'side': side.toUpperCase(),
      'type': 'LIMIT',
      'timeInForce': 'GTC',
      'quantity': quantity.toString(),
      'price': price.toString(),
      'timestamp': timestamp.toString(),
    };

    // 5. Generate signature
    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final signature = _generateSignature(queryString, secretKey);
    params['signature'] = signature;

    // 6. Execute order
    try {
      AppLogger.info('📡 Sending order to Binance...');

      final response = await http.post(
        Uri.parse('${SecureConfig.binanceApiUrl}/api/v3/order'),
        headers: {
          'X-MBX-APIKEY': apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        AppLogger.info('✅ Order placed successfully: ${result['orderId']}');

        return TradeResult.success(
          orderId: result['orderId'].toString(),
          symbol: symbol,
          side: side,
          quantity: quantity,
          price: price,
        );
      } else {
        final error = json.decode(response.body);
        AppLogger.error('❌ Order failed: ${error['msg']}');
        return TradeResult.failed(error['msg']);
      }
    } catch (e) {
      AppLogger.error('❌ Network error: $e');
      return TradeResult.failed('Network error: $e');
    }
  }

  // Generate HMAC-SHA256 signature
  String _generateSignature(String data, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  // Check if API keys are configured
  Future<bool> hasApiKeys() async {
    final apiKey = await _storage.read(key: 'binance_api_key');
    return apiKey != null && apiKey.isNotEmpty;
  }

  // Remove API keys
  Future<void> removeApiKeys() async {
    await _storage.delete(key: 'binance_api_key');
    await _storage.delete(key: 'binance_secret_key');
    AppLogger.info('🗑️  API keys removed');
  }

  // Get masked API key (for display)
  Future<String?> getMaskedApiKey() async {
    final apiKey = await _storage.read(key: 'binance_api_key');
    if (apiKey == null || apiKey.isEmpty) return null;

    // Show first 8 and last 4 characters
    if (apiKey.length > 12) {
      return '${apiKey.substring(0, 8)}...${apiKey.substring(apiKey.length - 4)}';
    }
    return apiKey;
  }
}

class ApiKeyVerification {
  final bool canTrade;
  final bool hasWithdrawalPermission;
  final bool isValid;

  ApiKeyVerification({
    required this.canTrade,
    required this.hasWithdrawalPermission,
    required this.isValid,
  });
}

class TradeResult {
  final bool success;
  final String? orderId;
  final String? error;
  final String? symbol;
  final String? side;
  final double? quantity;
  final double? price;

  TradeResult.success({
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
  })  : success = true,
        error = null;

  TradeResult.failed(this.error)
      : success = false,
        orderId = null,
        symbol = null,
        side = null,
        quantity = null,
        price = null;
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => message;
}

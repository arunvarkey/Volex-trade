import 'dart:convert';
import 'dart:math';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:crypto/crypto.dart';

class TrafficObfuscation {
  static final _random = Random.secure();

  /// Add random padding to requests to prevent traffic analysis
  static Map<String, dynamic> obfuscateRequest(
    Map<String, dynamic> originalRequest,
  ) {
    try {
      final obfuscated = Map<String, dynamic>.from(originalRequest);

      // Add random padding
      obfuscated['_padding'] = _generateRandomPadding();

      // Add random delay token (suggests variable timing)
      obfuscated['_delay_token'] = _generateDelayToken();

      // Add decoy fields (look like real data but aren't used)
      obfuscated['_decoy_timestamp'] = DateTime.now()
          .add(Duration(seconds: _random.nextInt(3600)))
          .millisecondsSinceEpoch;

      obfuscated['_decoy_nonce'] = _generateRandomString(16);

      SecureLogger.debug('Request obfuscated');

      return obfuscated;
    } catch (e) {
      SecureLogger.error('Request obfuscation failed', data: {
        'error': e.toString(),
      });
      return originalRequest;
    }
  }

  /// Remove obfuscation from response
  static Map<String, dynamic> deobfuscateResponse(
    Map<String, dynamic> obfuscatedResponse,
  ) {
    final clean = Map<String, dynamic>.from(obfuscatedResponse);

    // Remove padding and decoy fields
    clean.remove('_padding');
    clean.remove('_delay_token');
    clean.remove('_decoy_timestamp');
    clean.remove('_decoy_nonce');

    return clean;
  }

  /// Generate random padding (variable size)
  static String _generateRandomPadding() {
    // Random padding between 10-100 bytes
    final length = 10 + _random.nextInt(90);
    return _generateRandomString(length);
  }

  /// Generate delay token (for timing obfuscation)
  static String _generateDelayToken() {
    final value = _random.nextInt(1000000);
    return sha256.convert(utf8.encode(value.toString())).toString();
  }

  /// Generate random string
  static String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  /// Add random delays between requests (timing obfuscation)
  static Future<void> addRandomDelay() async {
    // Random delay between 50-500ms
    final delayMs = 50 + _random.nextInt(450);
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  /// Generate decoy requests (traffic analysis prevention)
  static Future<void> generateDecoyTraffic({
    required Function(Map<String, dynamic>) sendRequest,
    int count = 3,
  }) async {
    try {
      SecureLogger.debug('Generating decoy traffic', data: {'count': count});

      for (var i = 0; i < count; i++) {
        // Create realistic-looking but meaningless request
        final decoyRequest = {
          'action': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'nonce': _generateRandomString(32),
          'data': _generateRandomPadding(),
        };

        // Send decoy request
        try {
          await sendRequest(decoyRequest);
        } catch (e) {
          // Ignore errors from decoy requests
        }

        // Random delay between decoys
        await addRandomDelay();
      }

      SecureLogger.debug('Decoy traffic generated');
    } catch (e) {
      SecureLogger.error('Decoy traffic generation failed', data: {
        'error': e.toString(),
      });
    }
  }

  /// Obfuscate request size pattern
  static String padToFixedSize(String data, int targetSize) {
    if (data.length >= targetSize) {
      return data;
    }

    final padding = targetSize - data.length;
    final paddingString = _generateRandomString(padding);

    return data + paddingString;
  }

  /// Split large requests into multiple smaller ones
  static List<Map<String, dynamic>> fragmentRequest(
    Map<String, dynamic> largeRequest, {
    int maxFragmentSize = 1024,
  }) {
    final fragments = <Map<String, dynamic>>[];
    final data = jsonEncode(largeRequest);

    if (data.length <= maxFragmentSize) {
      return [largeRequest];
    }

    // Generate fragment ID
    final fragmentId = _generateRandomString(16);

    var offset = 0;
    var fragmentIndex = 0;

    while (offset < data.length) {
      final end = (offset + maxFragmentSize < data.length)
          ? offset + maxFragmentSize
          : data.length;

      final fragmentData = data.substring(offset, end);

      fragments.add({
        '_fragment_id': fragmentId,
        '_fragment_index': fragmentIndex,
        '_fragment_total': (data.length / maxFragmentSize).ceil(),
        '_fragment_data': base64.encode(utf8.encode(fragmentData)),
      });

      offset = end;
      fragmentIndex++;
    }

    SecureLogger.debug('Request fragmented', data: {
      'fragments': fragments.length,
    });

    return fragments;
  }

  /// Reassemble fragmented request
  static Map<String, dynamic>? reassembleFragments(
    List<Map<String, dynamic>> fragments,
  ) {
    if (fragments.isEmpty) return null;

    // Sort by fragment index
    fragments.sort((a, b) =>
        (a['_fragment_index'] as int).compareTo(b['_fragment_index'] as int));

    // Verify all fragments present
    final total = fragments.first['_fragment_total'] as int;
    if (fragments.length != total) {
      SecureLogger.error('Missing fragments', data: {
        'expected': total,
        'received': fragments.length,
      });
      return null;
    }

    // Reassemble data
    final buffer = StringBuffer();
    for (final fragment in fragments) {
      final fragmentData = fragment['_fragment_data'] as String;
      buffer.write(utf8.decode(base64.decode(fragmentData)));
    }

    return jsonDecode(buffer.toString());
  }
}

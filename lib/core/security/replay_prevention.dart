import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReplayPrevention {
  static const _maxRequestAge = Duration(minutes: 5);
  static const _maxCachedRequests = 10000;

  // In-memory cache of recent request IDs
  static final Map<String, RequestMetadata> _requestCache = {};

  /// Check if request is a replay attack
  static Future<ReplayCheckResult> checkRequest({
    required String requestId,
    required int timestamp,
    required String signature,
  }) async {
    try {
      // 1. Check timestamp freshness
      final requestTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(requestTime);

      if (age > _maxRequestAge) {
        SecureLogger.warning('Request too old - possible replay', data: {
          'request_id': requestId,
          'age_seconds': age.inSeconds,
        });

        return ReplayCheckResult.replay(
          reason: 'Request timestamp too old',
          age: age,
        );
      }

      // 2. Check for future timestamp (clock tampering)
      if (age.isNegative && age.abs() > const Duration(seconds: 30)) {
        SecureLogger.critical('Future timestamp detected - clock tampering?',
            data: {
              'request_id': requestId,
              'offset_seconds': age.inSeconds,
            });

        return ReplayCheckResult.replay(
          reason: 'Request timestamp in future',
          age: age,
        );
      }

      // 3. Check request ID cache (most important check)
      if (_requestCache.containsKey(requestId)) {
        final cached = _requestCache[requestId]!;

        SecureLogger.critical('REPLAY ATTACK DETECTED!', data: {
          'request_id': requestId,
          'original_timestamp': cached.timestamp,
          'replay_timestamp': timestamp,
          'time_between': DateTime.fromMillisecondsSinceEpoch(timestamp)
              .difference(DateTime.fromMillisecondsSinceEpoch(cached.timestamp))
              .inSeconds,
        });

        return ReplayCheckResult.replay(
          reason: 'Request ID already used',
          originalRequest: cached,
        );
      }

      // 4. Check persistent storage (for long-term protection)
      final isPersisted = await _isRequestPersisted(requestId);
      if (isPersisted) {
        SecureLogger.critical('REPLAY ATTACK from persisted data!', data: {
          'request_id': requestId,
        });

        return ReplayCheckResult.replay(
          reason: 'Request ID found in persistent storage',
        );
      }

      // 5. Request is valid - cache it
      await _cacheRequest(requestId, timestamp, signature);

      return ReplayCheckResult.valid();
    } catch (e) {
      SecureLogger.error('Replay check failed', data: {'error': e.toString()});
      // Fail secure - treat as potential replay
      return ReplayCheckResult.replay(reason: 'Replay check error');
    }
  }

  /// Cache request in memory and persistent storage
  static Future<void> _cacheRequest(
    String requestId,
    int timestamp,
    String signature,
  ) async {
    // Add to memory cache
    _requestCache[requestId] = RequestMetadata(
      requestId: requestId,
      timestamp: timestamp,
      signature: signature,
      cachedAt: DateTime.now(),
    );

    // Cleanup old entries to prevent memory bloat
    if (_requestCache.length > _maxCachedRequests) {
      _cleanupCache();
    }

    // Persist to storage for long-term protection
    await _persistRequest(requestId, timestamp);
  }

  /// Clean up old entries from cache
  static void _cleanupCache() {
    final now = DateTime.now();
    final cutoff = now.subtract(_maxRequestAge);

    _requestCache.removeWhere((id, metadata) {
      return metadata.cachedAt.isBefore(cutoff);
    });

    SecureLogger.debug('Request cache cleaned', data: {
      'remaining': _requestCache.length,
    });
  }

  /// Check if request exists in persistent storage
  static Future<bool> _isRequestPersisted(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'request_$requestId';
      return prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  /// Persist request ID to storage
  static Future<void> _persistRequest(String requestId, int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'request_$requestId';

      await prefs.setString(
          key,
          jsonEncode({
            'timestamp': timestamp,
            'cached_at': DateTime.now().millisecondsSinceEpoch,
          }));

      // Also maintain index of all request IDs for cleanup
      final allRequests = prefs.getStringList('all_request_ids') ?? [];
      allRequests.add(requestId);

      // Keep only recent ones
      if (allRequests.length > 1000) {
        await _cleanupPersistedRequests(allRequests.take(500).toList());
      }

      await prefs.setStringList('all_request_ids', allRequests);
    } catch (e) {
      SecureLogger.error('Failed to persist request',
          data: {'error': e.toString()});
    }
  }

  /// Clean up old persisted requests
  static Future<void> _cleanupPersistedRequests(List<String> idsToKeep) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (final key in allKeys) {
        if (key.startsWith('request_')) {
          final requestId = key.substring(8); // Remove 'request_' prefix

          if (!idsToKeep.contains(requestId)) {
            await prefs.remove(key);
          }
        }
      }

      await prefs.setStringList('all_request_ids', idsToKeep);

      SecureLogger.info('Persisted requests cleaned', data: {
        'kept': idsToKeep.length,
      });
    } catch (e) {
      SecureLogger.error('Cleanup failed', data: {'error': e.toString()});
    }
  }

  /// Clear all replay prevention data (for testing/reset)
  static Future<void> clearAll() async {
    _requestCache.clear();

    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    for (final key in allKeys) {
      if (key.startsWith('request_')) {
        await prefs.remove(key);
      }
    }

    await prefs.remove('all_request_ids');

    SecureLogger.info('Replay prevention data cleared');
  }

  /// Get statistics about cached requests
  static ReplayPreventionStats getStats() {
    final now = DateTime.now();

    final recentRequests = _requestCache.values.where((metadata) {
      return now.difference(metadata.cachedAt) < const Duration(minutes: 1);
    }).length;

    return ReplayPreventionStats(
      totalCached: _requestCache.length,
      recentRequests: recentRequests,
    );
  }
}

class RequestMetadata {
  final String requestId;
  final int timestamp;
  final String signature;
  final DateTime cachedAt;

  RequestMetadata({
    required this.requestId,
    required this.timestamp,
    required this.signature,
    required this.cachedAt,
  });
}

class ReplayCheckResult {
  final bool isValid;
  final String? reason;
  final Duration? age;
  final RequestMetadata? originalRequest;

  ReplayCheckResult._({
    required this.isValid,
    this.reason,
    this.age,
    this.originalRequest,
  });

  factory ReplayCheckResult.valid() {
    return ReplayCheckResult._(isValid: true);
  }

  factory ReplayCheckResult.replay({
    required String reason,
    Duration? age,
    RequestMetadata? originalRequest,
  }) {
    return ReplayCheckResult._(
      isValid: false,
      reason: reason,
      age: age,
      originalRequest: originalRequest,
    );
  }

  bool get isReplay => !isValid;
}

class ReplayPreventionStats {
  final int totalCached;
  final int recentRequests;

  ReplayPreventionStats({
    required this.totalCached,
    required this.recentRequests,
  });

  Map<String, dynamic> toJson() => {
        'total_cached': totalCached,
        'recent_requests': recentRequests,
      };
}

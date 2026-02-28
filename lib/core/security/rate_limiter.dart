import 'package:volex_terminal/core/security/secure_logger.dart';

class RateLimiter {
  // Endpoint-specific limits
  final Map<String, EndpointConfig> _endpointConfigs = {};

  // Request history per endpoint
  final Map<String, List<DateTime>> _requestHistory = {};

  // Backoff state per endpoint
  final Map<String, BackoffState> _backoffState = {};

  // Global rate limit
  final GlobalRateLimit _globalLimit;

  RateLimiter({
    int globalMaxRequests = 100,
    Duration globalWindow = const Duration(minutes: 1),
  }) : _globalLimit = GlobalRateLimit(
          maxRequests: globalMaxRequests,
          window: globalWindow,
        );

  /// Configure rate limit for specific endpoint
  void configureEndpoint(
    String endpoint, {
    required int maxRequests,
    required Duration window,
    int burstSize = 5,
    bool enableBackoff = true,
  }) {
    _endpointConfigs[endpoint] = EndpointConfig(
      maxRequests: maxRequests,
      window: window,
      burstSize: burstSize,
      enableBackoff: enableBackoff,
    );

    SecureLogger.debug('Endpoint configured', data: {
      'endpoint': endpoint,
      'max_requests': maxRequests,
      'window': window.inSeconds,
    });
  }

  /// Check if request is allowed
  Future<RateLimitResult> checkLimit(String endpoint) async {
    // Check global limit first
    if (!_globalLimit.check()) {
      SecureLogger.warning('Global rate limit exceeded');
      return RateLimitResult.blocked(
        reason: 'Global rate limit exceeded',
        retryAfter: _globalLimit.getRetryAfter(),
      );
    }

    // Get endpoint config
    final config = _endpointConfigs[endpoint];
    if (config == null) {
      // No limit configured - allow
      return RateLimitResult.allowed();
    }

    // Check if in backoff period
    if (config.enableBackoff) {
      final backoff = _backoffState[endpoint];
      if (backoff != null && backoff.isActive) {
        final retryAfter = backoff.getRetryAfter();

        SecureLogger.warning('Request in backoff period', data: {
          'endpoint': endpoint,
          'retry_after': retryAfter.inSeconds,
        });

        return RateLimitResult.blocked(
          reason: 'Rate limit exceeded - exponential backoff active',
          retryAfter: retryAfter,
        );
      }
    }

    // Clean old requests
    _cleanupOldRequests(endpoint, config.window);

    // Check limit
    final history = _requestHistory[endpoint] ?? [];

    if (history.length >= config.maxRequests) {
      // Limit exceeded
      if (config.enableBackoff) {
        _activateBackoff(endpoint);
      }

      final oldestRequest = history.first;
      final retryAfter =
          config.window - DateTime.now().difference(oldestRequest);

      SecureLogger.warning('Endpoint rate limit exceeded', data: {
        'endpoint': endpoint,
        'requests': history.length,
        'limit': config.maxRequests,
        'retry_after': retryAfter.inSeconds,
      });

      return RateLimitResult.blocked(
        reason: 'Rate limit exceeded for $endpoint',
        retryAfter: retryAfter,
      );
    }

    // Check burst size
    final recentRequests = history.where((time) {
      return DateTime.now().difference(time) < const Duration(seconds: 1);
    }).length;

    if (recentRequests >= config.burstSize) {
      SecureLogger.warning('Burst limit exceeded', data: {
        'endpoint': endpoint,
        'burst': recentRequests,
        'limit': config.burstSize,
      });

      return RateLimitResult.blocked(
        reason: 'Burst limit exceeded',
        retryAfter: const Duration(seconds: 1),
      );
    }

    // Allow request
    _recordRequest(endpoint);
    _globalLimit.recordRequest();

    return RateLimitResult.allowed();
  }

  /// Record a request
  void _recordRequest(String endpoint) {
    _requestHistory[endpoint] ??= [];
    _requestHistory[endpoint]!.add(DateTime.now());
  }

  /// Clean up old requests outside the window
  void _cleanupOldRequests(String endpoint, Duration window) {
    final history = _requestHistory[endpoint];
    if (history == null) return;

    final cutoff = DateTime.now().subtract(window);
    history.removeWhere((time) => time.isBefore(cutoff));
  }

  /// Activate exponential backoff
  void _activateBackoff(String endpoint) {
    final currentBackoff = _backoffState[endpoint];

    if (currentBackoff == null) {
      _backoffState[endpoint] = BackoffState(
        endpoint: endpoint,
        backoffDuration: const Duration(seconds: 30),
      );
    } else {
      // Double the backoff duration (exponential)
      final newDuration = currentBackoff.backoffDuration * 2;

      // Cap at 30 minutes
      final cappedDuration = newDuration > const Duration(minutes: 30)
          ? const Duration(minutes: 30)
          : newDuration;

      _backoffState[endpoint] = BackoffState(
        endpoint: endpoint,
        backoffDuration: cappedDuration,
        consecutiveViolations: currentBackoff.consecutiveViolations + 1,
      );

      SecureLogger.warning('Exponential backoff activated', data: {
        'endpoint': endpoint,
        'backoff_seconds': cappedDuration.inSeconds,
        'violations': currentBackoff.consecutiveViolations + 1,
      });
    }
  }

  /// Reset backoff for endpoint
  void resetBackoff(String endpoint) {
    _backoffState.remove(endpoint);
    SecureLogger.info('Backoff reset', data: {'endpoint': endpoint});
  }

  /// Get current rate limit status
  RateLimitStatus getStatus(String endpoint) {
    final config = _endpointConfigs[endpoint];
    if (config == null) {
      return RateLimitStatus(
        endpoint: endpoint,
        requestsMade: 0,
        requestsAllowed: -1,
        resetAt: null,
      );
    }

    _cleanupOldRequests(endpoint, config.window);
    final history = _requestHistory[endpoint] ?? [];
    final resetAt =
        history.isEmpty ? DateTime.now() : history.first.add(config.window);

    return RateLimitStatus(
      endpoint: endpoint,
      requestsMade: history.length,
      requestsAllowed: config.maxRequests,
      resetAt: resetAt,
    );
  }

  /// Clear all rate limit data (for testing)
  void clear() {
    _requestHistory.clear();
    _backoffState.clear();
    _globalLimit.clear();
  }
}

class EndpointConfig {
  final int maxRequests;
  final Duration window;
  final int burstSize;
  final bool enableBackoff;

  EndpointConfig({
    required this.maxRequests,
    required this.window,
    required this.burstSize,
    required this.enableBackoff,
  });
}

class BackoffState {
  final String endpoint;
  final Duration backoffDuration;
  final DateTime activatedAt;
  final int consecutiveViolations;

  BackoffState({
    required this.endpoint,
    required this.backoffDuration,
    this.consecutiveViolations = 1,
  }) : activatedAt = DateTime.now();

  bool get isActive {
    final elapsed = DateTime.now().difference(activatedAt);
    return elapsed < backoffDuration;
  }

  Duration getRetryAfter() {
    final elapsed = DateTime.now().difference(activatedAt);
    final remaining = backoffDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

class GlobalRateLimit {
  final int maxRequests;
  final Duration window;
  final List<DateTime> _requests = [];

  GlobalRateLimit({
    required this.maxRequests,
    required this.window,
  });

  bool check() {
    _cleanup();
    return _requests.length < maxRequests;
  }

  void recordRequest() {
    _requests.add(DateTime.now());
    _cleanup();
  }

  void _cleanup() {
    final cutoff = DateTime.now().subtract(window);
    _requests.removeWhere((time) => time.isBefore(cutoff));
  }

  Duration getRetryAfter() {
    if (_requests.isEmpty) return Duration.zero;

    final oldest = _requests.first;
    final resetAt = oldest.add(window);
    final remaining = resetAt.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  void clear() {
    _requests.clear();
  }
}

class RateLimitResult {
  final bool allowed;
  final String? reason;
  final Duration? retryAfter;

  RateLimitResult._({
    required this.allowed,
    this.reason,
    this.retryAfter,
  });

  factory RateLimitResult.allowed() {
    return RateLimitResult._(allowed: true);
  }

  factory RateLimitResult.blocked({
    required String reason,
    required Duration retryAfter,
  }) {
    return RateLimitResult._(
      allowed: false,
      reason: reason,
      retryAfter: retryAfter,
    );
  }
}

class RateLimitStatus {
  final String endpoint;
  final int requestsMade;
  final int requestsAllowed;
  final DateTime? resetAt;

  RateLimitStatus({
    required this.endpoint,
    required this.requestsMade,
    required this.requestsAllowed,
    this.resetAt,
  });

  int get requestsRemaining => requestsAllowed == -1
      ? -1
      : (requestsAllowed - requestsMade).clamp(0, requestsAllowed);

  bool get isLimited =>
      requestsAllowed != -1 && requestsMade >= requestsAllowed;

  Map<String, dynamic> toJson() => {
        'endpoint': endpoint,
        'requests_made': requestsMade,
        'requests_allowed': requestsAllowed,
        'requests_remaining': requestsRemaining,
        'is_limited': isLimited,
        'reset_at': resetAt?.toIso8601String(),
      };
}

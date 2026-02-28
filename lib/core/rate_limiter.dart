import 'dart:collection';

/// Rate limiter to prevent API abuse
/// Implements token bucket algorithm
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Queue<DateTime> _requests = Queue();

  RateLimiter({
    required this.maxRequests,
    required this.window,
  });

  /// Throttle requests to stay within rate limit
  /// Waits if necessary before allowing request
  Future<void> throttle() async {
    final now = DateTime.now();

    // Remove requests outside the time window
    _requests.removeWhere((time) => now.difference(time) > window);

    // If at limit, wait until oldest request expires
    if (_requests.length >= maxRequests) {
      final oldestRequest = _requests.first;
      final waitTime = window - now.difference(oldestRequest);
      if (waitTime.inMilliseconds > 0) {
        await Future.delayed(waitTime);
      }
      _requests.removeFirst();
    }

    _requests.add(now);
  }

  /// Check if we can make a request without waiting
  bool canMakeRequest() {
    final now = DateTime.now();
    _requests.removeWhere((time) => now.difference(time) > window);
    return _requests.length < maxRequests;
  }

  /// Reset the rate limiter
  void reset() {
    _requests.clear();
  }
}

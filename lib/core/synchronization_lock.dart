import 'dart:async';

/// A simple mutex/lock to prevent race conditions in async operations.
class SynchronizationLock {
  Completer<void>? _completer;

  /// Ensures that only one async operation runs at a time.
  Future<T> synchronized<T>(Future<T> Function() operation) async {
    while (_completer != null) {
      await _completer!.future;
    }

    _completer = Completer<void>();

    try {
      return await operation();
    } finally {
      final completer = _completer;
      _completer = null;
      completer?.complete();
    }
  }
}

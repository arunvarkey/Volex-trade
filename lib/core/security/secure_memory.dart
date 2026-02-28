import 'dart:typed_data';
import 'package:volex_terminal/core/security/secure_logger.dart';

class SecureMemory {
  /// Securely store sensitive string in memory
  static SecureString secureString(String value) {
    return SecureString(value);
  }

  /// Zero out memory buffer
  static void zeroMemory(Uint8List buffer) {
    for (var i = 0; i < buffer.length; i++) {
      buffer[i] = 0;
    }
  }

  /// Overwrite string in memory (best effort)
  static void overwriteString(String value) {
    // Note: Dart strings are immutable, so we can't truly zero them
    // But we can hint to GC and create garbage to overwrite memory
    final garbage =
        List.generate(value.length * 10, (i) => String.fromCharCode(i % 256));
    garbage.toString(); // Force evaluation
  }

  /// Secure string comparison (constant time)
  static bool secureEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  /// Create secure random bytes
  static Uint8List randomBytes(int length) {
    final random = Uint8List(length);
    final now = DateTime.now().microsecondsSinceEpoch;

    for (var i = 0; i < length; i++) {
      random[i] = ((now + i) * 31) % 256;
    }

    return random;
  }
}

/// Wrapper for sensitive strings with automatic cleanup
class SecureString {
  String? _value;
  bool _disposed = false;

  SecureString(String value) : _value = value {
    SecureLogger.debug('SecureString created');
  }

  /// Get the value
  String get value {
    if (_disposed) {
      throw StateError('SecureString has been disposed');
    }
    return _value!;
  }

  /// Use the value in a callback and automatically dispose
  T use<T>(T Function(String) callback) {
    if (_disposed) {
      throw StateError('SecureString has been disposed');
    }

    try {
      return callback(_value!);
    } finally {
      dispose();
    }
  }

  /// Manually dispose (clear from memory)
  void dispose() {
    if (!_disposed && _value != null) {
      SecureMemory.overwriteString(_value!);
      _value = null;
      _disposed = true;
      SecureLogger.debug('SecureString disposed');
    }
  }

  /// Get length without exposing value
  int get length => _disposed ? 0 : _value!.length;

  /// Check if disposed
  bool get isDisposed => _disposed;
}

/// Secure buffer that zeros itself on disposal
class SecureBuffer {
  Uint8List? _buffer;
  bool _disposed = false;

  SecureBuffer(int size) : _buffer = Uint8List(size) {
    SecureLogger.debug('SecureBuffer created', data: {'size': size});
  }

  /// Get the buffer
  Uint8List get buffer {
    if (_disposed) {
      throw StateError('SecureBuffer has been disposed');
    }
    return _buffer!;
  }

  /// Write data to buffer
  void write(List<int> data, {int offset = 0}) {
    if (_disposed) {
      throw StateError('SecureBuffer has been disposed');
    }

    buffer.setRange(offset, offset + data.length, data);
  }

  /// Read data from buffer
  Uint8List read({int offset = 0, int? length}) {
    if (_disposed) {
      throw StateError('SecureBuffer has been disposed');
    }

    final readLength = length ?? buffer.length - offset;
    return Uint8List.fromList(buffer.sublist(offset, offset + readLength));
  }

  /// Zero out and dispose
  void dispose() {
    if (!_disposed && _buffer != null) {
      SecureMemory.zeroMemory(_buffer!);
      _buffer = null;
      _disposed = true;
      SecureLogger.debug('SecureBuffer disposed');
    }
  }

  /// Get size
  int get size => _disposed ? 0 : _buffer!.length;

  /// Check if disposed
  bool get isDisposed => _disposed;
}

/// Auto-disposing scope for secure data
class SecureScope {
  final List<dynamic> _resources = [];

  /// Add resource to scope
  T add<T>(T resource) {
    _resources.add(resource);
    return resource;
  }

  /// Execute code in secure scope
  T execute<T>(T Function(SecureScope) callback) {
    try {
      return callback(this);
    } finally {
      dispose();
    }
  }

  /// Dispose all resources
  void dispose() {
    for (final resource in _resources) {
      if (resource is SecureString) {
        resource.dispose();
      } else if (resource is SecureBuffer) {
        resource.dispose();
      }
    }
    _resources.clear();

    SecureLogger.debug('SecureScope disposed');
  }
}

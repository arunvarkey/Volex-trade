import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/app_logger.dart';

/// Simulates a remote cloud backend (like Firebase/AWS S3 bucket/API)
/// In a real app, this would make HTTP calls.
/// For the prototype, it uses an in-memory map delayed by Future.delayed.
class CloudStorageService {
  static CloudStorageService? _instance;
  factory CloudStorageService() =>
      _instance ??= CloudStorageService._internal();
  CloudStorageService._internal();

  // "Remote" Database
  // Key -> { 'data': dynamic, 'version': int, 'timestamp': String }
  final Map<String, Map<String, dynamic>> _cloudStore = {};

  // Simulate network conditions
  Duration _latency = const Duration(milliseconds: 300);
  final bool _simulateErrors = false; // Toggle for testing chaos
  final Random _rng = Random();

  @visibleForTesting
  void reset({bool zeroLatency = true}) {
    _cloudStore.clear();
    if (zeroLatency) {
      _latency = Duration.zero;
    }
  }

  /// Uploads data to the cloud.
  /// Returns existing remote version if conflict, or null if success.
  /// Simple "Last Writer Wins" or explicit version check can be added here.
  /// For Volex Day 35, we'll implement a simple put.
  Future<void> upload(String key, Map<String, dynamic> data) async {
    await Future.delayed(_latency);
    if (_simulateErrors && _rng.nextDouble() < 0.1) {
      throw Exception("Network Error: Upload failed");
    }

    // Wrap in metadata
    _cloudStore[key] = {
      'data': data,
      'version': (_cloudStore[key]?['version'] ?? 0) + 1,
      'timestamp': DateTime.now().toIso8601String(),
    };

    AppLogger.debug("CLOUD: Uploaded $key (v${_cloudStore[key]!['version']})");
  }

  /// Downloads data from the cloud.
  /// Returns null if key doesn't exist.
  Future<Map<String, dynamic>?> download(String key) async {
    await Future.delayed(_latency);
    if (_simulateErrors && _rng.nextDouble() < 0.1) {
      throw Exception("Network Error: Download failed");
    }

    if (!_cloudStore.containsKey(key)) return null;

    return _cloudStore[key]!['data']; // Unwrapping metadata for the client
  }

  /// Gets metadata (version, timestamp) for conflict resolution
  Future<Map<String, dynamic>?> getMetadata(String key) async {
    await Future.delayed(_latency);
    if (!_cloudStore.containsKey(key)) return null;

    return {
      'version': _cloudStore[key]!['version'],
      'timestamp': _cloudStore[key]!['timestamp'],
    };
  }

  // Debug methods
  void clear() => _cloudStore.clear();
  int get count => _cloudStore.length;
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/security/secure_storage_service.dart';
import '../core/app_logger.dart';

/// Service to sync critical risk state (Daily Loss, Lockouts) to the cloud.
/// Ensures that uninstalling/clearing app data does not reset safety limits.
class RiskStateSyncService {
  static final RiskStateSyncService instance = RiskStateSyncService._();
  RiskStateSyncService._();

  final SecureStorageService _storage = SecureStorageService();
  DocumentReference? _docRef;
  bool _isInitialized = false;

  /// Initialize sync with unique ID based on API Key
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // We use the hash of the API Key as the unique identifier for risk state.
      // This persists across installs as long as the user uses the same Binance account.
      // If they switch keys, they get fresh risk state (which is logical).
      final apiKey = await _storage.getApiKey();

      if (apiKey != null && apiKey.isNotEmpty) {
        final docId = _storage.hash(apiKey);
        _docRef =
            FirebaseFirestore.instance.collection('risk_states').doc(docId);
        _isInitialized = true;
        AppLogger.info(
            'RiskStateSync initialized for ID: ${docId.substring(0, 8)}...');
      } else {
        AppLogger.warning('RiskStateSync skipped: No API Key found.');
      }
    } catch (e) {
      AppLogger.error('RiskStateSync initialization failed', e);
    }
  }

  /// Push local state to cloud
  Future<void> pushState({
    required double currentDailyLoss,
    required bool isEmergencyStopActive,
    DateTime? lockoutUntil,
  }) async {
    if (!_isInitialized || _docRef == null) return;

    try {
      await _docRef!.set({
        'currentDailyLoss': currentDailyLoss,
        'isEmergencyStopActive': isEmergencyStopActive,
        'lockoutUntil': lockoutUntil?.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      }, SetOptions(merge: true));
      // debugPrint('☁️ Risk state synced to cloud.');
    } catch (e) {
      AppLogger.error('Failed to sync risk state', e);
    }
  }

  /// Pull remote state (e.g., on startup)
  Future<RemoteRiskState?> pullState() async {
    if (!_isInitialized || _docRef == null) return null;

    try {
      final snapshot = await _docRef!.get();
      if (!snapshot.exists || snapshot.data() == null) return null;

      final data = snapshot.data() as Map<String, dynamic>;
      return RemoteRiskState(
        currentDailyLoss: (data['currentDailyLoss'] as num?)?.toDouble() ?? 0.0,
        isEmergencyStopActive: data['isEmergencyStopActive'] as bool? ?? false,
        lockoutUntil: data['lockoutUntil'] != null
            ? DateTime.tryParse(data['lockoutUntil'] as String)
            : null,
      );
    } catch (e) {
      AppLogger.error('Failed to pull risk state', e);
      return null;
    }
  }
}

class RemoteRiskState {
  final double currentDailyLoss;
  final bool isEmergencyStopActive;
  final DateTime? lockoutUntil;

  RemoteRiskState({
    required this.currentDailyLoss,
    required this.isEmergencyStopActive,
    this.lockoutUntil,
  });
}

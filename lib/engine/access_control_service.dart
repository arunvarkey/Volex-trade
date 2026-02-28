import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/app_logger.dart';

enum UserRole {
  operator, // Full System Control (Architect)
  trader, // Restricted Safe Mode (External User)
}

class AccessControlService {
  static final AccessControlService _instance =
      AccessControlService._internal();
  factory AccessControlService() => _instance;
  AccessControlService._internal();

  @visibleForTesting
  void reset() {
    _currentRole = UserRole.operator;
  }

  UserRole _currentRole = UserRole.operator; // Default to Operator for now

  final StreamController<UserRole> _roleController =
      StreamController<UserRole>.broadcast();
  Stream<UserRole> get roleStream => _roleController.stream;

  UserRole get currentRole => _currentRole;

  void setRole(UserRole role) {
    _currentRole = role;
    _roleController.add(role);
    AppLogger.info(
        "SECURITY: User role switched to ${role.name.toUpperCase()}");
  }

  // Mock Identity
  String get currentUserId => "mock_user_1";

  // --- Permission Queries ---

  /// Can the user authorize new strategies or change their config?
  bool get canAuthorizeStrategies => _currentRole == UserRole.operator;

  /// Can the user change global risk configurations?
  bool get canConfigureRisk => _currentRole == UserRole.operator;

  /// Can the user arm/disarm the Kill Switch?
  bool get canManageKillSwitch => _currentRole == UserRole.operator;

  /// Can the user see detailed internal logs?
  bool get canViewInternalLogs => _currentRole == UserRole.operator;

  /// Can the user change Execution Mode (e.g. to Full Auto)?
  bool get canChangeExecutionMode => _currentRole == UserRole.operator;

  /// Can the user manually trigger exchange reconciliation?
  bool get canTriggerReconciliation => _currentRole == UserRole.operator;

  /// Can the user publish new strategies to the Registry?
  bool get canPublishStrategies => _currentRole == UserRole.operator;

  /// Can the user subscribe to strategies?
  bool get canSubscribeToStrategies => true; // Both Operators and Traders

  /// Can the user manage/view global subscription data?
  bool get canManageSubscriptions => _currentRole == UserRole.operator;

  /// Can the user view the Creator Dashboard? (Creator + Operator)
  bool get canViewCreatorDashboard =>
      _currentRole == UserRole.operator ||
      _currentRole ==
          UserRole
              .operator; // For PVP/MVP assume Operator has dual role or explicit Creator role distinct?
  // Let's refine based on plan: "Creator: YES, Operator: YES".
  // Since we only have 'UserRole.trader' and 'UserRole.operator' currently in enum (AccessControlService),
  // we will treat Operator as the Creator for now (System Admin = Creator).
  // In a multi-user system we'd have UserRole.creator.

  /// Can the user view ALL revenue analytics? (Operator only, Creators view own)
  bool get canViewRevenueAnalytics => _currentRole == UserRole.operator;

  /// Can the user access the Strategy Sandbox? (Creator + Operator)
  bool get canUseSandbox =>
      _currentRole == UserRole.operator ||
      _currentRole == UserRole.operator; // TBD: Creator Role

  /// Can the user publish directly from Sandbox? (Operator only for now)
  bool get canPublishFromSandbox => _currentRole == UserRole.operator;

  /// Can the user toggle approved strategies ON/OFF?
  /// Traders CAN toggle, but only if the strategy is already authorized by an Operator.
  bool get canToggleStrategyState => true;

  /// Dispose resources to prevent memory leaks
  void dispose() {
    _roleController.close();
  }
}

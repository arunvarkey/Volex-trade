import 'package:flutter/material.dart';
import 'package:volex_terminal/core/services/auth/security_service.dart';
import 'package:volex_terminal/core/service_locator.dart';

import 'package:volex_terminal/core/app_logger.dart';

class BiometricGuard extends StatelessWidget {
  final Widget child;

  const BiometricGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Basic check for device security
    // In a real implementation, this might block rendering or show a lock screen
    // We use a try-catch block to safely get the service, avoiding crashes if GetIt isn't ready.
    bool isSecure = true;
    try {
      final security = getIt<SecurityService>();
      isSecure = security.isDeviceSecure;
    } catch (e) {
      // Service might not be registered yet or failing
      isSecure = false;
      AppLogger.error('BiometricGuard: SecurityService unavailable - $e');
    }

    if (!isSecure) {
      return const Material(
        child: Center(
          child: Text('Device Monitor: Security Issues Detected'),
        ),
      );
    }
    return child;
  }
}

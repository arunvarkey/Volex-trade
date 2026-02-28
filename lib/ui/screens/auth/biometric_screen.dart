import 'package:flutter/material.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_typography.dart';

class BiometricScreen extends StatelessWidget {
  const BiometricScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, color: VxColors.neonCyan, size: 80),
            const SizedBox(height: 32),
            VxText.title("AUTHENTICATION REQUIRED", color: Colors.white),
            const SizedBox(height: 16),
            VxText.body("Please authenticate to access Volex Terminal",
                color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

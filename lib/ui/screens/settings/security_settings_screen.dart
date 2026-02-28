import 'package:flutter/material.dart';
import 'package:volex_terminal/core/services/auth/security_service.dart';
import 'package:volex_terminal/ui/screens/auth/pin_entry_screen.dart';
import 'package:volex_terminal/services/data_privacy_service.dart';
import 'package:volex_terminal/core/service_locator.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_icons.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBox(),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: VxColors.neonCyan),
            title:
                const Text('Change PIN', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Update your 6-digit PIN',
                style: TextStyle(color: Colors.white54)),
            tileColor: VxColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PinEntryScreen(mode: PinEntryMode.change),
                ),
              );

              if (changed == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully')),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<bool>(
            future: getIt<SecurityService>().isBiometricAvailable,
            builder: (context, snapshot) {
              final isAvailable = snapshot.data ?? false;

              return ListTile(
                leading:
                    const Icon(Icons.fingerprint, color: VxColors.neonPurple),
                title: const Text('Biometric Authentication',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  isAvailable
                      ? 'Use fingerprint or face recognition'
                      : 'Biometrics not available on this device',
                  style: const TextStyle(color: Colors.white54),
                ),
                tileColor: VxColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                trailing: isAvailable
                    ? const Icon(Icons.check_circle, color: VxColors.neonGreen)
                    : const Icon(Icons.cancel, color: Colors.grey),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text('Data Privacy (GDPR)',
              style: TextStyle(
                  color: VxColors.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title: const Text('Export My Data',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Download a copy of your personal data',
                style: TextStyle(color: Colors.white54)),
            tileColor: VxColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () async {
              try {
                await getIt<DataPrivacyService>().exportUserData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data export ready')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: VxColors.neonRed),
            title: const Text('Delete Account',
                style: TextStyle(color: VxColors.neonRed)),
            subtitle: const Text('Permanently remove all data',
                style: TextStyle(color: Colors.white54)),
            tileColor: VxColors.surface.withOpacity(0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.neonCyan.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.neonCyan.withOpacity(0.1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(VxIcons.shieldOk, color: VxColors.neonCyan, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Volex uses your device's native secure enclave. Biometric data is never stored or transmitted by the app.",
              style:
                  TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.deepBlack,
        title: const Text('Delete Account?',
            style: TextStyle(color: VxColors.neonRed)),
        content: const Text(
          'This action cannot be undone. All your data, trading history, and settings will be permanently erased.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await getIt<DataPrivacyService>().deleteUserAccount();
                // AuthGate will handle the logout and redirect to login
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deletion failed: $e')),
                  );
                }
              }
            },
            child: const Text('DELETE',
                style: TextStyle(
                    color: VxColors.neonRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

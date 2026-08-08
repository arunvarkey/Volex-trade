import 'package:flutter/material.dart';
import 'package:volex_terminal/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/screens/settings/security_settings_screen.dart';
import 'package:volex_terminal/ui/screens/settings/risk_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/ui/providers/dashboard_provider.dart';
import 'package:volex_terminal/services/user_mode_service.dart';
import 'package:volex_terminal/core/service_locator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader("Account & Security"),
          _buildModeSwitch(context),
          _buildCpuTile(
            context,
            title: "Connect Exchange",
            icon: Icons.sync_alt,
            onTap: () => context.push('/api-key-setup'),
          ),
          _buildCpuTile(
            context,
            title: "Security & 2FA",
            icon: Icons.shield,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SecuritySettingsScreen())),
          ),
          _buildCpuTile(
            context,
            title: "Risk Parameters",
            icon: Icons.speed,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RiskSettingsScreen())),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Legal & Support"),
          _buildCpuTile(
            context,
            title: "Privacy Policy",
            icon: Icons.privacy_tip,
            onTap: () =>
                _launchUrl('https://volexterminal.com/privacy'), // Placeholder
          ),
          _buildCpuTile(
            context,
            title: "Terms of Service",
            icon: Icons.description,
            onTap: () =>
                _launchUrl('https://volexterminal.com/terms'), // Placeholder
          ),
          _buildCpuTile(
            context,
            title: "Open App Settings",
            icon: Icons.settings_applications,
            onTap: () => openAppSettings(),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              "Version 1.0.0 (Build 15)",
              style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCpuTile(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: VxColors.surface,
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: VxColors.neonCyan),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }

  Widget _buildModeSwitch(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final isPro = provider.userMode == UserMode.pro;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: VxColors.surface,
            border: Border.all(
              color: isPro ? VxColors.neonCyan : VxColors.textTertiary,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SwitchListTile(
            title: Text(
              "Pro Mode",
              style: TextStyle(
                color: isPro ? VxColors.neonCyan : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isPro ? "Pro Simulator Active" : "Paper Trading (Simulation)",
              style: const TextStyle(
                color: VxColors.textSecondary,
                fontSize: 12,
              ),
            ),
            value: isPro,
            activeThumbColor: VxColors.neonCyan,
            onChanged: (value) async {
              final newMode = value ? UserMode.pro : UserMode.explorer;
              await getIt<UserModeService>().setMode(newMode);
              await provider.refreshUserMode();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Switched to ${value ? 'Pro' : 'Explorer'} Mode",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor:
                        value ? VxColors.neonCyan : VxColors.surface,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

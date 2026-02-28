import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/ui/screens/settings/security_settings_screen.dart';

import 'package:provider/provider.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_icons.dart';
import '../design_system/theme_service.dart';
import '../design_system/vx_themes.dart';
import '../design_system/vx_typography.dart';
import '../../providers/execution_mode_provider.dart';
import '../../services/profile_service.dart';
import '../../features/subscriptions/services/subscription_service.dart';
import '../../core/services/secure_key_storage.dart';

/// Settings Screen with User Profile & IAP management
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 24),

          // CRITICAL: Execution Mode (Live vs Paper)
          _buildExecutionModeToggle(context),
          const SizedBox(height: 16),

          // Subscription Management
          _buildSubscriptionTile(context),
          const SizedBox(height: 16),

          _buildAiConfigTile(context), // New AI Settings
          const SizedBox(height: 16),

          const SizedBox(height: 16),

          _buildSettingTile(
            icon: VxIcons.notifications,
            title: 'Notifications',
            subtitle: 'Price alerts & updates',
            onTap: () => _showComingSoon(context, 'Notifications'),
          ),

          _buildSettingTile(
            icon: VxIcons.security,
            title: 'Security',
            subtitle: 'PIN, biometrics, safety',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
            ),
          ),

          _buildSettingTile(
            icon: VxIcons.appearance,
            title: 'Appearance',
            subtitle: 'Theme & colors',
            onTap: () => _showThemePicker(context),
          ),

          _buildSettingTile(
            icon: VxIcons.help,
            title: 'Help & Support',
            subtitle: 'Docs, FAQs, contact',
            onTap: () => _showComingSoon(context, 'Help & Support'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<ProfileService>(
      builder: (context, profile, _) {
        return GestureDetector(
          onTap: () => GoRouter.of(context).push('/profile'),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: VxColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: VxColors.neonCyan, width: 2),
                        image: profile.profileImage != null
                            ? DecorationImage(
                                image: FileImage(profile.profileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile.profileImage == null
                          ? const Icon(Icons.person_outline,
                              size: 48, color: Colors.white24)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: VxColors.neonCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                VxText.heading3("OPERATOR_0842"),
                VxText.body("verified_user@volex.terminal",
                    color: Colors.white38),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionTile(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, sub, _) {
        final isPro = sub.currentStatus.isProMode;
        return _buildSettingTile(
          icon: Icons.star_border,
          title: isPro
              ? (sub.currentStatus.isPremium ? 'VOLEX ELITE' : 'VOLEX PRO')
              : 'GO PRO',
          subtitle:
              isPro ? 'Premium features active' : 'Unlock elite trading tools',
          onTap: () => context.push('/subscription'),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        title: Text(feature,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "This feature is under development for V1.1.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: VxColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SELECT THEME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            ...VolexThemeType.values
                .map((type) => _buildThemeOption(context, type)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, VolexThemeType type) {
    final themeService = context.watch<ThemeService>();
    final isSelected = themeService.themeType == type;
    final themeData = VolexTheme.fromType(type);

    return InkWell(
      onTap: () {
        themeService.setTheme(type);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeData.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themeData.primary : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: themeData.background,
                shape: BoxShape.circle,
                border: Border.all(color: themeData.primary),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: themeData.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              type.name.toUpperCase(),
              style: TextStyle(
                color: isSelected ? themeData.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _colorDot(themeData.primary),
                _colorDot(themeData.accent),
                _colorDot(themeData.success),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildExecutionModeToggle(BuildContext context) {
    return Consumer<ExecutionModeProvider>(
      builder: (context, modeProvider, _) {
        // Force Paper Mode visual state since Live is disabled
        // const isLive = false; // Removed to fix lint

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: VxColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: VxColors.neonCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    VxIcons.paperTrading,
                    color: VxColors.neonCyan,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Educational Simulator',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Live Trading coming in Phase 2',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: false, // Always off
                    onChanged: (value) {
                      // Intercept tap to show Coming Soon
                      _showComingSoon(context, 'Live Trading');
                    },
                    activeColor: VxColors.neonRed,
                    inactiveThumbColor: VxColors.neonCyan,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: VxColors.neonCyan),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(VxIcons.chevronRight,
                    color: Colors.white24, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiConfigTile(BuildContext context) {
    return _buildSettingTile(
      icon: Icons.psychology,
      title: 'AI Configuration',
      subtitle: 'Manage OpenAI API Key',
      onTap: () => _showAiSettings(context),
    );
  }

  void _showAiSettings(BuildContext context) async {
    final storage = SecureKeyStorage();
    final hasKey = await storage.hasApiKey();
    final TextEditingController keyController = TextEditingController();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: VxColors.surface,
          title: const Text('AI Configuration',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To use the AI Strategy Generator, you need an OpenAI API Key.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (hasKey)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VxColors.neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: VxColors.neonGreen),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: VxColors.neonGreen, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('API Key is secure & active',
                            style: TextStyle(
                                color: VxColors.neonGreen,
                                fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white54),
                        onPressed: () async {
                          await storage.deleteApiKey();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('API Key removed')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'sk-...',
                        hintText: 'Paste OpenAI Key here',
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        // final Uri url = Uri.parse('https://platform.openai.com/api-keys');
                        // launchUrl(url);
                      },
                      child: const Text('Get a key from OpenAI ->',
                          style: TextStyle(
                              color: VxColors.neonCyan, fontSize: 12)),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
            if (!hasKey)
              ElevatedButton(
                onPressed: () async {
                  final key = keyController.text.trim();
                  if ((key.startsWith('sk-') && key.length > 20) ||
                      key.startsWith('sk-proj-')) {
                    await storage.storeApiKey(key);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API Key saved securely')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Invalid Key Format (must start with sk-)')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: VxColors.neonCyan),
                child: const Text('SAVE KEY',
                    style: TextStyle(color: Colors.black)),
              ),
          ],
        );
      }),
    );
  }
}

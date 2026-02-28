import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/widgets/vx_holographic_card.dart';
import 'package:volex_terminal/services/startup_service.dart';
import 'package:volex_terminal/services/haptic_service.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Menu',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('LEARN & PRACTICE'),
          _buildMenuItem(
            context,
            icon: Icons.auto_awesome,
            title: 'AI Strategy Builder',
            subtitle: 'Describe an idea, AI builds a strategy',
            route: '/ai-strategy',
          ),
          _buildMenuItem(
            context,
            icon: Icons.science,
            title: 'Backtest Lab',
            subtitle: 'Test strategies against real market history',
            route: '/lab',
          ),
          _buildMenuItem(
            context,
            icon: Icons.scanner,
            title: 'Market Scanner',
            subtitle: 'Find trading opportunities across markets',
            route: '/market-scanner',
          ),

          _buildSection('ADVANCED TOOLS'),
          _buildMenuItem(
            context,
            icon: Icons.speed,
            title: 'Strategy Optimizer',
            subtitle: 'Fine-tune with genetic algorithms',
            route: '/optimizer',
          ),
          _buildMenuItem(
            context,
            icon: Icons.code,
            title: 'Script Editor',
            subtitle: 'Write custom strategy code',
            route: '/script-editor',
          ),

          _buildSection('COMMUNITY'),
          _buildMenuItem(
            context,
            icon: Icons.store,
            title: 'Marketplace',
            subtitle: 'Browse and share strategies',
            route: '/marketplace',
          ),
          _buildMenuItem(
            context,
            icon: Icons.leaderboard,
            title: 'Leaderboard',
            subtitle: 'See top performing traders',
            route: '/leaderboard',
          ),

          _buildSection('ACCOUNT'),
          _buildMenuItem(
            context,
            icon: Icons.workspace_premium,
            title: 'Premium',
            subtitle: 'Unlock unlimited features',
            route: '/subscription',
          ),
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Your account and avatar',
            route: '/profile',
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'App preferences',
            route: '/settings',
          ),
          _buildMenuItem(
            context,
            icon: Icons.shield,
            title: 'Risk Settings',
            subtitle: 'Daily limits and safety controls',
            route: '/risk-settings',
          ),
          _buildMenuItem(
            context,
            icon: Icons.security,
            title: 'Security',
            subtitle: 'PIN, API keys, biometrics',
            route: '/security-settings',
          ),

          // Debug section (only in debug builds)
          if (kDebugMode) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Colors.white10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'SYSTEM_DEBUG',
                style: VxTypography.caption.copyWith(
                  color: VxColors.neonRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.bug_report,
              title: 'DEBUG: Test Navigation',
              subtitle: 'Test all routes',
              route: '/debug-nav',
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.red),
              title: Text(
                'RESET_ENVIRONMENT',
                style: VxTypography.body.copyWith(
                  color: VxColors.neonRed,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                'Purge local storage and restart simulation.',
                style: VxTypography.caption
                    .copyWith(color: Colors.white24, fontSize: 11),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: VxColors.surface,
                    title: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('Reset Everything?',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    content: const Text(
                      'This will:\n'
                      '• Sign you out\n'
                      '• Clear all preferences\n'
                      '• Reset onboarding\n'
                      '• Restart the app\n\n'
                      'Use this to test the first-time user experience.',
                      style: TextStyle(color: VxColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  // Reset everything
                  await StartupService().resetOnboarding();

                  // Navigate to splash
                  if (context.mounted) {
                    context.go('/splash');
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: VxTypography.caption.copyWith(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.instance.light();
        context.push(route);
      },
      child: VxHolographicCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        borderRadius: 12,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VxColors.neonCyan.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VxColors.neonCyan.withOpacity(0.1)),
              ),
              child: Icon(icon, color: VxColors.neonCyan, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        VxTypography.body.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VxTypography.caption
                        .copyWith(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white12, size: 18),
          ],
        ),
      ),
    );
  }
}

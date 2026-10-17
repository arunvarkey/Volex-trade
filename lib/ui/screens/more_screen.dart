import 'package:flutter/material.dart';
import 'package:volex_terminal/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_eyebrow.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/widgets/vx_holographic_card.dart';
import 'package:volex_terminal/services/startup_service.dart';
import 'package:volex_terminal/services/haptic_service.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.menuTitle,
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
          _buildSection(l10n.menuSectionLearn),
          _buildMenuItem(
            context,
            icon: Icons.bolt,
            title: l10n.menuDaily,
            subtitle: l10n.menuDailySub,
            route: '/daily',
          ),
          _buildMenuItem(
            context,
            icon: Icons.school,
            title: l10n.menuAcademy,
            subtitle: l10n.menuAcademySub,
            route: '/learn',
          ),
          _buildMenuItem(
            context,
            icon: Icons.spellcheck_rounded,
            title: l10n.menuGlossary,
            subtitle: l10n.menuGlossarySub,
            route: '/glossary',
          ),
          _buildMenuItem(
            context,
            icon: Icons.psychology_alt_outlined,
            title: l10n.menuBehaviour,
            subtitle: l10n.menuBehaviourSub,
            route: '/your-trading',
          ),
          _buildMenuItem(
            context,
            icon: Icons.menu_book_outlined,
            title: l10n.menuJournal,
            subtitle: l10n.menuJournalSub,
            route: '/journal',
          ),
          _buildMenuItem(
            context,
            icon: Icons.insights,
            title: l10n.menuPredictions,
            subtitle: l10n.menuPredictionsSub,
            route: '/predictions',
          ),
          _buildMenuItem(
            context,
            icon: Icons.tune,
            title: l10n.menuStrategyStudio,
            subtitle: l10n.menuStrategyStudioSub,
            route: '/simulator',
          ),
          _buildMenuItem(
            context,
            icon: Icons.science,
            title: l10n.menuBacktest,
            subtitle: l10n.menuBacktestSub,
            route: '/lab',
          ),
          _buildMenuItem(
            context,
            icon: Icons.scanner,
            title: l10n.menuScanner,
            subtitle: l10n.menuScannerSub,
            route: '/market-scanner',
          ),

          _buildSection(l10n.menuSectionTools),
          _buildMenuItem(
            context,
            icon: Icons.speed,
            title: l10n.menuOptimizer,
            subtitle: l10n.menuOptimizerSub,
            route: '/optimizer',
          ),
          _buildMenuItem(
            context,
            icon: Icons.code,
            title: l10n.menuScriptEditor,
            subtitle: l10n.menuScriptEditorSub,
            route: '/script-editor',
          ),

          _buildSection(l10n.menuSectionCommunity),
          _buildMenuItem(
            context,
            icon: Icons.store,
            title: l10n.menuMarketplace,
            // There is no server behind this, so "other people" was wrong:
            // the listings are the ones published on this device.
            subtitle: l10n.menuMarketplaceSub,
            route: '/marketplace',
          ),
          _buildMenuItem(
            context,
            icon: Icons.leaderboard,
            title: l10n.menuLeaderboard,
            // It ranks strategies on verified results, not people, and it
            // stays empty until there are results to rank.
            subtitle: l10n.menuLeaderboardSub,
            route: '/leaderboard',
          ),

          _buildSection(l10n.menuSectionAccount),
          _buildMenuItem(
            context,
            icon: Icons.workspace_premium,
            title: l10n.menuPremium,
            subtitle: l10n.menuPremiumSub,
            route: '/subscription',
          ),
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: l10n.menuProfile,
            subtitle: l10n.menuProfileSub,
            route: '/profile',
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: l10n.menuSettings,
            subtitle: l10n.menuSettingsSub,
            route: '/settings',
          ),
          _buildMenuItem(
            context,
            icon: Icons.shield,
            title: l10n.menuRiskSettings,
            subtitle: l10n.menuRiskSettingsSub,
            route: '/risk-settings',
          ),
          _buildMenuItem(
            context,
            icon: Icons.security,
            title: l10n.menuSecurity,
            subtitle: l10n.menuSecuritySub,
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
              child: VxEyebrow(l10n.debugSection,
                  color: VxColors.neonRed, fontSize: 10),
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.red),
              title: Text(
                l10n.debugReset,
                style: VxTypography.body.copyWith(
                  color: VxColors.neonRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                l10n.debugResetSub,
                style: VxTypography.caption
                    .copyWith(color: Colors.white24, fontSize: 11),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: VxColors.surface,
                    title: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        Text(l10n.debugResetConfirm,
                            style: const TextStyle(color: Colors.white)),
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
                        child: Text(l10n.actionCancel),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: Text(l10n.actionReset),
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
      child: VxEyebrow(title, color: Colors.white24, fontSize: 10),
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
                color: VxColors.neonCyan.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.1)),
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

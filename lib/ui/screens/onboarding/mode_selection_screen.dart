import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/services/startup_service.dart';
import '../../design_system/vx_colors.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Title
                const Text(
                  'Choose Your Experience',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Start exploring with zero pressure',
                  style: TextStyle(
                    fontSize: 16,
                    color: VxColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Explorer Mode Card (RECOMMENDED)
                _ModeCard(
                  title: 'Explorer Mode',
                  subtitle: 'Start Free - No API Keys Needed',
                  badge: 'RECOMMENDED',
                  icon: Icons.explore,
                  color: VxColors.primary,
                  features: const [
                    'AI-Powered Trade Signals',
                    'Paper Trading Practice',
                    'Strategy Backtesting',
                    'Market Scanner',
                    'Community Insights',
                    'Zero Risk',
                  ],
                  onTap: () => _selectExplorerMode(context),
                ),
                const SizedBox(height: 20),

                // Pro Mode Card
                _ModeCard(
                  title: 'Pro Mode',
                  subtitle: 'Connect Your Exchange',
                  icon: Icons.rocket_launch,
                  color: VxColors.neonPurple,
                  features: const [
                    'Everything in Explorer',
                    'Live Trading Execution',
                    'Automated Strategies',
                    'Advanced Risk Management',
                  ],
                  onTap: () => _selectProMode(context),
                ),
                const SizedBox(height: 32),

                // Can switch later
                const Text(
                  'You can upgrade to Pro Mode anytime',
                  style: TextStyle(
                    fontSize: 12,
                    color: VxColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectExplorerMode(BuildContext context) async {
    // Save mode selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mode', 'explorer');

    // Mark mode as selected
    await StartupService().markModeSelected();

    // Track analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'mode_selected',
      parameters: {'mode': 'explorer'},
    );

    // Go straight to app (no API keys needed!)
    if (context.mounted) context.go('/');
  }

  void _selectProMode(BuildContext context) async {
    // Save mode selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mode', 'pro');

    // Mark mode as selected
    await StartupService().markModeSelected();

    // Track analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'mode_selected',
      parameters: {'mode': 'pro'},
    );

    // Show API key setup
    if (context.mounted) context.push('/api-key-setup');
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color color;
  final List<String> features;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    this.badge,
    required this.icon,
    required this.color,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VxColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Badge
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: VxColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Features
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor:
                      VxColors.deepBlack, // ✅ FIXED: Dark text for contrast
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  badge != null ? 'Start Free' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: VxColors.deepBlack, // ✅ Explicit dark text
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

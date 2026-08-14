// lib/features/simulator/ai_strategy/screens/simulator_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';
import 'package:volex_terminal/features/subscriptions/models/subscription_tier.dart';
import 'package:volex_terminal/core/config/app_mode_service.dart';
import 'package:volex_terminal/core/config/app_mode.dart';

class SimulatorHomeScreen extends StatelessWidget {
  const SimulatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appMode = context.watch<AppModeService>();
    final subscription = context.watch<SubscriptionService>();

    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      appBar: AppBar(
        backgroundColor: VxColors.deepBlack,
        title: const Text('Strategy Simulator'),
        actions: [
          // Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: appMode.currentMode.themeColor.withValues(alpha: 0.2),
              border: Border.all(color: appMode.currentMode.themeColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              appMode.currentMode.displayName.toUpperCase(),
              style: TextStyle(
                color: appMode.currentMode.themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            _buildWelcomeCard(context, subscription),

            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(context, subscription),

            const SizedBox(height: 24),

            // Recent strategies
            _buildRecentStrategies(context),

            const SizedBox(height: 24),

            // Learning resources
            if (subscription.currentTier != SubscriptionTier.free)
              _buildLearningResources(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
      BuildContext context, SubscriptionService subscription) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VxColors.neonCyan.withValues(alpha: 0.12),
            VxColors.neonCyan.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: VxColors.neonCyan, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to the Simulator',
                      style: TextStyle(
                        color: VxColors.neonCyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.currentTier == SubscriptionTier.free
                          ? 'Free Tier • 3 Strategy Limit'
                          : '${subscription.currentTier.toString().split('.').last.toUpperCase()} Plan',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Build, backtest, and practice trading strategies risk-free. '
            'No real money until you\'re ready.',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, SubscriptionService subscription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: VxColors.neonCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.add_circle_outline,
                title: 'New Strategy',
                subtitle: 'From template',
                color: VxColors.neonGreen,
                onTap: () => context.push('/simulator/templates'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.psychology,
                title: 'AI Assistant',
                subtitle: 'Demo',
                color: VxColors.neonCyan,
                onTap: () => context.push('/simulator/ai-assistant'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context: context,
          icon: Icons.folder_open,
          title: 'My Strategies',
          subtitle: 'View & manage saved',
          color: VxColors.neonCyan,
          onTap: () => context.push('/simulator/my-strategies'),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentStrategies(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Strategies',
          style: TextStyle(
            color: VxColors.neonCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Ready for deployment. Start by creating a strategy from the templates above.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningResources(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Resources',
          style: TextStyle(
            color: VxColors.neonCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Coming soon: Video tutorials, strategy guides, and more.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }
}

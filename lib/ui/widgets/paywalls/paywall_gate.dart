import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/core/service_locator.dart';

class PaywallGate extends StatelessWidget {
  final String feature;
  final Widget child;
  final String? customTitle;
  final String? customMessage;

  const PaywallGate({
    super.key,
    required this.feature,
    required this.child,
    this.customTitle,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getIt<SubscriptionService>().statusStream,
      builder: (context, snapshot) {
        final hasAccess = getIt<SubscriptionService>().hasAccessTo(feature);

        if (hasAccess) {
          return child;
        }

        return _buildPaywall(context);
      },
    );
  }

  Widget _buildPaywall(BuildContext context) {
    return Container(
      color: VxColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: VxColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 64,
                  color: VxColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                customTitle ?? 'Premium Feature',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                customMessage ?? _getFeatureMessage(feature),
                style: const TextStyle(
                  fontSize: 16,
                  color: VxColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Upgrade button
              ElevatedButton(
                onPressed: () => context.push('/subscription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.primary,
                  foregroundColor: VxColors.deepBlack, // ✅ ADDED
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: VxColors.deepBlack, // ✅ FIXED
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Learn more
              TextButton(
                onPressed: () => context.push('/subscription'),
                child: const Text('View All Plans'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFeatureMessage(String feature) {
    switch (feature) {
      case 'unlimited_signals':
        return 'Upgrade to Premium to get unlimited AI trading signals every day';
      case 'ai_guardian':
        return 'Upgrade to Premium for trade checks that flag risky habits before you commit';
      case 'live_trading':
        return 'Coming Soon!';
      case 'automated_strategies':
        return 'Upgrade to Premium to run automated trading strategies 24/7';
      case 'advanced_analytics':
        return 'Upgrade to Premium to access advanced performance analytics';
      case 'custom_watchlists':
        return 'Upgrade to Premium to create unlimited custom watchlists';
      case 'priority_support':
        return 'Upgrade to Premium to get priority customer support';
      default:
        return 'Upgrade to unlock this feature';
    }
  }
}

/// Simple check widget - shows upgrade button if feature locked
class FeatureCheck extends StatelessWidget {
  final String feature;

  const FeatureCheck({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final hasAccess = getIt<SubscriptionService>().hasAccessTo(feature);

    if (hasAccess) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: VxColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Upgrade to unlock',
              style: TextStyle(
                color: VxColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/subscription'),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}

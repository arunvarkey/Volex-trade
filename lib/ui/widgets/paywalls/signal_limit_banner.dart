import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/core/service_locator.dart';

class SignalLimitBanner extends StatelessWidget {
  const SignalLimitBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: getIt<SubscriptionService>().canViewMoreSignals(),
      builder: (context, snapshot) {
        // Premium users - no banner
        if (getIt<SubscriptionService>().currentStatus.isPremium) {
          return const SizedBox.shrink();
        }

        // Loading
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final canView = snapshot.data!;

        // Has signals remaining - no banner
        if (canView) {
          return _buildRemainingSignalsBanner(context);
        }

        // Limit reached - show upgrade banner
        return _buildLimitReachedBanner(context);
      },
    );
  }

  Widget _buildRemainingSignalsBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: VxColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<int>(
              future: _getRemainingSignals(),
              builder: (context, snapshot) {
                final remaining = snapshot.data ?? 5;
                return Text(
                  '$remaining signals remaining today',
                  style: const TextStyle(
                    color: VxColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          TextButton(
            onPressed: () => context.push('/subscription'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Upgrade', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitReachedBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VxColors.neonPurple.withValues(alpha: 0.2),
            VxColors.primary.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VxColors.primary.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VxColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium,
                    color: VxColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Limit Reached',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upgrade for unlimited signals',
                      style: TextStyle(
                        color: VxColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VxColors.primary,
                foregroundColor: VxColors.deepBlack, // ✅ ADDED
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upgrade to Premium - \$9.99/mo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: VxColors.deepBlack, // ✅ FIXED
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Resets at midnight UTC',
            style: TextStyle(
              color: VxColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getRemainingSignals() async {
    // 5 is max for free tier
    return getIt<SubscriptionService>().getRemainingDailySignals();
  }
}

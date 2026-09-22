// lib/features/simulator/strategy_builder/screens/template_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../ui/design_system/vx_colors.dart';
import '../../../../features/subscriptions/services/subscription_service.dart';
import '../../../../features/subscriptions/models/subscription_tier.dart';
import '../services/template_library.dart';
import '../models/strategy_template.dart';

class TemplateSelectorScreen extends StatelessWidget {
  const TemplateSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionService>();
    final templates = TemplateLibrary.all;

    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      appBar: AppBar(
        backgroundColor: VxColors.deepBlack,
        title: const Text(
          'CHOOSE TEMPLATE',
          style: TextStyle(
            color: VxColors.neonCyan,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final template = templates[index];
          final hasAccess = _checkAccess(template, subscription);

          return _buildTemplateCard(
            context: context,
            template: template,
            hasAccess: hasAccess,
            onTap: hasAccess
                ? () => _navigateToConfig(context, template)
                : () => context.push('/paywall'),
          );
        },
      ),
    );
  }

  bool _checkAccess(
      StrategyTemplate template, SubscriptionService subscription) {
    switch (template.requiredTier) {
      case SubscriptionTier.free:
        return true;
      case SubscriptionTier.explorerPremium:
        return subscription.currentTier != SubscriptionTier.free;
    }
  }

  Widget _buildTemplateCard({
    required BuildContext context,
    required StrategyTemplate template,
    required bool hasAccess,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasAccess
              ? VxColors.neonCyan.withValues(alpha: 0.05)
              : Colors.grey[900],
          border: Border.all(
            color: hasAccess
                ? VxColors.neonCyan.withValues(alpha: 0.3)
                : Colors.grey[800]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasAccess
                    ? VxColors.neonCyan.withValues(alpha: 0.2)
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                template.icon,
                color: hasAccess ? VxColors.neonCyan : Colors.grey[600],
                size: 32,
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.name.toUpperCase(),
                        style: TextStyle(
                          color:
                              hasAccess ? VxColors.neonCyan : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      if (!hasAccess) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock, color: Colors.orange, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.category,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: hasAccess ? VxColors.neonCyan : Colors.grey[700],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToConfig(BuildContext context, StrategyTemplate template) {
    context.push('/simulator/templates/config', extra: template);
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/services/startup_service.dart';

class UpgradePromptDialog extends StatelessWidget {
  const UpgradePromptDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final shouldShow = await StartupService().shouldShowUpgradePrompt();

    if (shouldShow && context.mounted) {
      await StartupService().markUpgradePromptShown();

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UpgradePromptDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VxColors.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: VxColors.primary.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: VxColors.primary.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [VxColors.primary, VxColors.neonCyan],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Loving the signals?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Message
            const Text(
              'You\'ve viewed 5 AI-powered signals!\n\nUpgrade to Premium for:',
              style: TextStyle(
                fontSize: 15,
                color: VxColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Features
            ...[
              '✨ Unlimited signals every day',
              '⚠️ Trade checks before you commit',
              '📊 Advanced analytics',
              '🎯 Custom watchlists',
            ].map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.primary,
                  foregroundColor: VxColors.deepBlack, // ✅ ADDED
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Upgrade to Premium - \$9.99/mo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: VxColors.deepBlack, // ✅ FIXED
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Maybe later
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}

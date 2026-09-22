import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/features/academy/services/academy_progress_service.dart';
import 'package:volex_terminal/services/haptic_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// The trademark: "Guided every step."
///
/// A single, always-present card that reads the user's real progress and shows
/// the one best next action along the Learn -> Build -> Trade -> Level-up spine,
/// with a plain-language "why". A new user should never be lost.
class NextStepGuide extends StatefulWidget {
  const NextStepGuide({super.key});

  @override
  State<NextStepGuide> createState() => _NextStepGuideState();
}

class _NextStepGuideState extends State<NextStepGuide> {
  final AcademyProgressService _academy = AcademyProgressService.instance;

  static const int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _academy.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final exec = context.watch<ExecutionManager>();
    return AnimatedBuilder(
      animation: _academy,
      builder: (context, _) => _card(context, _computeStep(exec)),
    );
  }

  _NextStep _computeStep(ExecutionManager exec) {
    final learned = _academy.completedCount > 0;
    final hasStrategy = exec.activeStrategyIds.isNotEmpty;
    final hasTraded = exec.orders.isNotEmpty;

    if (!learned) {
      return const _NextStep(
        index: 1,
        title: 'Take your first lesson',
        why: 'Every trader starts here — about 3 minutes to your first concept.',
        cta: 'Start learning',
        icon: Icons.school_rounded,
        route: '/learn',
      );
    }
    if (!hasStrategy && !hasTraded) {
      return const _NextStep(
        index: 2,
        title: 'Build your first strategy',
        why: 'Start from a ready-made template and change the parts you '
            'understand — no code.',
        cta: 'Open Strategy Studio',
        icon: Icons.tune_rounded,
        route: '/simulator/templates',
      );
    }
    if (!hasTraded) {
      return const _NextStep(
        index: 3,
        title: 'Place your first paper trade',
        why: 'Put it to work risk-free with \$100k of practice money.',
        cta: 'Open the chart',
        icon: Icons.candlestick_chart_rounded,
        route: '/chart',
      );
    }
    return const _NextStep(
      index: 4,
      title: "You're trading — keep leveling up",
      why: 'Refine a strategy, take today\'s challenge, or learn something new.',
      cta: 'Continue learning',
      icon: Icons.workspace_premium_rounded,
      route: '/learn',
    );
  }

  Widget _card(BuildContext context, _NextStep step) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VxColors.primary.withValues(alpha: 0.16),
            VxColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VxColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'YOUR NEXT STEP',
                style: VxTypography.caption.copyWith(
                  color: VxColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${step.index} of $_totalSteps',
                style: VxTypography.caption.copyWith(
                  color: VxColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: VxColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step.icon, color: VxColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: VxTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.why,
                      style: VxTypography.bodySmall.copyWith(
                        color: VxColors.textSecondary,
                        height: 1.35,
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
              onPressed: () {
                HapticService.instance.light();
                context.push(step.route);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: VxColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(step.cta,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _progressDots(step.index),
        ],
      ),
    );
  }

  Widget _progressDots(int currentIndex) {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final done = i < currentIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == _totalSteps - 1 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: done
                  ? VxColors.primary
                  : Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _NextStep {
  final int index;
  final String title;
  final String why;
  final String cta;
  final IconData icon;
  final String route;

  const _NextStep({
    required this.index,
    required this.title,
    required this.why,
    required this.cta,
    required this.icon,
    required this.route,
  });
}

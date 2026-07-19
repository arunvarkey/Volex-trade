import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/features/academy/services/academy_progress_service.dart';
import 'package:volex_terminal/services/haptic_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// The trader journey — Learn → Build → Test → Trade → Pro — as one guided
/// horizontal strip on home. Makes the Strategy Lab loop visible and gives
/// every user an obvious "what's next".
class JourneyStrip extends StatefulWidget {
  const JourneyStrip({super.key});

  @override
  State<JourneyStrip> createState() => _JourneyStripState();
}

class _JourneyStripState extends State<JourneyStrip> {
  final AcademyProgressService _academy = AcademyProgressService.instance;

  @override
  void initState() {
    super.initState();
    _academy.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _academy,
      builder: (context, _) {
        final learnPct = (_academy.overallProgress * 100).round();
        final steps = <_JourneyStep>[
          _JourneyStep(
            number: '01',
            label: 'LEARN',
            sub: learnPct > 0 ? '$learnPct% complete' : 'Start the Academy',
            icon: Icons.school_rounded,
            color: VxColors.neonGreen,
            route: '/learn',
            progress: _academy.overallProgress,
          ),
          const _JourneyStep(
            number: '02',
            label: 'BUILD',
            sub: 'AI strategy from an idea',
            icon: Icons.auto_awesome_rounded,
            color: VxColors.neonCyan,
            route: '/ai-strategy',
          ),
          const _JourneyStep(
            number: '03',
            label: 'TEST',
            sub: 'Backtest on real history',
            icon: Icons.science_rounded,
            color: VxColors.neonPurple,
            route: '/lab',
          ),
          const _JourneyStep(
            number: '04',
            label: 'TRADE',
            sub: 'Paper trade it live',
            icon: Icons.candlestick_chart_rounded,
            color: VxColors.neonYellow,
            route: '/chart',
          ),
          const _JourneyStep(
            number: '05',
            label: 'GO PRO',
            sub: 'Unlimited everything',
            icon: Icons.workspace_premium_rounded,
            color: VxColors.neonMagenta,
            route: '/subscription',
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Text(
                'YOUR TRADER JOURNEY',
                style: VxTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: VxColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _JourneyCard(step: steps[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _JourneyStep {
  final String number;
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final String route;
  final double? progress;

  const _JourneyStep({
    required this.number,
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.route,
    this.progress,
  });
}

class _JourneyCard extends StatelessWidget {
  final _JourneyStep step;
  const _JourneyCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.instance.light();
        context.push(step.route);
      },
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VxColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: step.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(step.icon, size: 16, color: step.color),
                const Spacer(),
                Text(
                  step.number,
                  style: VxTypography.caption.copyWith(
                    fontSize: 10,
                    color: step.color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              step.label,
              style: VxTypography.body.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              step.sub,
              style: VxTypography.caption
                  .copyWith(fontSize: 9.5, color: VxColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (step.progress != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: step.progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(step.color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

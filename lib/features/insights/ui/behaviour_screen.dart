import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/features/academy/data/academy_curriculum.dart';
import 'package:volex_terminal/features/academy/ui/lesson_screen.dart';
import 'package:volex_terminal/features/insights/models/behaviour_insight.dart';
import 'package:volex_terminal/features/insights/services/behaviour_analysis_service.dart';
import 'package:volex_terminal/features/journal/services/journal_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// Your own trading record, read back to you.
///
/// The screen deliberately leads with what is costing the user and shows the
/// sample size on every card. Both choices are there to stop this becoming
/// the thing it would be easiest to build: a flattering dashboard that tells
/// people they are doing well.
class BehaviourScreen extends StatefulWidget {
  const BehaviourScreen({super.key});

  @override
  State<BehaviourScreen> createState() => _BehaviourScreenState();
}

class _BehaviourScreenState extends State<BehaviourScreen> {
  final _journal = JournalService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _journal.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  void _openLesson(String lessonId) {
    for (final lesson in AcademyCurriculum.allLessons) {
      if (lesson.id != lessonId) continue;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Your trading'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: VxColors.primary))
          : Consumer<ExecutionManager>(
              builder: (context, manager, _) {
                final report = const BehaviourAnalysisService().analyse(
                  positions: manager.positions,
                  journal: _journal.entries,
                );
                return _body(report);
              },
            ),
    );
  }

  Widget _body(BehaviourReport report) {
    if (!report.hasInsights) {
      return _notYet(report);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        _preamble(report),
        const SizedBox(height: 16),
        for (final insight in report.insights) ...[
          _card(insight),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        _footnote(),
      ],
    );
  }

  /// The empty state, which is most users most of the time and is therefore
  /// worth writing properly. It says exactly how many more trades are needed
  /// rather than "no data" — a number is an instruction, "no data" is a dead
  /// end.
  Widget _notYet(BehaviourReport report) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insights_outlined,
                size: 44, color: VxColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              report.tradesAnalysed == 0
                  ? 'Nothing to read yet'
                  : '${report.tradesUntilFirstInsight} more closed trades',
              style: VxTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              report.tradesAnalysed == 0
                  ? 'Once you have closed some trades, this screen shows what '
                      'your own record says about how you trade.'
                  : 'You have closed ${report.tradesAnalysed}. Patterns drawn '
                      'from fewer than '
                      '${BehaviourAnalysisService.minTradesForRate} trades are '
                      'mostly noise, and this app is not going to tell you '
                      'something it taught you to disbelieve.',
              style: VxTypography.bodySmall.copyWith(
                color: VxColors.textSecondary,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _preamble(BehaviourReport report) {
    return Text(
      'From ${report.tradesAnalysed} closed trades. Every figure below comes '
      'from your own record — nothing here is an average of other people.',
      style: VxTypography.bodySmall.copyWith(
        color: VxColors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _card(BehaviourInsight insight) {
    final accent = switch (insight.tone) {
      InsightTone.warning => VxColors.neonRed,
      InsightTone.good => VxColors.positive,
      InsightTone.neutral => VxColors.textTertiary,
    };
    final icon = switch (insight.tone) {
      InsightTone.warning => Icons.error_outline_rounded,
      InsightTone.good => Icons.check_circle_outline_rounded,
      InsightTone.neutral => Icons.info_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.headline,
                  style: VxTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.evidence,
            style: VxTypography.bodySmall.copyWith(
              color: VxColors.textSecondary,
              height: 1.55,
            ),
          ),
          if (insight.suggestion != null) ...[
            const SizedBox(height: 12),
            Text(
              insight.suggestion!,
              style: VxTypography.bodySmall.copyWith(height: 1.55),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // Always visible, never in small print. A reader who knows a
              // claim rests on 23 trades can weigh it; one who is not told
              // cannot.
              Text(
                'Based on ${insight.sampleSize} trades',
                style: VxTypography.caption.copyWith(
                  color: VxColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (insight.lessonId != null)
                TextButton(
                  onPressed: () => _openLesson(insight.lessonId!),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    foregroundColor: VxColors.primary,
                  ),
                  child: const Text('Learn this'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footnote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        'These are patterns in a simulated record, and a pattern is not a '
        'cause. They are worth checking against what you remember doing, not '
        'taking as a verdict. Anything drawn from too few trades is left out '
        'rather than shown with a caveat.',
        style: VxTypography.caption.copyWith(
          color: VxColors.textTertiary,
          height: 1.5,
          fontSize: 11,
        ),
      ),
    );
  }
}

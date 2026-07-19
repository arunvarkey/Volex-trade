import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import '../data/academy_curriculum.dart';
import '../models/academy_models.dart';
import '../services/academy_progress_service.dart';

/// The Trading Academy hub — a guided, top-to-bottom learning path.
class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  final AcademyProgressService _progress = AcademyProgressService.instance;

  @override
  void initState() {
    super.initState();
    _progress.ensureLoaded();
  }

  void _openLesson(Lesson lesson) {
    context.push('/learn/lesson', extra: lesson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'TRADING ACADEMY',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            color: Colors.white,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _ProgressHeader(
                progress: _progress.overallProgress,
                completed: _progress.completedCount,
                total: _progress.totalCount,
                nextLesson: _progress.nextLesson,
                onContinue: (lesson) => _openLesson(lesson),
              ),
              const SizedBox(height: 24),
              for (final module in AcademyCurriculum.modules) ...[
                _ModuleCard(
                  module: module,
                  progress: _progress,
                  onTapLesson: _openLesson,
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              const _DisclaimerFooter(),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;
  final Lesson? nextLesson;
  final ValueChanged<Lesson> onContinue;

  const _ProgressHeader({
    required this.progress,
    required this.completed,
    required this.total,
    required this.nextLesson,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bool finished = nextLesson == null && total > 0;
    final bool started = completed > 0;
    final int pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VxColors.surfaceBright, VxColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎓', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  finished
                      ? 'You\'ve completed every lesson!'
                      : started
                          ? 'Keep going — you\'re building real skill'
                          : 'Learn to trade, the right way',
                  style: VxTypography.h3.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            finished
                ? 'Now put it into practice with paper trades and backtests.'
                : 'Short, plain-English lessons. No jargon, no hype, zero risk.',
            style: VxTypography.bodySmall.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        VxColors.neonCyan),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$pct%',
                style: VxTypography.price.copyWith(
                  color: VxColors.neonCyan,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$completed of $total lessons complete',
            style: VxTypography.caption.copyWith(fontSize: 11),
          ),
          if (!finished) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextLesson == null
                    ? null
                    : () => onContinue(nextLesson!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(started ? Icons.play_arrow_rounded
                        : Icons.school_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      started ? 'CONTINUE LEARNING' : 'START LEARNING',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final AcademyModule module;
  final AcademyProgressService progress;
  final ValueChanged<Lesson> onTapLesson;

  const _ModuleCard({
    required this.module,
    required this.progress,
    required this.onTapLesson,
  });

  @override
  Widget build(BuildContext context) {
    final done = progress.completedInModule(module);
    final total = module.lessons.length;
    final bool moduleComplete = progress.isModuleComplete(module);

    return Container(
      decoration: BoxDecoration(
        color: VxColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: moduleComplete
              ? module.accent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: module.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(module.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              module.title,
                              style: VxTypography.body
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LevelChip(level: module.level, accent: module.accent),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        module.subtitle,
                        style: VxTypography.bodySmall.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(module.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$done/$total',
                  style: VxTypography.caption.copyWith(
                    fontSize: 11,
                    color: moduleComplete ? module.accent : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < module.lessons.length; i++)
            _LessonRow(
              lesson: module.lessons[i],
              index: i + 1,
              accent: module.accent,
              done: progress.isComplete(module.lessons[i].id),
              onTap: () => onTapLesson(module.lessons[i]),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final int index;
  final Color accent;
  final bool done;
  final VoidCallback onTap;

  const _LessonRow({
    required this.lesson,
    required this.index,
    required this.accent,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done
                    ? accent.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? accent : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: done
                    ? Icon(Icons.check_rounded, size: 15, color: accent)
                    : Text(
                        '$index',
                        style: VxTypography.caption.copyWith(fontSize: 11),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: VxTypography.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: done ? VxColors.textSecondary : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    lesson.summary,
                    style: VxTypography.bodySmall.copyWith(fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${lesson.minutes}m',
              style: VxTypography.caption.copyWith(fontSize: 10),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String level;
  final Color accent;

  const _LevelChip({required this.level, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level.toUpperCase(),
        style: VxTypography.caption.copyWith(
          fontSize: 8.5,
          color: accent,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DisclaimerFooter extends StatelessWidget {
  const _DisclaimerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'Educational content only. Volex is a risk-free simulator — nothing here '
        'is financial advice, and all practice uses virtual money.',
        textAlign: TextAlign.center,
        style: VxTypography.caption.copyWith(fontSize: 10.5),
      ),
    );
  }
}

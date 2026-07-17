import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import '../data/academy_curriculum.dart';
import '../models/academy_models.dart';
import '../services/academy_progress_service.dart';

/// Reads a single [Lesson]: renders its content blocks and lets the learner
/// mark it complete and flow straight into the next lesson.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final AcademyProgressService _progress = AcademyProgressService.instance;

  int get _lessonNumber {
    final all = AcademyCurriculum.allLessons;
    final idx = all.indexWhere((l) => l.id == widget.lesson.id);
    return idx < 0 ? 1 : idx + 1;
  }

  Future<void> _completeAndContinue() async {
    await _progress.markComplete(widget.lesson.id);
    final next = _progress.lessonAfter(widget.lesson.id);
    if (!mounted) return;
    if (next != null) {
      context.pushReplacement('/learn/lesson', extra: next);
    } else {
      _showFinishedAndExit();
    }
  }

  void _goNextOrBack() {
    final next = _progress.lessonAfter(widget.lesson.id);
    if (next != null) {
      context.pushReplacement('/learn/lesson', extra: next);
    } else {
      context.pop();
    }
  }

  void _showFinishedAndExit() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VxColors.surfaceBright,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('🎓 Curriculum complete!',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'You\'ve finished every lesson. Now practise with paper trades and '
          'prove your ideas in the Backtest Lab — risk-free.',
          style: VxTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) context.pop();
            },
            child: const Text('BACK TO ACADEMY',
                style: TextStyle(color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final total = AcademyCurriculum.totalLessons;
    final bool alreadyDone = _progress.isComplete(lesson.id);
    final bool hasNext = _progress.lessonAfter(lesson.id) != null;

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'LESSON $_lessonNumber OF $total',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white70,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(lesson.title, style: VxTypography.h1.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 14, color: VxColors.textTertiary),
              const SizedBox(width: 4),
              Text('${lesson.minutes} min read',
                  style: VxTypography.caption.copyWith(fontSize: 11)),
              if (alreadyDone) ...[
                const SizedBox(width: 12),
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: VxColors.neonGreen),
                const SizedBox(width: 4),
                Text('Completed',
                    style: VxTypography.caption.copyWith(
                        fontSize: 11, color: VxColors.neonGreen)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          for (final block in lesson.blocks) _LessonBlockView(block: block),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        alreadyDone: alreadyDone,
        hasNext: hasNext,
        onComplete: _completeAndContinue,
        onNext: _goNextOrBack,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool alreadyDone;
  final bool hasNext;
  final VoidCallback onComplete;
  final VoidCallback onNext;

  const _BottomBar({
    required this.alreadyDone,
    required this.hasNext,
    required this.onComplete,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData icon;
    final VoidCallback onTap;

    if (!alreadyDone) {
      label = hasNext ? 'MARK COMPLETE & CONTINUE' : 'MARK COMPLETE & FINISH';
      icon = Icons.check_rounded;
      onTap = onComplete;
    } else if (hasNext) {
      label = 'NEXT LESSON';
      icon = Icons.arrow_forward_rounded;
      onTap = onNext;
    } else {
      label = 'BACK TO ACADEMY';
      icon = Icons.school_rounded;
      onTap = onNext;
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: VxColors.neonCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders one content block according to its type.
class _LessonBlockView extends StatelessWidget {
  final LessonBlock block;

  const _LessonBlockView({required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case LessonBlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(block.text, style: VxTypography.h3.copyWith(fontSize: 18)),
        );
      case LessonBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            block.text,
            style: VxTypography.body.copyWith(height: 1.55, fontSize: 15.5),
          ),
        );
      case LessonBlockType.bullets:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final b in block.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 7, right: 10),
                        child: Icon(Icons.circle,
                            size: 6, color: VxColors.neonCyan),
                      ),
                      Expanded(
                        child: Text(
                          b,
                          style: VxTypography.body
                              .copyWith(height: 1.45, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      case LessonBlockType.tip:
        return _Callout(
          icon: Icons.lightbulb_rounded,
          color: VxColors.neonCyan,
          label: 'PRO TIP',
          text: block.text,
        );
      case LessonBlockType.warning:
        return _Callout(
          icon: Icons.warning_amber_rounded,
          color: VxColors.neonYellow,
          label: 'WATCH OUT',
          text: block.text,
        );
      case LessonBlockType.keyTakeaway:
        return _Callout(
          icon: Icons.key_rounded,
          color: VxColors.neonGreen,
          label: 'KEY TAKEAWAY',
          text: block.text,
          emphasise: true,
        );
      case LessonBlockType.tryIt:
        return _TryItBlock(block: block);
    }
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String text;
  final bool emphasise;

  const _Callout({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(emphasise ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: VxTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: VxTypography.body.copyWith(
              height: 1.5,
              fontSize: 14.5,
              fontWeight: emphasise ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TryItBlock extends StatelessWidget {
  final LessonBlock block;

  const _TryItBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VxColors.neonCyan.withOpacity(0.12),
            VxColors.neonPurple.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VxColors.neonCyan.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded,
                  size: 16, color: VxColors.neonCyan),
              const SizedBox(width: 6),
              Text(
                'TRY IT NOW',
                style: VxTypography.caption.copyWith(
                  color: VxColors.neonCyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.text,
            style: VxTypography.body.copyWith(height: 1.5, fontSize: 14.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final route = block.actionRoute;
                if (route != null && route.isNotEmpty) context.push(route);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: VxColors.neonCyan,
                side: const BorderSide(color: VxColors.neonCyan, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                (block.actionLabel ?? 'OPEN').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

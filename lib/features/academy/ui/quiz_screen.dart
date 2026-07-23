import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import '../data/academy_quizzes.dart';
import '../models/academy_models.dart';
import '../services/academy_progress_service.dart';
import '../services/xp_service.dart';

/// Checkpoint quiz for a lesson. The learner answers three questions one at a
/// time; passing ([AcademyQuizzes.passThreshold]/3) marks the lesson complete
/// and awards XP. Failing sends them back to re-read, protecting the meaning of
/// "completed".
class QuizScreen extends StatefulWidget {
  final Lesson lesson;

  const QuizScreen({super.key, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizQuestion> _questions =
      AcademyQuizzes.forLesson(widget.lesson.id);

  int _index = 0;
  int _correct = 0;
  int? _chosen; // null until the learner picks; then the answer is locked
  bool _finished = false;
  int _awardedXp = 0;

  QuizQuestion get _q => _questions[_index];
  bool get _answered => _chosen != null;

  void _choose(int i) {
    if (_answered) return;
    setState(() {
      _chosen = i;
      if (_q.isCorrect(i)) _correct++;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _chosen = null;
      });
      return;
    }
    // Last question answered — resolve the quiz.
    final passed = AcademyQuizzes.isPass(_correct);
    if (passed) {
      await AcademyProgressService.instance.markComplete(widget.lesson.id);
      _awardedXp = await XpService.instance
          .awardOnce('lesson:${widget.lesson.id}', XpService.lessonXp);
    }
    if (!mounted) return;
    setState(() => _finished = true);
  }

  void _retry() {
    setState(() {
      _index = 0;
      _correct = 0;
      _chosen = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      // No quiz for this lesson — nothing to gate on; leave immediately.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const Scaffold(backgroundColor: VxColors.background);
    }

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _finished ? 'RESULT' : 'CHECKPOINT ${_index + 1} OF ${_questions.length}',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white70,
          ),
        ),
      ),
      body: _finished ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final q = _q;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _ProgressDots(total: _questions.length, current: _index),
        const SizedBox(height: 24),
        Text(q.prompt, style: VxTypography.h2.copyWith(fontSize: 21, height: 1.3)),
        const SizedBox(height: 24),
        for (int i = 0; i < q.options.length; i++)
          _OptionTile(
            text: q.options[i],
            state: _stateFor(i),
            onTap: () => _choose(i),
          ),
        if (_answered) ...[
          const SizedBox(height: 8),
          _ExplanationCard(
            correct: q.isCorrect(_chosen!),
            text: q.explanation,
          ),
        ],
      ],
    );
  }

  _OptionState _stateFor(int i) {
    if (!_answered) return _OptionState.idle;
    if (i == _q.correctIndex) return _OptionState.correct;
    if (i == _chosen) return _OptionState.wrong;
    return _OptionState.dimmed;
  }

  Widget _buildResult() {
    final passed = AcademyQuizzes.isPass(_correct);
    final color = passed ? VxColors.neonGreen : VxColors.neonYellow;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Text(passed ? '🎉' : '📖',
              style: const TextStyle(fontSize: 56)),
        ),
        const SizedBox(height: 16),
        Text(
          passed ? 'Lesson complete!' : 'Almost there',
          textAlign: TextAlign.center,
          style: VxTypography.h1.copyWith(fontSize: 26, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          'You got $_correct of ${_questions.length} correct'
          '${passed ? '.' : ' — you need ${AcademyQuizzes.passThreshold} to pass.'}',
          textAlign: TextAlign.center,
          style: VxTypography.bodySmall.copyWith(fontSize: 15, height: 1.5),
        ),
        if (passed && _awardedXp > 0) ...[
          const SizedBox(height: 20),
          Center(child: _XpChip(xp: _awardedXp)),
        ],
        const SizedBox(height: 32),
        if (passed)
          _PrimaryButton(
            label: _hasNext ? 'NEXT LESSON' : 'BACK TO ACADEMY',
            icon: _hasNext
                ? Icons.arrow_forward_rounded
                : Icons.school_rounded,
            onTap: _continueAfterPass,
          )
        else ...[
          _PrimaryButton(
            label: 'TRY AGAIN',
            icon: Icons.refresh_rounded,
            onTap: _retry,
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'RE-READ THE LESSON',
            onTap: () => context.pop(),
          ),
        ],
      ],
    );
  }

  bool get _hasNext =>
      AcademyProgressService.instance.lessonAfter(widget.lesson.id) != null;

  void _continueAfterPass() {
    final next =
        AcademyProgressService.instance.lessonAfter(widget.lesson.id);
    if (next != null) {
      context.pushReplacement('/learn/lesson', extra: next);
    } else {
      // Pop the quiz and the lesson beneath it, back to the Academy hub.
      context.pop();
    }
  }
}

enum _OptionState { idle, correct, wrong, dimmed, }

class _OptionTile extends StatelessWidget {
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border;
    Color fill;
    Widget? trailing;
    double opacity = 1.0;

    switch (state) {
      case _OptionState.idle:
        border = VxColors.border;
        fill = VxColors.surfaceBright;
        break;
      case _OptionState.correct:
        border = VxColors.neonGreen;
        fill = VxColors.neonGreen.withValues(alpha: 0.12);
        trailing = const Icon(Icons.check_circle_rounded,
            color: VxColors.neonGreen, size: 20);
        break;
      case _OptionState.wrong:
        border = VxColors.neonRed;
        fill = VxColors.neonRed.withValues(alpha: 0.12);
        trailing = const Icon(Icons.cancel_rounded,
            color: VxColors.neonRed, size: 20);
        break;
      case _OptionState.dimmed:
        border = VxColors.border;
        fill = VxColors.surfaceBright;
        opacity = 0.45;
        break;
    }

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: VxTypography.body
                          .copyWith(fontSize: 15, height: 1.35),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final bool correct;
  final String text;

  const _ExplanationCard({required this.correct, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = correct ? VxColors.neonGreen : VxColors.neonYellow;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? 'CORRECT' : 'NOT QUITE',
            style: VxTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(text,
              style: VxTypography.body.copyWith(fontSize: 14.5, height: 1.5)),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const _ProgressDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= current
                    ? VxColors.neonCyan
                    : VxColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

class _XpChip extends StatelessWidget {
  final int xp;
  const _XpChip({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: VxColors.neonCyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: VxColors.neonCyan, size: 18),
          const SizedBox(width: 6),
          Text('+$xp XP',
              style: VxTypography.body.copyWith(
                color: VxColors.neonCyan,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              )),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: VxColors.neonCyan,
          side: const BorderSide(color: VxColors.neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      ),
    );
  }
}

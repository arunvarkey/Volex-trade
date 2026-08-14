import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/features/academy/data/academy_curriculum.dart';
import 'package:volex_terminal/features/academy/models/academy_models.dart';
import 'package:volex_terminal/services/haptic_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import '../models/daily_models.dart';
import '../services/daily_service.dart';

/// Volex Daily — the daily ritual: five quick trading-judgment calls, instant
/// resolution, a streak, and a shareable result. Wordle for traders.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

enum _Phase { loading, intro, playing, done }

class _DailyScreenState extends State<DailyScreen> {
  final DailyService _service = DailyService.instance;

  _Phase _phase = _Phase.loading;
  late DailyChallenge _challenge;
  int _index = 0;
  final List<bool> _correctness = [];
  bool? _choseA; // current call's selection (null = not answered yet)
  DailyResult? _result;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.ensureLoaded();
    _challenge = _service.todayChallenge();
    if (!mounted) return;
    setState(() {
      _phase = _service.hasPlayedToday() ? _Phase.done : _Phase.intro;
    });
  }

  void _start() {
    HapticService.instance.light();
    setState(() {
      _phase = _Phase.playing;
      _index = 0;
      _correctness.clear();
      _choseA = null;
      _result = null;
    });
  }

  DailyCall get _call => _challenge.calls[_index];

  void _answer(bool choseA) {
    if (_choseA != null) return; // already answered this call
    final correct = _call.isCorrect(choseA);
    HapticService.instance.light();
    setState(() {
      _choseA = choseA;
      _correctness.add(correct);
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _challenge.length) {
      setState(() {
        _index += 1;
        _choseA = null;
      });
    } else {
      final result =
          await _service.recordCompletion(_challenge, List.of(_correctness));
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.done;
      });
    }
  }

  void _openLesson(String lessonId) {
    Lesson? lesson;
    for (final l in AcademyCurriculum.allLessons) {
      if (l.id == lessonId) {
        lesson = l;
        break;
      }
    }
    if (lesson != null) context.push('/learn/lesson', extra: lesson);
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
          'VOLEX DAILY',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(
            child: CircularProgressIndicator(color: VxColors.neonCyan));
      case _Phase.intro:
        return _IntroView(challenge: _challenge, onStart: _start);
      case _Phase.playing:
        return _CallView(
          call: _call,
          index: _index,
          total: _challenge.length,
          choseA: _choseA,
          onAnswer: _answer,
          onNext: _next,
          onLearn: _openLesson,
        );
      case _Phase.done:
        return _DoneView(
          result: _result,
          service: _service,
          challenge: _challenge,
        );
    }
  }
}

// ── Intro ───────────────────────────────────────────────────────────

class _IntroView extends StatelessWidget {
  final DailyChallenge challenge;
  final VoidCallback onStart;
  const _IntroView({required this.challenge, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 44), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Volex Daily #${challenge.number}',
              textAlign: TextAlign.center,
              style: VxTypography.h1.copyWith(fontSize: 26)),
          const SizedBox(height: 10),
          Text(
            '${challenge.length} quick calls. About 60 seconds. '
            'Test your trading judgment, keep your streak alive.',
            textAlign: TextAlign.center,
            style: VxTypography.bodySmall.copyWith(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('START TODAY\'S CALLS',
                style: TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }
}

// ── A single call ───────────────────────────────────────────────────

class _CallView extends StatelessWidget {
  final DailyCall call;
  final int index;
  final int total;
  final bool? choseA;
  final ValueChanged<bool> onAnswer;
  final VoidCallback onNext;
  final ValueChanged<String> onLearn;

  const _CallView({
    required this.call,
    required this.index,
    required this.total,
    required this.choseA,
    required this.onAnswer,
    required this.onNext,
    required this.onLearn,
  });

  @override
  Widget build(BuildContext context) {
    final answered = choseA != null;
    final gotItRight = answered && call.isCorrect(choseA!);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress
          Row(
            children: [
              for (int i = 0; i < total; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= index
                          ? VxColors.neonCyan
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('CALL ${index + 1} OF $total',
              style: VxTypography.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 20),
          Text(call.prompt,
              style: VxTypography.h2.copyWith(fontSize: 21, height: 1.3)),
          const SizedBox(height: 10),
          Text(call.context,
              style: VxTypography.bodySmall.copyWith(fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 24),
          _choice(true, call.optionA, answered),
          const SizedBox(height: 12),
          _choice(false, call.optionB, answered),
          const Spacer(),
          if (answered) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (gotItRight ? VxColors.neonGreen : VxColors.neonRed)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (gotItRight ? VxColors.neonGreen : VxColors.neonRed)
                        .withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        gotItRight
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: gotItRight
                            ? VxColors.neonGreen
                            : VxColors.neonRed,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gotItRight ? 'CORRECT' : 'NOT QUITE',
                        style: VxTypography.caption.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: gotItRight
                              ? VxColors.neonGreen
                              : VxColors.neonRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(call.explanation,
                      style: VxTypography.bodySmall
                          .copyWith(fontSize: 13, height: 1.45)),
                  if (!gotItRight && call.lessonId != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => onLearn(call.lessonId!),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded,
                              size: 14, color: VxColors.neonCyan),
                          const SizedBox(width: 5),
                          Text('Learn this in 3 min',
                              style: VxTypography.caption.copyWith(
                                  fontSize: 12,
                                  color: VxColors.neonCyan,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  index + 1 < total ? 'NEXT CALL' : 'SEE RESULTS',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _choice(bool isA, String label, bool answered) {
    final selected = choseA == isA;
    final isCorrectOption = call.correctIsA == isA;

    Color border = Colors.white.withValues(alpha: 0.1);
    Color bg = Colors.white.withValues(alpha: 0.03);
    if (answered) {
      if (isCorrectOption) {
        border = VxColors.neonGreen;
        bg = VxColors.neonGreen.withValues(alpha: 0.10);
      } else if (selected) {
        border = VxColors.neonRed;
        bg = VxColors.neonRed.withValues(alpha: 0.10);
      }
    }

    return GestureDetector(
      onTap: answered ? null : () => onAnswer(isA),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: VxTypography.body
                      .copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            if (answered && isCorrectOption)
              const Icon(Icons.check_rounded,
                  size: 18, color: VxColors.neonGreen),
          ],
        ),
      ),
    );
  }
}

// ── Done / results ──────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  final DailyResult? result;
  final DailyService service;
  final DailyChallenge challenge;

  const _DoneView({
    required this.result,
    required this.service,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    // Either a fresh result (just played) or a "come back tomorrow" state.
    final grid = result?.correctness
            .map((c) => c ? '🟩' : '🟥')
            .join() ??
        '';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result != null) ...[
            Text('${result!.score}/${result!.total}',
                textAlign: TextAlign.center,
                style: VxTypography.hero.copyWith(fontSize: 52)),
            const SizedBox(height: 4),
            Text(grid,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Estimated ${result!.estimatedRank}',
                textAlign: TextAlign.center,
                style: VxTypography.bodySmall.copyWith(fontSize: 13)),
          ] else ...[
            const Text('✅', style: TextStyle(fontSize: 40), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('You\'ve played today',
                textAlign: TextAlign.center,
                style: VxTypography.h2.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text('Come back tomorrow for Volex Daily #${challenge.number + 1}.',
                textAlign: TextAlign.center,
                style: VxTypography.bodySmall.copyWith(fontSize: 13)),
          ],
          const SizedBox(height: 24),
          _StreakRow(service: service),
          const SizedBox(height: 24),
          if (result != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: result!.shareText()));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Result copied — paste it anywhere!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                label: const Text('SHARE RESULT',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  final DailyService service;
  const _StreakRow({required this.service});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat('🔥', '${service.currentStreak}', 'STREAK'),
        _stat('🏆', '${service.bestStreak}', 'BEST'),
        _stat('📅', '${service.playedCount}', 'PLAYED'),
      ],
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: VxTypography.price.copyWith(fontSize: 20)),
        Text(label, style: VxTypography.caption.copyWith(fontSize: 9)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/features/academy/data/academy_curriculum.dart';
import 'package:volex_terminal/features/academy/services/academy_progress_service.dart';
import 'package:volex_terminal/services/haptic_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// First-run welcome card (Duolingo pattern: get the user doing the core
/// thing in under a minute, one obvious action, zero jargon).
///
/// Shows only while the user is brand new — no lessons completed and not
/// dismissed. Disappears forever once either changes.
class FirstUserGuide extends StatefulWidget {
  const FirstUserGuide({super.key});

  @override
  State<FirstUserGuide> createState() => _FirstUserGuideState();
}

class _FirstUserGuideState extends State<FirstUserGuide> {
  static const String _dismissKey = 'first_user_guide_dismissed_v1';

  final AcademyProgressService _academy = AcademyProgressService.instance;
  bool _dismissed = true; // hidden until we know it should show

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _academy.ensureLoaded();
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_dismissKey) ?? false;
      if (mounted) setState(() => _dismissed = dismissed);
    } catch (_) {
      if (mounted) setState(() => _dismissed = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissKey, true);
    } catch (_) {}
  }

  void _startFirstLesson() {
    HapticService.instance.light();
    final first = AcademyCurriculum.allLessons.first;
    context.push('/learn/lesson', extra: first);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _academy,
      builder: (context, _) {
        // Gone once they've started learning or dismissed it.
        if (_dismissed || _academy.completedCount > 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VxColors.neonCyan.withOpacity(0.14),
                  VxColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VxColors.neonCyan.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Welcome to Volex',
                        style: VxTypography.h3.copyWith(fontSize: 18),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            size: 18, color: Colors.white38),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Practice trading with \$100k of virtual money — real market '
                  'data, zero risk. Here\'s the best place to start:',
                  style: VxTypography.bodySmall
                      .copyWith(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startFirstLesson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VxColors.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'TAKE YOUR FIRST LESSON  •  3 MIN',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryChoice(
                        emoji: '📈',
                        label: 'Watch the markets',
                        onTap: () {
                          HapticService.instance.light();
                          context.push('/chart?symbol=BTCUSDT');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SecondaryChoice(
                        emoji: '🔮',
                        label: 'Predict events',
                        onTap: () {
                          HapticService.instance.light();
                          context.go('/predictions');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SecondaryChoice extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _SecondaryChoice({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: VxTypography.bodySmall
                    .copyWith(fontSize: 11.5, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

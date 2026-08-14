import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/services/haptic_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import '../services/daily_service.dart';

/// Home hero for Volex Daily: the daily ritual hook. Shows "Play" when not yet
/// done today, or the current streak once played.
class DailyHomeCard extends StatefulWidget {
  const DailyHomeCard({super.key});

  @override
  State<DailyHomeCard> createState() => _DailyHomeCardState();
}

class _DailyHomeCardState extends State<DailyHomeCard> {
  final DailyService _service = DailyService.instance;

  @override
  void initState() {
    super.initState();
    _service.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final played = _service.hasPlayedToday();
        final number = DailyService.challengeNumber(DateTime.now());
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GestureDetector(
            onTap: () {
              HapticService.instance.light();
              context.push('/daily');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VxColors.neonCyan.withValues(alpha: 0.18),
                    VxColors.neonCyan.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: VxColors.neonCyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🎯', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Volex Daily #$number',
                                style: VxTypography.body
                                    .copyWith(fontWeight: FontWeight.w800)),
                            if (_service.currentStreak > 0) ...[
                              const SizedBox(width: 8),
                              Text('🔥 ${_service.currentStreak}',
                                  style: VxTypography.caption.copyWith(
                                      fontSize: 12,
                                      color: VxColors.neonYellow,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          played
                              ? 'Done today — come back tomorrow'
                              : '5 quick calls · keep your streak alive',
                          style: VxTypography.bodySmall.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: played
                          ? Colors.white.withValues(alpha: 0.08)
                          : VxColors.neonCyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      played ? 'DONE' : 'PLAY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: played ? Colors.white54 : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../engine/replay_controller.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';
import 'package:intl/intl.dart';
import 'screens/script_editor_screen.dart';
import 'package:provider/provider.dart';
import '../../core/service_locator.dart';
import '../../engine/sandbox/python_sandbox_service.dart';
import '../../engine/chart_controller.dart';
import '../../features/subscriptions/services/subscription_service.dart'; // [NEW] For gating
// [NEW] For upgrade path

class ReplayPanel extends StatelessWidget {
  final ReplayController controller;

  const ReplayPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 118,
      left: 12,
      right: 12,
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final dateStr = controller.currentDate != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(controller.currentDate!)
                : "Loading…";

            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(VxSpacing.lg),
                  decoration: BoxDecoration(
                    color: VxColors.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: VxColors.primary.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_toggle_off,
                                  color: VxColors.primary, size: 16),
                              const SizedBox(width: 8),
                              VxText.bodyBold("Replay",
                                  color: VxColors.primary, fontSize: 14),
                            ],
                          ),
                          VxText.mono(dateStr,
                              color: Colors.white, fontSize: 12),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Scrubber
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: VxColors.primary,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                          trackHeight: 2,
                          overlayColor: VxColors.primary.withValues(alpha: 0.1),
                        ),
                        child: Slider(
                          value: controller.progress,
                          onChanged: (val) {
                            controller.seekTo(val);
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Play/Pause
                          IconButton(
                            onPressed: controller.togglePlayPause,
                            icon: Icon(
                              controller.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  VxColors.primary.withValues(alpha: 0.1),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),

                          // Speed Toggles
                          Row(
                            children: [
                              // [NEW] Code Editor Button
                              IconButton(
                                onPressed: () async {
                                  // [NEW] Gating Logic - Elite Feature
                                  final subService =
                                      context.read<SubscriptionService>();
                                  if (!subService.currentStatus.isPremium) {
                                    // Not Elite? Show Paywall
                                    context.push('/subscription');
                                    return;
                                  }

                                  // Navigate to Script Editor and wait for result
                                  final script =
                                      await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ScriptEditorScreen(),
                                    ),
                                  );

                                  // If user hit "SIMULATE" (returned a script string)
                                  if (script != null &&
                                      script is String &&
                                      context.mounted) {
                                    try {
                                      // 1. Get Service
                                      final service =
                                          getIt<PythonSandboxService>();

                                      // 2. Run Hyper-Threaded Simulation
                                      // Using full history from controller
                                      final signals =
                                          await service.simulateStrategy(
                                        script: script,
                                        history: controller.fullHistory,
                                      );

                                      if (context.mounted) {
                                        // 3. Update Chart
                                        final chart =
                                            context.read<ChartController>();
                                        chart.clearSignals();
                                        for (final s in signals) {
                                          chart.addSignal(s);
                                        }

                                        // 4. Feedback
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              "Hyper-Thread Complete: ${signals.length} Signals Generated"),
                                          backgroundColor: VxColors.neonGreen,
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text("Error: $e"),
                                                backgroundColor:
                                                    VxColors.neonRed));
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.code,
                                    color: VxColors.neonCyan),
                                tooltip: 'Edit Strategy',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      VxColors.neonCyan.withValues(alpha: 0.2),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                              const SizedBox(width: 12),

                              _SpeedButton(
                                  label: "1x",
                                  speed: ReplaySpeed.x1,
                                  current: controller.speed,
                                  onTap: controller.setSpeed),
                              _SpeedButton(
                                  label: "2x",
                                  speed: ReplaySpeed.x2,
                                  current: controller.speed,
                                  onTap: controller.setSpeed),
                              _SpeedButton(
                                  label: "5x",
                                  speed: ReplaySpeed.x5,
                                  current: controller.speed,
                                  onTap: controller.setSpeed),
                              _SpeedButton(
                                  label: "10x",
                                  speed: ReplaySpeed.x10,
                                  current: controller.speed,
                                  onTap: controller.setSpeed),
                              _SpeedButton(
                                  label: "50x",
                                  speed: ReplaySpeed.x50,
                                  current: controller.speed,
                                  onTap: controller.setSpeed),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final ReplaySpeed speed;
  final ReplaySpeed current;
  final Function(ReplaySpeed) onTap;

  const _SpeedButton({
    required this.label,
    required this.speed,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = speed == current;
    return GestureDetector(
      onTap: () => onTap(speed),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? VxColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isSelected ? VxColors.primary : Colors.white10),
        ),
        child: VxText.monoBold(
          label,
          color: isSelected ? Colors.black : Colors.white38,
          fontSize: 10,
        ),
      ),
    );
  }
}

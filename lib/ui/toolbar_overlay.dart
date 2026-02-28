import 'dart:ui';
import 'package:flutter/material.dart';
import '../engine/chart_controller.dart';
import '../engine/execution_manager.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';

class ToolbarOverlay extends StatelessWidget {
  final ChartController controller;
  final ExecutionManager executionManager;
  final VoidCallback? onBacktest;
  final VoidCallback? onOptimize;
  final VoidCallback? onGenetic;
  final VoidCallback? onAutoTune;
  final VoidCallback? onToggleLive;
  final bool isLiveMode;

  const ToolbarOverlay({
    super.key,
    required this.controller,
    required this.executionManager,
    this.onBacktest,
    this.onOptimize,
    this.onGenetic,
    this.onAutoTune,
    this.onToggleLive,
    this.isLiveMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: VxColors.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 0. SIM/LIVE Switch
                    Row(
                      children: [
                        _ModeButton(
                          label: "SIM",
                          isActive: !isLiveMode,
                          color: Colors.white24,
                          onTap: !isLiveMode ? null : onToggleLive,
                        ),
                        _ModeButton(
                          label: "PRO",
                          isActive: isLiveMode,
                          color: VxColors.neonRed,
                          onTap: isLiveMode ? null : onToggleLive,
                        ),
                      ],
                    ),

                    _Divider(),

                    // 1. Crosshair Toggle
                    _ToolbarButton(
                      icon: Icons.gps_fixed,
                      label: "X-HAIR",
                      isActive: true,
                      onTap: () {},
                    ),

                    _Divider(),

                    _ToolbarButton(
                      icon: Icons.bolt,
                      label: "OPTIMIZE",
                      isActive: true,
                      color: VxColors.neonMagenta,
                      onTap: onOptimize,
                    ),

                    _Divider(),

                    _ToolbarButton(
                      icon: Icons.psychology,
                      label: "AUTOTUNE",
                      isActive: true,
                      color: VxColors.neonMagenta,
                      onTap: onAutoTune,
                    ),

                    _Divider(),

                    _ToolbarButton(
                      icon: Icons.auto_awesome,
                      label: "GENETIC",
                      isActive: true,
                      color: VxColors.neonCyan,
                      onTap: onGenetic,
                    ),

                    _Divider(),

                    _ToolbarButton(
                      icon: Icons.science,
                      label: "BACKTEST",
                      isActive: true,
                      color: VxColors.neonCyan,
                      onTap: onBacktest,
                    ),

                    _Divider(),

                    // 2. Zone Actions
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final hasSelection =
                            controller.selectedZoneIndex != null;
                        return Row(
                          children: [
                            _ToolbarButton(
                              icon: Icons.delete_outline,
                              label: "DELETE",
                              isActive: hasSelection,
                              color: hasSelection
                                  ? VxColors.neonRed
                                  : Colors.white24,
                              onTap: hasSelection
                                  ? controller.deleteSelectedZone
                                  : null,
                            ),
                            _Divider(),
                            _ToolbarButton(
                              icon: Icons.clear_all,
                              label: "CLEAR",
                              isActive: controller.zones.isNotEmpty,
                              onTap: () {
                                controller.clearZones();
                              },
                            ),
                            _Divider(),
                            _ToolbarButton(
                              icon: Icons.close_fullscreen,
                              label: "CLOSE ALL",
                              isActive: true,
                              onTap: () {
                                if (controller.allCandles.isNotEmpty) {
                                  executionManager.closeAllOrders(
                                      controller.allCandles.last.close);
                                }
                              },
                              color: VxColors.neonRed,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final finalColor = color ?? (isActive ? Colors.white : Colors.white24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: finalColor, size: 18),
              const SizedBox(height: 4),
              VxText.monoBold(
                label,
                color: finalColor,
                fontSize: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : Colors.white10,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: VxText.monoBold(
          label,
          fontSize: 8,
          color: isActive ? color : Colors.white24,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withOpacity(0.05),
    );
  }
}

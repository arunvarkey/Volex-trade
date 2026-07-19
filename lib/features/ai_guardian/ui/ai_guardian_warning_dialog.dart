import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:volex_terminal/features/ai_guardian/models/trade_analysis.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';

class AIGuardianWarningDialog extends StatelessWidget {
  final TradeAnalysis analysis;

  const AIGuardianWarningDialog({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Transparent for Glassmorphism
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: VxColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VxColors.neutral800),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with warning icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: VxColors.neonRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: VxColors.neonRed,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Guardian Alert',
                              style: TextStyle(
                                color: VxColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Potential risk detected',
                              style: TextStyle(
                                color: VxColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Risk meter
                  _buildRiskMeter(),

                  const SizedBox(height: 24),

                  // Emotional state warning
                  if (analysis.emotionalState != EmotionalState.calm)
                    _buildEmotionalWarning(),

                  // Pattern warnings
                  if (analysis.patterns.isNotEmpty)
                    ...analysis.patterns.map(_buildPatternWarning),

                  const SizedBox(height: 24),

                  // AI Recommendation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: VxColors.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: VxColors.neonCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb,
                                color: VxColors.neonCyan, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'AI Recommendation',
                              style: TextStyle(
                                color: VxColors.neonCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          analysis.recommendation,
                          style: const TextStyle(
                              color: VxColors.textPrimary, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VxColors.textSecondary,
                            side: const BorderSide(color: VxColors.neutral700),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('I Understand the Risk'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VxColors.neonCyan,
                            foregroundColor: VxColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel Trade'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskMeter() {
    Color color;
    String label;

    if (analysis.riskScore < 30) {
      color = VxColors.success;
      label = 'Low Risk';
    } else if (analysis.riskScore < 60) {
      color = VxColors.warning;
      label = 'Moderate Risk';
    } else {
      color = VxColors.danger;
      label = 'High Risk';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Risk Score',
                style: TextStyle(color: VxColors.textPrimary)),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: analysis.riskScore / 100,
            backgroundColor: VxColors.neutral800,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${analysis.riskScore.toStringAsFixed(0)}/100',
          style: const TextStyle(color: VxColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmotionalWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: VxColors.danger, size: 20),
              SizedBox(width: 8),
              Text(
                'Emotional State Detected',
                style: TextStyle(
                  color: VxColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.emotionalState.name,
            style: const TextStyle(
              color: VxColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analysis.emotionalState.description,
            style: const TextStyle(color: VxColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternWarning(PatternWarning pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_down,
                  color: VxColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                pattern.name,
                style: const TextStyle(
                  color: VxColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pattern.description,
            style: const TextStyle(color: VxColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: VxColors.neutral800,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Historical win rate: ${pattern.historicalWinRate.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: VxColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

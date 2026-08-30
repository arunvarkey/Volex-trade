import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/vx_colors.dart';
import '../../engine/execution_manager.dart';
import '../wizard/smart_strategy_wizard.dart';

class TerminalTopBar extends StatelessWidget {
  final String currentSymbol;
  final double currentPrice;
  final bool isReplayMode;
  final VoidCallback onToggleReplay;
  final VoidCallback onShowSymbolPicker;
  final VoidCallback onShowAlerts;

  const TerminalTopBar({
    super.key,
    required this.currentSymbol,
    required this.currentPrice,
    required this.isReplayMode,
    required this.onToggleReplay,
    required this.onShowSymbolPicker,
    required this.onShowAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: VxColors.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // App Icon - Compact
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [VxColors.neonCyan, VxColors.neonPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
          ),

          const SizedBox(width: 8),

          // Symbol
          Expanded(
            flex: 3,
            child: _buildSymbolSelector(),
          ),

          const SizedBox(width: 4),

          // Price - Flexible
          Expanded(
            flex: 4,
            child: _buildPriceDisplay(),
          ),

          const SizedBox(width: 4),

          // Mode
          _buildModeIndicator(context),

          const SizedBox(width: 4),

          // Alerts Button
          _buildAlertsButton(),

          const SizedBox(width: 4),

          // Strategy wizard (template-driven, not a model)
          _buildStrategyWizardButton(context),

          const SizedBox(width: 4),

          // Replay Toggle
          InkWell(
            onTap: onToggleReplay,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isReplayMode ? VxColors.neonCyan : Colors.transparent,
                border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.history,
                color: isReplayMode ? Colors.black : VxColors.neonCyan,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolSelector() {
    return InkWell(
      onTap: onShowSymbolPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: VxColors.deepBlack,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                currentSymbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LAST',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 8,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                '\$${currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                '+2.3%',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeIndicator(BuildContext context) {
    final executionManager = context.watch<ExecutionManager?>();
    final isPaper = executionManager?.isLiveMode != true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isPaper
            ? VxColors.neonCyan.withValues(alpha: 0.1)
            : VxColors.neonRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaper ? VxColors.neonCyan : VxColors.neonRed,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPaper ? VxColors.neonCyan : VxColors.neonRed,
              boxShadow: [
                BoxShadow(
                  color: isPaper ? VxColors.neonCyan : VxColors.neonRed,
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isPaper ? 'PAPER' : 'LIVE',
            style: TextStyle(
              color: isPaper ? VxColors.neonCyan : VxColors.neonRed,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsButton() {
    return InkWell(
      onTap: onShowAlerts,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: VxColors.neonCyan.withValues(alpha: 0.1),
          border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.notifications_active,
            color: VxColors.neonCyan, size: 16),
      ),
    );
  }

  Widget _buildStrategyWizardButton(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => const SmartStrategyWizard(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [VxColors.neonPurple, VxColors.neonMagenta],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.tune, color: Colors.white, size: 16),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/terminal_settings_provider.dart';
import 'package:volex_terminal/ui/parameters/parameter_editor.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_card.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';
import 'package:volex_terminal/core/app_logger.dart';

import 'package:volex_terminal/engine/strategy/strategy_engine.dart';

class ParametersTab extends StatelessWidget {
  final String strategyId;
  const ParametersTab({super.key, required this.strategyId});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<TerminalSettingsProvider>();
    final engine = context.watch<StrategyEngine>();

    final strategy = engine.allStrategies.firstWhere((s) => s.id == strategyId,
        orElse: () => engine.allStrategies.first);
    final schemas = strategy.parameters;
    final currentValues = strategy.currentParameterValues;

    return ListView(
      padding: const EdgeInsets.all(VxSpacing.md),
      children: [
        VxCard(
          title: VxText.subtitle("STRATEGY PARAMETERS",
              color:
                  settings.isProMode ? VxColors.neonCyan : VxColors.neonPurple),
          description: settings.isProMode
              ? "Advanced controls enabled. Type safety and bounds enforced."
              : "Read-only view. Enable Pro Mode to modify parameters.",
          action: Icon(
            settings.isProMode ? Icons.edit_note : Icons.lock_outline,
            color: settings.isProMode ? VxColors.neonCyan : Colors.white38,
          ),
          child: ParameterEditor(
            schemas: schemas,
            currentValues: currentValues,
            isEditable: settings.isProMode,
            onValuesChanged: (values) {
              engine.updateStrategyParams(strategyId, values);
              AppLogger.info("Parameters Updated via Control Room: $values");
            },
          ),
        ),
        if (settings.isProMode) ...[
          const SizedBox(height: VxSpacing.md),
          VxCard(
            title:
                VxText.subtitle("SAFETY OVERRIDES", color: Colors.orangeAccent),
            child: Column(
              children: [
                _buildToggleRow("Emergency Kill Switch", true),
                _buildToggleRow("Halt on 5% Drawdown", true),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VxText.body(label, color: Colors.white70),
          Switch(
              value: value,
              onChanged: (v) {},
              activeThumbColor: Colors.orangeAccent),
        ],
      ),
    );
  }
}

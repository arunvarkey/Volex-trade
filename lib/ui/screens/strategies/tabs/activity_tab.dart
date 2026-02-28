import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/ui/design_system/vx_log_list.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<StrategyEngine>();

    final logs = engine.logHistory.reversed.map((l) {
      VxLogSeverity severity = VxLogSeverity.info;
      if (l.action == "ORDER" || l.action == "FILL") {
        severity = VxLogSeverity.success;
      }
      if (l.action == "ERROR" || l.action == "REJECT") {
        severity = VxLogSeverity.error;
      }
      if (l.action == "SIGNAL" || l.action == "TRIGGER") {
        severity = VxLogSeverity.debug;
      }
      if (l.action == "WARNING") severity = VxLogSeverity.warning;

      return VxLogEntry(
        message: l.message,
        timestamp: l.timestamp,
        severity: severity,
        metadata:
            "Action: ${l.action}\nStrategy: ${l.strategyName}\nID: ${l.strategyId}",
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(VxSpacing.md),
      child: VxLogList(logs: logs),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../engine/strategy/strategy_engine.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';
import 'package:intl/intl.dart';

class StrategyLogPanel extends StatelessWidget {
  final StrategyEngine strategyEngine;

  const StrategyLogPanel({super.key, required this.strategyEngine});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 16,
      width: 320,
      height: 220,
      child: Container(
        padding: const EdgeInsets.all(VxSpacing.md),
        decoration: BoxDecoration(
          color: VxColors.surface.withOpacity(0.8),
          border: Border.all(color: VxColors.neonCyan.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: VxColors.neonCyan, size: 14),
                const SizedBox(width: 8),
                VxText.monoBold("STRATEGY_ENGINE",
                    color: VxColors.neonCyan, fontSize: 11),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Expanded(
              child: _LogList(stream: strategyEngine.allLogs),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogList extends StatefulWidget {
  final Stream<StrategyLog> stream;
  const _LogList({required this.stream});

  @override
  State<_LogList> createState() => _LogListState();
}

class _LogListState extends State<_LogList> {
  final List<StrategyLog> _logs = [];
  late StreamSubscription _sub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.insert(0, log);
          if (_logs.length > 50) _logs.removeLast();
        });
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_logs.isEmpty) {
      return Center(
          child: VxText.body("AWAITING_ACTIVITY",
              color: Colors.white10, fontSize: 10));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final timeStr = DateFormat('HH:mm:ss').format(log.timestamp);

        Color actionColor = Colors.white70;
        if (log.action == "BUY") actionColor = VxColors.neonGreen;
        if (log.action == "SELL") actionColor = VxColors.neonRed;
        if (log.action.contains("CLOSE")) actionColor = VxColors.warning;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VxText.mono("[$timeStr]", color: Colors.white24, fontSize: 9),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VxText.monoBold("${log.strategyName} // ${log.action}",
                        color: actionColor, fontSize: 10),
                    const SizedBox(height: 2),
                    VxText.body(log.message,
                        color: Colors.white54, fontSize: 10, maxLines: 2),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

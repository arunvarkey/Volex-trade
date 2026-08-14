import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';

class VxLogEntry {
  final String message;
  final DateTime timestamp;
  final VxLogSeverity severity;
  final String? metadata; // JSON or raw log data

  VxLogEntry({
    required this.message,
    required this.timestamp,
    required this.severity,
    this.metadata,
  });
}

enum VxLogSeverity { info, warning, error, success, debug }

class VxLogList extends StatelessWidget {
  final List<VxLogEntry> logs;
  final ScrollController? controller;

  const VxLogList({super.key, required this.logs, this.controller});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
          child: VxText.body("No logs matched current filters",
              color: Colors.white24));
    }

    return ListView.separated(
      controller: controller,
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final log = logs[index];
        return _VxLogTile(log: log);
      },
    );
  }
}

class _VxLogTile extends StatefulWidget {
  final VxLogEntry log;

  const _VxLogTile({required this.log});

  @override
  State<_VxLogTile> createState() => _VxLogTileState();
}

class _VxLogTileState extends State<_VxLogTile> {
  bool _isExpanded = false;

  Color get _color {
    switch (widget.log.severity) {
      case VxLogSeverity.info:
        return VxColors.textSecondary;
      case VxLogSeverity.warning:
        return VxColors.warning;
      case VxLogSeverity.error:
        return VxColors.danger;
      case VxLogSeverity.success:
        return VxColors.success;
      case VxLogSeverity.debug:
        return VxColors.neonCyan;
    }
  }

  IconData get _icon {
    switch (widget.log.severity) {
      case VxLogSeverity.info:
        return Icons.info_outline;
      case VxLogSeverity.warning:
        return Icons.warning_amber;
      case VxLogSeverity.error:
        return Icons.error_outline;
      case VxLogSeverity.success:
        return Icons.check_circle_outline;
      case VxLogSeverity.debug:
        return Icons.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.log.metadata != null
              ? () => setState(() => _isExpanded = !_isExpanded)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VxText.mono(
                  "${widget.log.timestamp.hour.toString().padLeft(2, '0')}:${widget.log.timestamp.minute.toString().padLeft(2, '0')}:${widget.log.timestamp.second.toString().padLeft(2, '0')}",
                  color: VxColors.textTertiary,
                  fontSize: 10,
                ),
                const SizedBox(width: VxSpacing.sm),
                Icon(_icon, color: _color, size: 12),
                const SizedBox(width: VxSpacing.xs),
                Expanded(
                  child: VxText.mono(
                    widget.log.message,
                    color: _color,
                  ),
                ),
                if (widget.log.metadata != null)
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white24,
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
        if (_isExpanded && widget.log.metadata != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 60, top: 4, bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white10),
            ),
            child: VxText.mono(
              widget.log.metadata!,
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

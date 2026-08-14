import 'package:flutter/material.dart';
import '../../vx_colors.dart';
import 'vx_drawing_models.dart';

/// Floating toolbar for drawing tools
class VxDrawingToolbar extends StatefulWidget {
  final DrawingTool selectedTool;
  final Function(DrawingTool) onToolSelected;
  final VoidCallback onClearAll;
  final VoidCallback onUndo;
  final bool hasDrawings;

  const VxDrawingToolbar({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
    required this.onClearAll,
    required this.onUndo,
    this.hasDrawings = false,
  });

  @override
  State<VxDrawingToolbar> createState() => _VxDrawingToolbarState();
}

class _VxDrawingToolbarState extends State<VxDrawingToolbar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tool selector button
        FloatingActionButton.small(
          heroTag: 'drawing_tools',
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          backgroundColor: VxColors.surface,
          child: Icon(
            _isExpanded ? Icons.close : Icons.draw,
            color: widget.selectedTool != DrawingTool.none
                ? widget.selectedTool.color
                : VxColors.neonCyan,
          ),
        ),

        // Expanded toolbar
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VxColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: VxColors.neonCyan.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Row(
                  children: [
                    Icon(Icons.draw, color: VxColors.neonCyan, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'DRAWING TOOLS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tool buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildToolButton(DrawingTool.none),
                    _buildToolButton(DrawingTool.horizontalLine),
                    _buildToolButton(DrawingTool.trendLine),
                    _buildToolButton(DrawingTool.fibonacci),
                    _buildToolButton(DrawingTool.rectangle),
                  ],
                ),

                if (widget.hasDrawings) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.undo,
                          label: 'Undo',
                          onPressed: widget.onUndo,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Clear',
                          onPressed: () => _showClearConfirmation(context),
                          color: VxColors.neonRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // Quick indicator when tool is selected
        if (!_isExpanded && widget.selectedTool != DrawingTool.none)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selectedTool.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.selectedTool.color.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.selectedTool.icon,
                  color: widget.selectedTool.color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.selectedTool.label,
                  style: TextStyle(
                    color: widget.selectedTool.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildToolButton(DrawingTool tool) {
    final isSelected = widget.selectedTool == tool;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onToolSelected(tool),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? tool.color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? tool.color : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tool.icon,
                color: isSelected ? tool.color : Colors.white54,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                tool.label,
                style: TextStyle(
                  color: isSelected ? tool.color : Colors.white38,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: VxColors.warning, size: 24),
            SizedBox(width: 12),
            Text(
              'Clear All Drawings?',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'This will remove all drawings from the chart. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onClearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

/// Drawing info panel - shows instructions
class VxDrawingInfoPanel extends StatelessWidget {
  final DrawingTool selectedTool;

  const VxDrawingInfoPanel({
    super.key,
    required this.selectedTool,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTool == DrawingTool.none) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: selectedTool.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedTool.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(selectedTool.icon, color: selectedTool.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getInstructions(selectedTool),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInstructions(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.horizontalLine:
        return 'Tap anywhere on the chart to place a horizontal line';
      case DrawingTool.trendLine:
        return 'Tap to set start point, then tap again for end point';
      case DrawingTool.fibonacci:
        return 'Tap swing low, then tap swing high to draw Fibonacci levels';
      case DrawingTool.rectangle:
        return 'Tap top-left corner, then tap bottom-right corner';
      case DrawingTool.none:
        return '';
    }
  }
}

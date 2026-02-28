import 'package:flutter/material.dart';
import '../engine/chart_controller.dart';
import '../ui/design_system/vx_colors.dart';

class TradeZonePainter {
  static void paint(Canvas canvas, Size size, ChartController controller) {
    for (final zone in controller.zones) {
      final x1 = controller.indexToX(zone.startIndex);
      final x2 = controller.indexToX(zone.endIndex);

      final y1 = controller.priceToY(zone.maxPrice, size.height);
      final y2 = controller.priceToY(zone.minPrice, size.height);

      final rect = Rect.fromPoints(Offset(x1, y1), Offset(x2, y2));

      final isSelected = controller.selectedZoneIndex != null &&
          controller.zones.indexOf(zone) == controller.selectedZoneIndex;

      final color = zone.isTriggered ? VxColors.neonRed : VxColors.neonMagenta;

      if (isSelected || zone.isTriggered) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawRect(rect, glowPaint);
      }

      final fillPaint = Paint()
        ..color = isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.0;
      canvas.drawRect(rect, borderPaint);
    }

    if (controller.isDrawing &&
        controller.activeDragStart != null &&
        controller.activeDragEnd != null) {
      final rect = Rect.fromPoints(
          controller.activeDragStart!, controller.activeDragEnd!);

      final paint = Paint()
        ..color = VxColors.neonCyan.withOpacity(0.15)
        ..style = PaintingStyle.fill;

      final border = Paint()
        ..color = VxColors.neonCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, border);
    }
  }
}

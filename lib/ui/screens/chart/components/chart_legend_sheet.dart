import 'package:flutter/material.dart';

import 'package:volex_terminal/core/glossary.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/widgets/glossary_sheet.dart';

/// "What are all these lines?" — a key to everything the chart draws.
///
/// The chart paints candles, two moving averages, a volume histogram and an
/// RSI pane, labelling them on the canvas as SMA20, SMA50, Vol and RSI(14).
/// Those labels identify the lines to someone who already knows what they
/// are, and to everyone else they are four pieces of unexplained shorthand on
/// the app's main screen. Nothing on the chart could be tapped to find out,
/// because the whole thing is one painted canvas.
class ChartLegendSheet {
  const ChartLegendSheet._();

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: VxColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("What's on this chart",
                  style: VxTypography.h2.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Tap any row for a fuller explanation.',
                style: VxTypography.caption,
              ),
              const SizedBox(height: 18),
              const _LegendRow(
                swatch: _Swatch.candle,
                title: 'The bars',
                body: 'Each bar is one period of trading. Green means the '
                    'price finished higher than it started, red means lower. '
                    'The thin lines above and below reach the highest and '
                    'lowest price in that period.',
                termId: 'candlestick',
              ),
              const _LegendRow(
                swatch: _Swatch.line,
                color: VxColors.neonCyan,
                title: 'SMA 20 — the cyan line',
                body: 'The average price over the last 20 bars. It smooths '
                    'out the noise so the underlying direction is easier to '
                    'see.',
                termId: 'sma',
              ),
              const _LegendRow(
                swatch: _Swatch.line,
                color: VxColors.neonPurple,
                title: 'SMA 50 — the purple line',
                body: 'The same idea over 50 bars, so it moves more slowly. '
                    'When the faster line crosses it, that is often read as a '
                    'change of trend.',
                termId: 'sma',
              ),
              const _LegendRow(
                swatch: _Swatch.bars,
                title: 'Vol — the bars underneath',
                body: 'How much was traded in each period. A big move on high '
                    'volume means more people agreed with it; the same move '
                    'on low volume is weaker.',
                termId: 'volume',
              ),
              const _LegendRow(
                swatch: _Swatch.line,
                color: VxColors.neonYellow,
                title: 'RSI — the panel at the bottom',
                body: 'A 0–100 gauge of how hard the price has been pushed '
                    'recently. Above 70 it is often called overbought, below '
                    '30 oversold — but a strong trend can sit at either end '
                    'for a long time.',
                termId: 'rsi',
              ),
              const _LegendRow(
                swatch: _Swatch.dashed,
                title: 'The dashed line across the chart',
                body: 'The most recent price, so you can see at a glance '
                    'where the market is now relative to everything before '
                    'it.',
              ),
              const SizedBox(height: 8),
              Text(
                'None of these predict anything. They are ways of describing '
                'what price has already done — useful for spotting a '
                'situation, never a reason on their own to trade.',
                style: VxTypography.caption.copyWith(
                  color: VxColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VxColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Swatch { candle, line, bars, dashed }

class _LegendRow extends StatelessWidget {
  final _Swatch swatch;
  final Color? color;
  final String title;
  final String body;
  final String? termId;

  const _LegendRow({
    required this.swatch,
    required this.title,
    required this.body,
    this.color,
    this.termId,
  });

  @override
  Widget build(BuildContext context) {
    final hasTerm = termId != null && Glossary.has(termId!);
    return InkWell(
      onTap: hasTerm ? () => GlossarySheet.show(context, termId!) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              height: 20,
              child: CustomPaint(
                painter: _SwatchPainter(
                  swatch: swatch,
                  color: color ?? VxColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: VxTypography.body
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (hasTerm) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.help_outline_rounded,
                            size: 14,
                            color: VxColors.textTertiary
                                .withValues(alpha: 0.8)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: VxTypography.bodySmall.copyWith(
                      color: VxColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a miniature of the thing being described, so the row can be matched
/// to the chart by eye rather than by reading a colour name.
class _SwatchPainter extends CustomPainter {
  final _Swatch swatch;
  final Color color;

  _SwatchPainter({required this.swatch, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    switch (swatch) {
      case _Swatch.candle:
        _candle(canvas, 7, size, VxColors.chartUp, 0.30, 0.72);
        _candle(canvas, 19, size, VxColors.chartDown, 0.15, 0.60);
      case _Swatch.line:
        final path = Path()
          ..moveTo(0, size.height * 0.75)
          ..cubicTo(size.width * 0.35, size.height * 0.1,
              size.width * 0.6, size.height * 0.95, size.width, midY * 0.55);
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..isAntiAlias = true,
        );
      case _Swatch.bars:
        for (final (dx, h) in [(4.0, 0.35), (11.0, 0.75), (18.0, 0.5)]) {
          canvas.drawRect(
            Rect.fromLTWH(dx, size.height * (1 - h), 5, size.height * h),
            Paint()..color = VxColors.chartUp.withValues(alpha: 0.45),
          );
        }
      case _Swatch.dashed:
        final paint = Paint()
          ..color = VxColors.neonGreen
          ..strokeWidth = 1.6;
        for (double x = 0; x < size.width; x += 6) {
          canvas.drawLine(
              Offset(x, midY), Offset(x + 3.5, midY), paint);
        }
    }
  }

  void _candle(Canvas canvas, double cx, Size size, Color c, double top,
      double bottom) {
    final paint = Paint()..color = c;
    canvas.drawRect(
      Rect.fromLTWH(cx - 0.6, size.height * (top - 0.18), 1.2,
          size.height * ((bottom + 0.16) - (top - 0.18))),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - 2.6, size.height * top, 5.2,
          size.height * (bottom - top)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SwatchPainter old) =>
      old.swatch != swatch || old.color != color;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'vx_colors.dart';
import 'vx_skeleton.dart';

/// Loading states for Volex.
///
/// ## When a spinner is the wrong answer
///
/// A centred spinner says one thing: *something is happening*. It cannot say
/// what is coming, how much of it there is, or how close it is — so the user
/// has nothing to do but wait and watch. Then the content arrives, the spinner
/// vanishes, the layout snaps to a completely different height, and whatever
/// they were about to tap has moved.
///
/// A skeleton answers all of that by being the shape of the thing that is
/// loading. Six rows of skeleton say "six markets, each with a symbol, a name
/// and a price". The eye starts parsing the layout before the data lands, the
/// data lands into the space already reserved for it, and nothing jumps. That
/// is the whole trick, and it is why every serious trading and finance client
/// uses it: the wait stops being dead time and becomes the first frame of the
/// screen.
///
/// So the rule in this codebase:
///
/// * **The shape is known** — a list of markets, a feed of signals, a chart, a
///   page of cards. Draw the shape: [VxListSkeleton], [VxCardListSkeleton],
///   [VxChartSkeleton].
/// * **The shape is not known, and the wait is short and inside a control the
///   user just pressed** — a form submitting, an order confirming. A spinner is
///   right, because the only question is "did my tap register". Use
///   [VxInlineSpinner], which is sized for a button rather than for a page.
///
/// A determinate ring showing a real value — the gauges in `VxMetricGauge` —
/// is neither of these. It is a chart, and it stays.
///
/// ## One warning about skeletons
///
/// A skeleton animates forever if the load never finishes, and a shimmering
/// ghost of content that is never going to arrive is worse than a spinner: it
/// looks like the app is working when it has in fact failed. Every caller here
/// clears its loading flag in a `finally` and has an error or empty state to
/// fall through to. A new caller must do the same.

/// One line of placeholder text, sized as a fraction of the available width.
///
/// Lines are deliberately uneven across a skeleton. A block of identical bars
/// reads as a loading graphic; varied lengths read as text, which is what the
/// user is about to get.
class VxSkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const VxSkeletonLine({
    super.key,
    this.widthFactor = 1,
    this.height = 11,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor.clamp(0.0, 1.0).toDouble(),
      child: VxSkeleton(
        width: double.infinity,
        height: height,
        borderRadius: height / 2,
      ),
    );
  }
}

/// Placeholder for a list of rows that each carry an icon, two lines of text
/// and a right-aligned figure — the market list, the signal feed, a holdings
/// table.
///
/// [rowHeight] should match the real row so the content does not shift when it
/// arrives. Getting it wrong by a few pixels is harmless; getting it wrong by
/// forty undoes the reason for using a skeleton at all.
class VxListSkeleton extends StatelessWidget {
  final int rows;
  final double rowHeight;
  final bool showLeading;
  final bool showTrailing;
  final bool dividers;
  final EdgeInsetsGeometry padding;

  const VxListSkeleton({
    super.key,
    this.rows = 6,
    this.rowHeight = 64,
    this.showLeading = true,
    this.showTrailing = true,
    this.dividers = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    // Repeating widths, so each row differs from its neighbour without any of
    // it being random — a skeleton that reshuffles on every rebuild flickers.
    const titleWidths = <double>[0.42, 0.3, 0.52, 0.36, 0.46, 0.33];
    const subtitleWidths = <double>[0.62, 0.74, 0.55, 0.68, 0.58, 0.7];

    return _LoadingSemantics(
      child: LayoutBuilder(builder: (context, constraints) {
        // Fit the space rather than insisting on [rows]. A Column of fixed
        // heights taller than its parent is a layout overflow, and this gets
        // dropped into an Expanded on one screen and an unbounded Column on
        // another. Where the height is known, draw what fits; where it is
        // not, draw the asking number.
        final int visible = constraints.maxHeight.isFinite
            ? math.max(
                1, math.min(rows, (constraints.maxHeight / (rowHeight + 1)).floor()))
            : rows;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < visible; i++) ...[
            if (dividers && i > 0)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.white10,
              ),
            SizedBox(
              height: rowHeight,
              child: Padding(
                padding: padding,
                child: Row(
                  children: [
                    if (showLeading) ...[
                      const VxSkeleton(width: 36, height: 36, borderRadius: 18),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VxSkeletonLine(
                            widthFactor: titleWidths[i % titleWidths.length],
                            height: 12,
                          ),
                          const SizedBox(height: 7),
                          VxSkeletonLine(
                            widthFactor:
                                subtitleWidths[i % subtitleWidths.length],
                            height: 9,
                          ),
                        ],
                      ),
                    ),
                    if (showTrailing) ...[
                      const SizedBox(width: 12),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          VxSkeleton(width: 68, height: 12),
                          SizedBox(height: 7),
                          VxSkeleton(width: 44, height: 9),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
        );
      }),
    );
  }
}

/// Placeholder for a page of cards — marketplace strategies, insight cards,
/// subscription tiers.
class VxCardListSkeleton extends StatelessWidget {
  final int cards;
  final double cardHeight;
  final EdgeInsetsGeometry padding;

  const VxCardListSkeleton({
    super.key,
    this.cards = 4,
    this.cardHeight = 108,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return _LoadingSemantics(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => Container(
          height: cardHeight,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VxColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const VxSkeleton(width: 32, height: 32, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VxSkeletonLine(
                      widthFactor: i.isEven ? 0.5 : 0.38,
                      height: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const VxSkeletonLine(widthFactor: 0.9, height: 9),
              const SizedBox(height: 7),
              const VxSkeletonLine(widthFactor: 0.65, height: 9),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder for a price chart: a run of bars of varying height over a
/// baseline, which reads as a chart rather than as a grey box.
///
/// Leave [height] null to fill whatever the parent gives — the chart is
/// usually the whole body of its screen — or set it to match a fixed-height
/// chart card.
class VxChartSkeleton extends StatelessWidget {
  final double? height;
  final int bars;

  const VxChartSkeleton({super.key, this.height, this.bars = 28});

  @override
  Widget build(BuildContext context) {
    // A fixed profile rather than noise: it suggests price action, and it is
    // identical on every frame so the placeholder does not twitch.
    const profile = <double>[
      0.42, 0.48, 0.44, 0.55, 0.62, 0.58, 0.66, 0.72, 0.68, 0.6,
      0.54, 0.47, 0.5, 0.58, 0.64, 0.7, 0.78, 0.74, 0.82, 0.88,
      0.8, 0.72, 0.66, 0.7, 0.76, 0.84, 0.9, 0.86,
    ];

    final bar = LayoutBuilder(
      builder: (context, constraints) {
        // An unbounded parent gives maxHeight == infinity, and infinity times
        // a fraction is still infinity — which lays out as a crash rather
        // than as a tall chart. Fall back to a sensible card height there.
        final box =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0;
        final usable = math.max(24.0, box - 40);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < bars; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: VxSkeleton(
                      width: double.infinity,
                      height: usable * profile[i % profile.length],
                      borderRadius: 2,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    return _LoadingSemantics(
      child: height == null ? bar : SizedBox(height: height, child: bar),
    );
  }
}

/// A spinner sized for the inside of a button or a text field.
///
/// The only honest use of an indeterminate spinner: the user has just pressed
/// something, the wait is short, and the question they want answered is "did
/// that register" — not "what is coming".
class VxInlineSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const VxInlineSpinner({super.key, this.size = 18, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        // Scaled with the spinner: the default 4px stroke on an 18px ring is
        // a doughnut rather than a line.
        strokeWidth: math.min(3.0, math.max(1.5, size / 9)),
        color: color ?? VxColors.primary,
      ),
    );
  }
}

/// Announces a placeholder as loading, once, and hides the bars themselves.
///
/// Without this a screen reader walks a tree of decorative boxes and reports
/// nothing, so a blind user cannot tell a loading screen from an empty one.
class _LoadingSemantics extends StatelessWidget {
  final Widget child;

  const _LoadingSemantics({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      excludeSemantics: true,
      child: child,
    );
  }
}

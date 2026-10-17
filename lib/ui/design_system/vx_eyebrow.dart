import 'package:flutter/material.dart';

import 'vx_colors.dart';
import 'vx_typography.dart';

/// A small capitalised label — a section eyebrow, a column header, a metric
/// caption.
///
/// ## Why capitals live in a widget and not in the string
///
/// This app used to write `'AVAILABLE BALANCE'` and `label.toUpperCase()` at
/// around a hundred and forty call sites, and the capitals leaked into places
/// they do not belong: buttons, dialog titles, screen headings, feedback
/// ("CORRECT"), whole sentences. Capitals are a typographic device for labels.
/// They are not a voice, and an app that shouts every word has no way left to
/// emphasise anything.
///
/// They also cost reading speed. Lower-case words have ascenders and
/// descenders that give each word a distinct outline, and a fluent reader
/// matches those shapes rather than spelling the word out. Capitals erase the
/// outline — every word becomes the same rectangle — which is why all-caps
/// text measures slower to read and why the effect gets worse the longer the
/// run. On a label of one or two words that cost is nil. On "MARK COMPLETE &
/// CONTINUE" it is the whole button.
///
/// So the rule in this codebase:
///
/// * **Label** — a section eyebrow, a chip, a badge, a metric caption, a
///   column header. One to three words, not a sentence, and the user scans it
///   rather than reads it. Use [VxEyebrow].
/// * **Language** — a button, a heading, a dialog title, a piece of feedback,
///   any sentence. Sentence case, written out as the user should read it.
///
/// ## Why it uppercases rather than being handed capitals
///
/// The caller passes `'Available balance'`. Three things follow from that.
///
/// A screen reader gets real words. TalkBack and VoiceOver treat a short
/// all-capital string as an initialism and spell it: "P, N, L" for `PNL`, and
/// "C, O, R, R, E, C, T". Uppercasing in the widget means [Semantics] can
/// carry the sentence-case original while the glyphs on screen are capitals,
/// so the label is read as a word.
///
/// The copy stays searchable and translatable. A reviewer greps for "Available
/// balance" and finds it; an ARB value reads as a sentence, which matters
/// because capitalisation is not universal — a translator should never have to
/// decide whether their language even has a concept of "all caps".
///
/// And the decision stays reversible. Tracking, weight, size and whether the
/// capitals happen at all are set once here. Capitals need positive letter
/// spacing or they crowd — that is what [VxTypography.eyebrow] is for, and it
/// is a correction no call site should be making by hand.
class VxEyebrow extends StatelessWidget {
  /// The label in sentence case. This widget capitalises it for display; the
  /// text passed here is what assistive technology reads out.
  final String text;

  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;

  const VxEyebrow(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      // The Text below renders capitals. Without this the screen reader would
      // announce those instead of the label above, defeating the point.
      excludeSemantics: true,
      child: Text(
        text.toUpperCase(),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: VxTypography.eyebrow.copyWith(
          color: color ?? VxColors.textTertiary,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

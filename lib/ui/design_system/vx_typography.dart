import 'package:flutter/material.dart';
import 'vx_colors.dart';

class VxTypography {
  VxTypography._();

  /// The app's two type families, bundled as assets in pubspec.yaml.
  ///
  /// Referenced by name rather than through the google_fonts package, which
  /// downloads font files at runtime — the first screens of a fresh install
  /// rendered in a fallback face while it waited on the network, then swapped.
  ///
  /// DM Sans for everything the user reads; JetBrains Mono for numbers only,
  /// where fixed-width digits stop prices and P&L jittering as they tick.
  static const String sans = 'DM Sans';
  static const String mono = 'JetBrains Mono';

  /// Builds one entry in the scale.
  ///
  /// This exists to keep the styles *out* of the constant pool, which is a
  /// deliberate choice rather than an oversight. A `static const TextStyle`
  /// is a compile-time constant, so every `Text(...)` that uses one becomes
  /// const-able, and so does the `Column` around it, and the `Padding` around
  /// that — `prefer_const_constructors` then reports every widget in the
  /// chain, in files that never referenced typography directly. Analysis runs
  /// with `--fatal-infos`, so that is a red build spreading out from a change
  /// to one file. Writing `static final x = const TextStyle(...)` only trades
  /// it for `prefer_const_declarations` on the field itself.
  ///
  /// A function call is not a constant expression, so neither lint applies and
  /// the styles stay where they belong: one definition each, read by everyone,
  /// with no effect on how callers are written. The cost is a single lazy
  /// allocation per style for the life of the process.
  static TextStyle _scale(
    String family,
    double size,
    FontWeight weight,
    Color color, {
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      // Tabular figures everywhere, not just on the price style.
      //
      // In a proportional face a '1' is narrower than a '0', so a live number
      // physically changes width as it ticks and everything beside it shuffles
      // — a balance in the app bar, a P&L in a list, a countdown. Traders read
      // that jitter as amateur before they can say why: every terminal they
      // have used, from Bloomberg to TWS, locks digits to one width.
      //
      // Applied in _scale rather than per style because any digit anywhere in
      // this app can update, and because it is inert on text that has no
      // digits in it. JetBrains Mono is already fixed-width so the feature is
      // redundant there and harmless; DM Sans is where it does the work.
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static final TextStyle hero = _scale(
      sans, 38, FontWeight.w700, VxColors.textPrimary, letterSpacing: -1.2);

  static final TextStyle h1 = _scale(
      sans, 28, FontWeight.w700, VxColors.textPrimary, letterSpacing: -0.5);

  static final TextStyle h2 =
      _scale(sans, 24, FontWeight.w600, VxColors.textPrimary);

  static final TextStyle h3 =
      _scale(sans, 20, FontWeight.w600, VxColors.textPrimary);

  static final TextStyle bodyLarge =
      _scale(sans, 18, FontWeight.w400, VxColors.textPrimary);

  static final TextStyle body =
      _scale(sans, 16, FontWeight.w400, VxColors.textPrimary);

  static final TextStyle bodySmall =
      _scale(sans, 14, FontWeight.w400, VxColors.textSecondary);

  static final TextStyle price =
      _scale(mono, 16, FontWeight.w600, VxColors.textPrimary);

  static final TextStyle caption = _scale(
      sans, 12, FontWeight.w500, VxColors.textTertiary, letterSpacing: 0.2);

  static final TextStyle button = _scale(
      sans, 16, FontWeight.w600, VxColors.textPrimary, letterSpacing: 0.2);

  /// Small capitalised labels — section eyebrows, column headers, metric
  /// captions. Always applied through `VxEyebrow`, never by hand.
  ///
  /// The letter spacing is the part that is easy to leave out and the part
  /// that matters. Type designers fit the sidebearings of a capital for the
  /// company of lower-case letters, so a run of capitals set at its default
  /// tracking reads as crowded — the glyphs touch where the eye expects air.
  /// Roughly 0.1em of extra tracking restores it, which at 11px is 1.1.
  static final TextStyle eyebrow = _scale(
      sans, 11, FontWeight.w600, VxColors.textTertiary, letterSpacing: 1.1);

  /// The single mono family for numeric/tabular text, exposed so raw
  /// `fontFamily:` usages can align to it.
  static String get monoFamily => mono;
}

class VxText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  const VxText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.color,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: (style ?? VxTypography.body).copyWith(color: color),
    );
  }

  // --- Named Constructors for Legacy Compatibility ---

  factory VxText.heading1(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.h1.copyWith(fontSize: fontSize, fontWeight: weight),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.heading2(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.h2.copyWith(fontSize: fontSize, fontWeight: weight),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.heading3(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.h3.copyWith(fontSize: fontSize, fontWeight: weight),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  // Mobile standard titles
  factory VxText.title(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.h3.copyWith(fontSize: fontSize, fontWeight: weight),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.subtitle(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.bodyLarge
            .copyWith(fontSize: fontSize, fontWeight: weight),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.body(String text,
      {Color? color,
      TextAlign? textAlign,
      int? maxLines,
      TextOverflow? overflow,
      double? fontSize,
      FontWeight? weight}) {
    return VxText(text,
        style:
            VxTypography.body.copyWith(fontSize: fontSize, fontWeight: weight),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.bodyBold(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.body.copyWith(
            fontWeight: weight ?? FontWeight.bold, fontSize: fontSize),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.caption(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.caption
            .copyWith(fontSize: fontSize, fontWeight: weight),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.micro(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.caption
            .copyWith(fontSize: fontSize ?? 10, fontWeight: weight),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.mono(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.bodySmall
            .copyWith(fontSize: fontSize, fontWeight: weight)
            .copyWith(fontFamily: VxTypography.mono),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }

  factory VxText.monoBold(String text,
      {Color? color,
      TextAlign? textAlign,
      double? fontSize,
      FontWeight? weight,
      int? maxLines,
      TextOverflow? overflow}) {
    return VxText(text,
        style: VxTypography.bodySmall
            .copyWith(fontWeight: weight ?? FontWeight.bold, fontSize: fontSize)
            .copyWith(fontFamily: VxTypography.mono),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }
}

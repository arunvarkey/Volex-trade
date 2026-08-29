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

  static const TextStyle hero = TextStyle(
    fontFamily: sans,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: VxColors.textPrimary,
    letterSpacing: -1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: sans,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: VxColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: sans,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: VxColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: sans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: VxColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: sans,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: VxColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: VxColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: VxColors.textSecondary,
  );

  static const TextStyle price = TextStyle(
    fontFamily: mono,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VxColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: VxColors.textTertiary,
    letterSpacing: 0.2,
  );

  static const TextStyle button = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VxColors.textPrimary,
    letterSpacing: 0.2,
  );

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

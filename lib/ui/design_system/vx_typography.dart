import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vx_colors.dart';

class VxTypography {
  VxTypography._();

  static TextStyle hero = GoogleFonts.dmSans(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: VxColors.textPrimary,
    letterSpacing: -1.2,
  );

  static TextStyle h1 = GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: VxColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle h2 = GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: VxColors.textPrimary,
  );

  static TextStyle h3 = GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: VxColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: VxColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: VxColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: VxColors.textSecondary,
  );

  static TextStyle price = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VxColors.textPrimary,
  );

  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: VxColors.textTertiary,
    letterSpacing: 0.2,
  );

  static TextStyle button = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VxColors.textPrimary,
    letterSpacing: 0.2,
  );

  /// The single mono family for numeric/tabular text, exposed so raw
  /// `fontFamily:` usages can align to it without re-importing google_fonts.
  static String? get monoFamily => GoogleFonts.jetBrainsMono().fontFamily;
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
        style: GoogleFonts.jetBrainsMono(
            textStyle: VxTypography.bodySmall
                .copyWith(fontSize: fontSize, fontWeight: weight)),
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
        style: GoogleFonts.jetBrainsMono(
            textStyle: VxTypography.bodySmall.copyWith(
                fontWeight: weight ?? FontWeight.bold, fontSize: fontSize)),
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }
}

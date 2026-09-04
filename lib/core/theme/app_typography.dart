import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static String get _sans => GoogleFonts.plusJakartaSans().fontFamily!;
  static String get _mono => GoogleFonts.jetBrainsMono().fontFamily!;

  static TextStyle display(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: color,
    height: 1.15,
  );

  static TextStyle h1(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: color,
    height: 1.2,
  );

  static TextStyle h2(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: color,
    height: 1.25,
  );

  static TextStyle h3(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: color,
    height: 1.3,
  );

  static TextStyle title(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    color: color,
  );

  static TextStyle bodyLarge(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodyMedium(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodySmall(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.4,
  );

  static TextStyle label(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: color,
  );

  static TextStyle labelLarge(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: color,
  );

  static TextStyle caption(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.4,
  );

  static TextStyle financialAmountLarge(Color color) => TextStyle(
    fontFamily: _mono,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle financialAmountMedium(Color color) => TextStyle(
    fontFamily: _mono,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle financialAmount(Color color) => TextStyle(
    fontFamily: _mono,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle financialAmountSmall(Color color) => TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle button(Color color) => TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: color,
  );
}

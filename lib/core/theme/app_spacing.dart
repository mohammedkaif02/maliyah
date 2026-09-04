import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double colossal = 64;
}

class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 28;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => const [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x070F172A), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> get cardDark => const [
    BoxShadow(color: Color(0x3D000000), blurRadius: 20, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static List<BoxShadow> get navBar => const [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 24, offset: Offset(0, -4)),
  ];

  static List<BoxShadow> get navBarDark => const [
    BoxShadow(color: Color(0x4D000000), blurRadius: 24, offset: Offset(0, -4)),
  ];

  static List<BoxShadow> get button => const [
    BoxShadow(color: Color(0x330D9488), blurRadius: 14, offset: Offset(0, 4)),
  ];
}

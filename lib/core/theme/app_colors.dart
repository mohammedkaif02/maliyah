import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const lightPrimary = Color(0xFF0D9488); // Teal-600
  static const lightPrimaryDark = Color(0xFF0F766E); // Teal-700
  static const lightPrimaryContainer = Color(0xFFCCFBF1); // Teal-100
  static const lightSecondary = Color(0xFF6366F1); // Indigo-500
  static const lightSecondaryContainer = Color(0xFFE0E7FF); // Indigo-100
  static const lightBackground = Color(0xFFF8FAFC); // Slate-50
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF1F5F9); // Slate-100
  static const lightSurfaceElevated = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF0F172A); // Slate-900
  static const lightTextSecondary = Color(0xFF475569); // Slate-600
  static const lightTextTertiary = Color(0xFF94A3B8); // Slate-400
  static const lightBorder = Color(0xFFE2E8F0); // Slate-200
  static const lightDivider = Color(0xFFF1F5F9); // Slate-100
  static const lightShimmer = Color(0xFFE2E8F0);
  static const lightShadow = Color(0x0F0F172A);

  // ─────────────────────── Dark Theme ───────────────────────────
  static const darkPrimary = Color(
    0xFF2DD4BF,
  ); // Teal-400  (vibrant neon on dark)
  static const darkPrimaryDark = Color(0xFF14B8A6); // Teal-500
  static const darkPrimaryContainer = Color(0xFF134E4A); // Teal-900
  static const darkSecondary = Color(0xFF818CF8); // Indigo-400
  static const darkSecondaryContainer = Color(0xFF1E1B4B); // Indigo-950
  static const darkBackground = Color(0xFF060B12); // near-OLED black
  static const darkSurface = Color(0xFF0E1520); // ~Slate-950
  static const darkSurfaceVariant = Color(0xFF162031); // slightly lighter
  static const darkSurfaceElevated = Color(0xFF1C2B3D); // card elevation
  static const darkTextPrimary = Color(0xFFF0F9FF); // Slate-50
  static const darkTextSecondary = Color(0xFF94A3B8); // Slate-400
  static const darkTextTertiary = Color(0xFF475569); // Slate-600
  static const darkBorder = Color(0xFF1E2D40);
  static const darkDivider = Color(0xFF0F1A27);
  static const darkShimmer = Color(0xFF1E2D40);
  static const darkShadow = Color(0x33000000);

  // ─────────────────── Financial Semantics (theme-independent) ───
  static const income = Color(0xFF10B981); // Emerald-500
  static const incomeLight = Color(0xFFD1FAE5); // Emerald-100
  static const incomeDark = Color(0xFF064E3B); // Emerald-950
  static const expense = Color(0xFFF43F5E); // Rose-500
  static const expenseLight = Color(0xFFFFE4E6); // Rose-100
  static const expenseDark = Color(0xFF4C0519); // Rose-950
  static const savings = Color(0xFF6366F1); // Indigo-500
  static const savingsLight = Color(0xFFE0E7FF); // Indigo-100

  // ─────────────────── Budget Status ─────────────────────────────
  static const budgetOk = Color(0xFF10B981); // Emerald
  static const budgetWarning = Color(0xFFF59E0B); // Amber-500
  static const budgetExceeded = Color(0xFFF43F5E); // Rose
  static const budgetOkBg = Color(0xFFD1FAE5);
  static const budgetWarningBg = Color(0xFFFEF3C7);
  static const budgetExceededBg = Color(0xFFFFE4E6);

  // ─────────────────── Status Colors ─────────────────────────────
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFF43F5E);
  static const info = Color(0xFF3B82F6); // Blue-500

  // ─────────────────── Gradient Definitions ──────────────────────
  static const balanceGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9488), Color(0xFF0284C7), Color(0xFF4F46E5)],
    stops: [0.0, 0.55, 1.0],
  );

  static const balanceGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF134E4A), Color(0xFF1E3A5F), Color(0xFF1E1B4B)],
    stops: [0.0, 0.5, 1.0],
  );

  static const incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
  );

  static const categoryPalette = <Color>[
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFF0EA5E9), // Sky
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF84CC16), // Lime
  ];
}

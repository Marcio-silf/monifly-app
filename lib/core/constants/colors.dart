import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Teal/Cyan (Made darker for better contrast with white text)
  static const Color primary = Color(0xFF0891B2); // Cyan 600
  static const Color primaryLight = Color(0xFF06B6D4); // Cyan 500
  static const Color primaryDark = Color(0xFF155E75); // Cyan 800

  // Secondary - Sky Blue
  static const Color secondary = Color(0xFF0284C7); // Sky 600
  static const Color secondaryLight = Color(0xFF0EA5E9); // Sky 500
  static const Color secondaryDark = Color(0xFF0369A1); // Sky 700

  // Accent - Amber
  static const Color accent = Color(0xFFD97706); // Amber 600
  static const Color accentLight = Color(0xFFF59E0B); // Amber 500
  static const Color accentDark = Color(0xFFB45309); // Amber 700

  // Semantic (Extra dark/saturated for better contrast on blue gradients)
  static const Color income = Color(0xFF065F46); // Emerald 800
  static const Color expense = Color(0xFF9F1239); // Rose 800
  static const Color pending = Color(0xFF92400E); // Amber 800
  static const Color investment = Color(0xFF5B21B6); // Violet 800

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF0F9FF);
  static const Color backgroundDark = Color(0xFF0F172A);

  // Surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFE2E8F0); // Reduzido brilho excessivo
  static const Color textSecondaryLight =
      Color(0xFF475569); // Mais escuro para melhor contraste no fundo claro
  static const Color textSecondaryDark =
      Color(0xFF94A3B8); // Tom mais suave para modo escuro

  // Borders
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Card backgrounds
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);

  // Error / Success / Warning (Saturated for contrast)
  static const Color error = Color(0xFF9F1239); // Rose 800
  static const Color success = Color(0xFF065F46); // Emerald 800
  static const Color warning = Color(0xFF92400E); // Amber 800

  // Overlays
  static const Color overlay = Color(0x80000000);
}

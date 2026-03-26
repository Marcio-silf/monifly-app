import 'package:flutter/material.dart';
import 'colors.dart';

class AppGradients {
  AppGradients._();

  // Main Monifly gradient (teal → sky blue)
  static const LinearGradient monifly = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Vertical Monifly gradient
  static const LinearGradient moniflyVertical = LinearGradient(
    colors: [
      AppColors.primaryDark,
      AppColors.primary,
      AppColors.secondary,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Success / Income gradient
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warning / Pending gradient
  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Expense / Danger gradient
  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Investment gradient (purple)
  static const LinearGradient investment = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark card gradient
  static const LinearGradient darkCard = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background gradient (very light)
  static const LinearGradient backgroundLight = LinearGradient(
    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundDark = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

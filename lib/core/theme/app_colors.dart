import 'package:flutter/material.dart';

/// Centralized color palette. Widgets should prefer [Theme]/[ColorScheme];
/// these are the brand/semantic colors the theme is built from.
abstract final class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF2E7D5B);
  static const Color expense = Color(0xFFE5484D);
  static const Color income = Color(0xFF1A936F);
}

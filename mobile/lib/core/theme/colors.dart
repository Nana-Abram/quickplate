import 'package:flutter/material.dart';

abstract final class AppColors {
  /// The brand colour. The Material 3 colour scheme is derived from it by
  /// [ColorScheme.fromSeed].
  static const Color brand = Color(0xFFE85D04);

  /// The rating star. Decorative only, never used for text.
  static const Color star = Color(0xFFFFB300);

  /// The home header's gradient. White text passes WCAG AA on both ends.
  static const Color brandWarm = Color(0xFFC2410C);
  static const Color brandDeep = Color(0xFF9A3412);
}

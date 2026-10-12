import 'package:flutter/material.dart';

abstract final class AppColors {
  /// The brand colour. The Material 3 colour scheme is derived from it by
  /// [ColorScheme.fromSeed].
  static const Color brand = Color(0xFFE85D04);

  /// Kente accents, used only for decoration (the kente band, the rating
  /// star), never for text, so they need no contrast pairing.
  static const Color kenteGold = Color(0xFFF2B705);
  static const Color kenteGreen = Color(0xFF0B7A3B);
  static const Color kenteRed = Color(0xFFC1121F);
  static const Color kenteBlack = Color(0xFF1B1B1B);

  /// The home header's gradient. White text passes WCAG AA on both ends.
  static const Color brandWarm = Color(0xFFC2410C);
  static const Color brandDeep = Color(0xFF9A3412);
}

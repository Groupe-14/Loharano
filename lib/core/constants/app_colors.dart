import 'package:flutter/material.dart';

import '../models/risk_level.dart';

abstract final class AppColors {
  static const ink = Color(0xFF1A2421);
  static const muted = Color(0xFF5E675F);
  static const paper = Color(0xFFF3EFE6);
  static const surface = Color(0xFFFFFCF7);
  static const line = Color(0xFFDDD4C4);
  static const teal = Color(0xFF0F5C56);
  static const tealSoft = Color(0xFFD7EBE6);

  static const low = Color(0xFF1B6B43);
  static const lowSurface = Color(0xFFE5F2EA);
  static const medium = Color(0xFF8A4E0B);
  static const mediumSurface = Color(0xFFF8EDD8);
  static const high = Color(0xFF8C1E1E);
  static const highSurface = Color(0xFFF8E6E3);
  static const unknown = Color(0xFF3D4A50);
  static const unknownSurface = Color(0xFFE6EBEE);

  static const primaryBlue = teal;
  static const background = paper;

  static Color forRisk(RiskLevel level) => switch (level) {
        RiskLevel.low => low,
        RiskLevel.medium => medium,
        RiskLevel.high => high,
        RiskLevel.unknown => unknown,
      };

  static Color surfaceFor(RiskLevel level) => switch (level) {
        RiskLevel.low => lowSurface,
        RiskLevel.medium => mediumSurface,
        RiskLevel.high => highSurface,
        RiskLevel.unknown => unknownSurface,
      };

  static IconData iconFor(RiskLevel level) => switch (level) {
        RiskLevel.low => Icons.info_outline,
        RiskLevel.medium => Icons.warning_amber_rounded,
        RiskLevel.high => Icons.report_outlined,
        RiskLevel.unknown => Icons.help_outline,
      };
}

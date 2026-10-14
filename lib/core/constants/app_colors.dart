import 'package:flutter/material.dart';

class AppColors {
  // Deep OLED true black for battery efficiency and HUD windshield projection
  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);

  // Active Neon Themes
  static const Color neonGreen = Color(0xFF00FF66);
  static const Color electricCyan = Color(0xFF00F0FF);
  static const Color racingOrange = Color(0xFFFF9900);
  static const Color alertRed = Color(0xFFFF3344);
  static const Color hyperViolet = Color(0xFFB537F2);

  static const List<Color> themePalette = [
    neonGreen,
    electricCyan,
    racingOrange,
    alertRed,
    hyperViolet,
  ];

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);
}

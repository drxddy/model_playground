import 'package:flutter/material.dart';

class AppTheme {
  static const List<Color> gradientColors = [
    Color(0xFFAAE5FF),
    Color(0xFF68C7FE),
    Color(0xFF38A8F2),
    Color(0xFF2286D4),
  ];

  static final ThemeData themeData = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2286D4),
      primary: const Color(0xFF2286D4),
      secondary: const Color(0xFF38A8F2),
      tertiary: const Color(0xFF68C7FE),
      surface: const Color(0xFFAAE5FF),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static const BoxDecoration gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: gradientColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

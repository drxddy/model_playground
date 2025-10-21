import 'package:flutter/material.dart';

class AppTheme {
  static const List<Color> gradientColors = [
    Color(0xFFAAE5FF),
    Color(0xFF68C7FE),
    Color(0xFF38A8F2),
    Color(0xFF2286D4),
  ];

  static final ThemeData themeData = ThemeData(
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2286D4),
      primary: const Color(0xFF2286D4),
      secondary: const Color(0xFF38A8F2),
      tertiary: const Color(0xFF68C7FE),
      surface: const Color(0xFFAAE5FF),
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Poly'),
      displayMedium: TextStyle(fontFamily: 'Poly'),
      displaySmall: TextStyle(fontFamily: 'Poly'),
      headlineLarge: TextStyle(fontFamily: 'Poly'),
      headlineMedium: TextStyle(fontFamily: 'Poly'),
      headlineSmall: TextStyle(fontFamily: 'Poly'),
      titleLarge: TextStyle(fontFamily: 'Poly'),
      titleMedium: TextStyle(fontFamily: 'Poly'),
      titleSmall: TextStyle(fontFamily: 'Poly'),
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

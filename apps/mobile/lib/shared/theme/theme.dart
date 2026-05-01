import 'package:flutter/material.dart';

class AppTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF1A1A1A),
      primary: Color(0xFF6C63FF),
      error: Color(0xFFF87171),
    ),
    fontFamily: 'Inter',
  );
}

import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors (from web app app.css)
  static const background = Color(0xFF161B1F);
  static const surface = Color(0xFF1E2428);
  static const surface2 = Color(0xFF252C32);
  static const card = Color(0xFF242B31);
  static const border = Color(0xFF2E3740);
  static const border2 = Color(0xFF3A4550);

  static const text = Color(0xFFC4CDD6);
  static const text2 = Color(0xFF9EAAB6);
  static const muted = Color(0xFF7A8A97);
  static const muted2 = Color(0xFF5D6E7A);
  static const textStrong = Color(0xFFE2E8ED);

  // Level Colors (Dark Theme)
  static const day = Color(0xFF4BCE97);
  static const daySoft = Color(0x384BCE97); // 0.22 opacity
  static const dayTint = Color(0x174BCE97); // 0.09 opacity

  static const week = Color(0xFF579DFF);
  static const weekSoft = Color(0x38579DFF);
  static const weekTint = Color(0x17579DFF);

  static const month = Color(0xFF9F8FEF);
  static const monthSoft = Color(0x389F8FEF);
  static const monthTint = Color(0x179F8FEF);

  static const year = Color(0xFFE2B203);
  static const yearSoft = Color(0x38E2B203);
  static const yearTint = Color(0x17E2B203);

  // Status
  static const warning = Color(0xFFF87168);
  static const warningSoft = Color(0x38F87168);
  static const warningTint = Color(0x17F87168);
  static const warningInk = Color(0xFFFF9C8F);

  static const success = Color(0xFF7EE2B8);
  static const danger = Color(0xFFF87168);

  static const brand = Color(0xFF579DFF);
  static const brand2 = Color(0xFF85B8FF);
  static const brandSoft = Color(0x29579DFF); // 0.16 opacity
}

class AppTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.card,
    dividerColor: AppColors.border,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.brand,
      secondary: AppColors.brand2,
      error: AppColors.danger,
      onSurface: AppColors.text,
      onBackground: AppColors.text,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.text, fontSize: 14),
      bodyMedium: TextStyle(color: AppColors.text2, fontSize: 13),
      labelSmall: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brand;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: AppColors.border2, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textStrong,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.brand,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

import 'package:flutter/material.dart';

// ── Color tokens — exactly matching web CSS custom properties ─────────────────

class AppColors {
  // ── Dark theme ──────────────────────────────────────────────────────────────
  static const backgroundDark  = Color(0xFF161B1F);
  static const surfaceDark     = Color(0xFF1E2428);
  static const surface2Dark    = Color(0xFF252C32);
  static const cardDark        = Color(0xFF242B31);
  static const borderDark      = Color(0xFF2E3740);
  static const border2Dark     = Color(0xFF3A4550);

  static const textDark        = Color(0xFFC4CDD6);
  static const text2Dark       = Color(0xFF9EAAB6);
  static const textStrongDark  = Color(0xFFE2E8ED);
  static const mutedDark       = Color(0xFF7A8A97);
  static const muted2Dark      = Color(0xFF5D6E7A);

  static const dayDark         = Color(0xFF4BCE97);
  static const daySoftDark     = Color(0x384BCE97);  // 22% opacity
  static const dayTintDark     = Color(0x174BCE97);  // 9% opacity
  static const weekDark        = Color(0xFF579DFF);
  static const weekSoftDark    = Color(0x38579DFF);
  static const weekTintDark    = Color(0x17579DFF);
  static const monthDark       = Color(0xFF9F8FEF);
  static const monthSoftDark   = Color(0x389F8FEF);
  static const monthTintDark   = Color(0x179F8FEF);
  static const yearDark        = Color(0xFFE2B203);
  static const yearSoftDark    = Color(0x38E2B203);
  static const yearTintDark    = Color(0x17E2B203);

  static const warningDark     = Color(0xFFF87168);
  static const warningSoftDark = Color(0x38F87168);
  static const warningTintDark = Color(0x17F87168);
  static const warningInkDark  = Color(0xFFFF9C8F);
  static const successDark     = Color(0xFF7EE2B8);
  static const dangerDark      = Color(0xFFF87168);
  static const brandDark       = Color(0xFF579DFF);
  static const brand2Dark      = Color(0xFF85B8FF);
  static const brandSoftDark   = Color(0x29579DFF);

  // ── Light theme — warm paper palette ────────────────────────────────────────
  static const backgroundLight = Color(0xFFF4F1EA);
  static const surfaceLight    = Color(0xFFEBE7DC);
  static const surface2Light   = Color(0xFFE0DBCC);
  static const cardLight       = Color(0xFFFBFAF6);
  static const borderLight     = Color(0xFFD6D0BF);
  static const border2Light    = Color(0xFFC9C1AC);

  static const textLight       = Color(0xFF1A1814);
  static const text2Light      = Color(0xFF4A463C);
  static const textStrongLight = Color(0xFF1A1814);
  static const mutedLight      = Color(0xFF82796A);
  static const muted2Light     = Color(0xFFA89E8C);

  static const dayLight        = Color(0xFF2F5F8F);
  static const daySoftLight    = Color(0xFFD9E3EE);
  static const dayTintLight    = Color(0xFFEAF0F7);
  static const weekLight       = Color(0xFF3D7A4A);
  static const weekSoftLight   = Color(0xFFD5E3D3);
  static const weekTintLight   = Color(0xFFE8EFE5);
  static const monthLight      = Color(0xFF6B4A8A);
  static const monthSoftLight  = Color(0xFFDDD0E6);
  static const monthTintLight  = Color(0xFFEBE2F0);
  static const yearLight       = Color(0xFFB85C1F);
  static const yearSoftLight   = Color(0xFFF0D6C0);
  static const yearTintLight   = Color(0xFFF5E5D4);

  static const warningLight    = Color(0xFFB8731A);
  static const warningSoftLight = Color(0xFFF0D9A8);
  static const warningTintLight = Color(0xFFF6E8C8);
  static const warningInkLight = Color(0xFF6B4310);
  static const successLight    = Color(0xFF3D7A4A);
  static const dangerLight     = Color(0xFF8C4242);
  static const brandLight      = Color(0xFF2F5F8F);
  static const brand2Light     = Color(0xFF4A7AAD);
  static const brandSoftLight  = Color(0x292F5F8F);
}

// ── Context extension ─────────────────────────────────────────────────────────

extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get colorBackground  => isDark ? AppColors.backgroundDark  : AppColors.backgroundLight;
  Color get colorSurface     => isDark ? AppColors.surfaceDark     : AppColors.surfaceLight;
  Color get colorSurface2    => isDark ? AppColors.surface2Dark    : AppColors.surface2Light;
  Color get colorCard        => isDark ? AppColors.cardDark        : AppColors.cardLight;
  Color get colorBorder      => isDark ? AppColors.borderDark      : AppColors.borderLight;
  Color get colorBorder2     => isDark ? AppColors.border2Dark     : AppColors.border2Light;
  Color get colorText        => isDark ? AppColors.textDark        : AppColors.textLight;
  Color get colorText2       => isDark ? AppColors.text2Dark       : AppColors.text2Light;
  Color get colorTextStrong  => isDark ? AppColors.textStrongDark  : AppColors.textStrongLight;
  Color get colorMuted       => isDark ? AppColors.mutedDark       : AppColors.mutedLight;
  Color get colorMuted2      => isDark ? AppColors.muted2Dark      : AppColors.muted2Light;
  Color get colorBrand       => isDark ? AppColors.brandDark       : AppColors.brandLight;
  Color get colorBrand2      => isDark ? AppColors.brand2Dark      : AppColors.brand2Light;
  Color get colorBrandSoft   => isDark ? AppColors.brandSoftDark   : AppColors.brandSoftLight;

  Color get colorDay         => isDark ? AppColors.dayDark         : AppColors.dayLight;
  Color get colorDaySoft     => isDark ? AppColors.daySoftDark     : AppColors.daySoftLight;
  Color get colorDayTint     => isDark ? AppColors.dayTintDark     : AppColors.dayTintLight;
  Color get colorWeek        => isDark ? AppColors.weekDark        : AppColors.weekLight;
  Color get colorWeekSoft    => isDark ? AppColors.weekSoftDark    : AppColors.weekSoftLight;
  Color get colorWeekTint    => isDark ? AppColors.weekTintDark    : AppColors.weekTintLight;
  Color get colorMonth       => isDark ? AppColors.monthDark       : AppColors.monthLight;
  Color get colorMonthSoft   => isDark ? AppColors.monthSoftDark   : AppColors.monthSoftLight;
  Color get colorMonthTint   => isDark ? AppColors.monthTintDark   : AppColors.monthTintLight;
  Color get colorYear        => isDark ? AppColors.yearDark        : AppColors.yearLight;
  Color get colorYearSoft    => isDark ? AppColors.yearSoftDark    : AppColors.yearSoftLight;
  Color get colorYearTint    => isDark ? AppColors.yearTintDark    : AppColors.yearTintLight;

  Color get colorWarning     => isDark ? AppColors.warningDark     : AppColors.warningLight;
  Color get colorWarningSoft => isDark ? AppColors.warningSoftDark : AppColors.warningSoftLight;
  Color get colorWarningTint => isDark ? AppColors.warningTintDark : AppColors.warningTintLight;
  Color get colorWarningInk  => isDark ? AppColors.warningInkDark  : AppColors.warningInkLight;
  Color get colorSuccess     => isDark ? AppColors.successDark     : AppColors.successLight;
  Color get colorDanger      => isDark ? AppColors.dangerDark      : AppColors.dangerLight;
}

// ── Theme builder ─────────────────────────────────────────────────────────────

ThemeData _buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final bg      = dark ? AppColors.backgroundDark  : AppColors.backgroundLight;
  final surface = dark ? AppColors.surfaceDark     : AppColors.surfaceLight;
  final surface2= dark ? AppColors.surface2Dark    : AppColors.surface2Light;
  final card    = dark ? AppColors.cardDark        : AppColors.cardLight;
  final border  = dark ? AppColors.borderDark      : AppColors.borderLight;
  final border2 = dark ? AppColors.border2Dark     : AppColors.border2Light;
  final text    = dark ? AppColors.textDark        : AppColors.textLight;
  final text2   = dark ? AppColors.text2Dark       : AppColors.text2Light;
  final textStr = dark ? AppColors.textStrongDark  : AppColors.textStrongLight;
  final muted   = dark ? AppColors.mutedDark       : AppColors.mutedLight;
  final muted2  = dark ? AppColors.muted2Dark      : AppColors.muted2Light;
  final brand   = dark ? AppColors.brandDark       : AppColors.brandLight;
  final danger  = dark ? AppColors.dangerDark      : AppColors.dangerLight;

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    cardColor: card,
    dividerColor: border,
    fontFamily: 'Inter',

    colorScheme: ColorScheme(
      brightness: brightness,
      primary:    brand,
      onPrimary:  dark ? AppColors.backgroundDark : Colors.white,
      secondary:  dark ? AppColors.brand2Dark     : AppColors.brand2Light,
      onSecondary: dark ? AppColors.backgroundDark : Colors.white,
      surface:    surface,
      onSurface:  text,
      error:      danger,
      onError:    Colors.white,
    ),

    textTheme: TextTheme(
      titleMedium: TextStyle(fontFamily: 'Inter', color: textStr,  fontSize: 14.5, fontWeight: FontWeight.w500),
      bodyLarge:   TextStyle(fontFamily: 'Inter', color: text,     fontSize: 14),
      bodyMedium:  TextStyle(fontFamily: 'Inter', color: text2,    fontSize: 13),
      bodySmall:   TextStyle(fontFamily: 'Inter', color: muted,    fontSize: 11.5),
      labelSmall:  TextStyle(fontFamily: 'Inter', color: muted,    fontSize: 10,  fontWeight: FontWeight.w600, letterSpacing: 0.1),
      displayLarge:   TextStyle(fontFamilyFallback: const ['Georgia', 'serif'], fontStyle: FontStyle.italic, fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: -0.5, color: textStr),
      headlineMedium: TextStyle(fontFamilyFallback: const ['Georgia', 'serif'], fontStyle: FontStyle.italic, fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: -0.3, color: textStr),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Inter', color: textStr, fontSize: 17, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: text),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: dark ? AppColors.brandSoftDark : AppColors.brandSoftLight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
        color: states.contains(WidgetState.selected) ? brand : muted,
        size: 22,
      )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
        color: states.contains(WidgetState.selected) ? brand : muted,
      )),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brand : Colors.transparent),
      side: BorderSide(color: border2, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: border2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: border2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: dark ? brand : textStr, width: 1.5),
      ),
      hintStyle: TextStyle(color: muted, fontFamily: 'Inter', fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: dark ? brand : textStr,
        foregroundColor: dark ? AppColors.backgroundDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brand,
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: 'Inter', color: text, fontSize: 14),
      subtitleTextStyle: TextStyle(fontFamily: 'Inter', color: muted, fontSize: 12),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brand : muted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brand.withAlpha(60) : border),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: TextStyle(fontFamily: 'Inter', color: textStr, fontSize: 16, fontWeight: FontWeight.w600),
      contentTextStyle: TextStyle(fontFamily: 'Inter', color: text2, fontSize: 14),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? AppColors.surface2Dark : AppColors.textLight,
      contentTextStyle: TextStyle(fontFamily: 'Inter', color: dark ? text : AppColors.cardLight, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class AppTheme {
  static final dark  = _buildTheme(Brightness.dark);
  static final light = _buildTheme(Brightness.light);
}

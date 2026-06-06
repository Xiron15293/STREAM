import 'package:flutter/material.dart';

class StreamColors {
  StreamColors._();

  static const canvas = Color(0xFF0C0E12);
  static const surface = Color(0xFF15171D);
  static const surfaceElevated = Color(0xFF1E2028);
  static const surfaceHighlight = Color(0xFF272A33);

  static const primary = Color(0xFF4B7BFF);
  static const primarySoft = Color(0xFF3A6AE8);
  static const income = Color(0xFF34C759);
  static const expense = Color(0xFFFF453A);
  static const warning = Color(0xFFFFD60A);
  static const neutral = Color(0xFF8E8E93);

  static const textPrimary = Color(0xFFEBEBF5);
  static const textSecondary = Color(0xFF8E8E93);
  static const textMuted = Color(0xFF636366);

  static const divider = Color(0xFF1E2028);
}

class StreamSpacing {
  StreamSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const section = 32.0;
}

class StreamRadius {
  StreamRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const full = 100.0;
}

class StreamTypography {
  StreamTypography._();
  static const display = TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.5, height: 1.0);
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.1);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.2);
  static const h3 = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.3);
  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.4);
  static const bodyBold = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.4);
  static const caption = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.2, height: 1.3);
  static const captionBold = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2, height: 1.3);
  static const micro = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.2);
  static const amount = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.2);
  static const amountLarge = TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.5, height: 1.0);
}

class StreamTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: StreamColors.canvas,
    colorScheme: ColorScheme.dark(
      primary: StreamColors.primary,
      secondary: StreamColors.primarySoft,
      surface: StreamColors.surface,
      error: StreamColors.expense,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: StreamColors.canvas,
      foregroundColor: StreamColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: StreamColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: StreamColors.surface,
      selectedItemColor: StreamColors.primary,
      unselectedItemColor: StreamColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3),
    ),
    cardTheme: CardThemeData(
      color: StreamColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.lg)),
      margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: StreamColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: StreamColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StreamRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StreamRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StreamRadius.md),
        borderSide: const BorderSide(color: StreamColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StreamRadius.md),
        borderSide: const BorderSide(color: StreamColors.expense, width: 1),
      ),
      labelStyle: const TextStyle(color: StreamColors.textSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: StreamColors.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: StreamColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: StreamColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: StreamColors.primary,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StreamColors.textSecondary,
        side: const BorderSide(color: StreamColors.surfaceElevated),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: StreamColors.surfaceElevated,
      contentTextStyle: const TextStyle(color: StreamColors.textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: StreamColors.surfaceElevated,
      labelStyle: const TextStyle(color: StreamColors.textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.full)),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
      color: StreamColors.divider,
      thickness: 1,
      space: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: StreamColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.xl)),
      titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: StreamColors.textPrimary),
      contentTextStyle: const TextStyle(fontSize: 15, color: StreamColors.textSecondary),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: StreamColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(StreamRadius.xl)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: StreamColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
      elevation: 4,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: StreamColors.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: StreamColors.primary,
      headerForegroundColor: Colors.white,
      todayForegroundColor: WidgetStatePropertyAll(StreamColors.primary),
      todayBackgroundColor: WidgetStatePropertyAll(StreamColors.primary.withValues(alpha: 0.15)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: StreamColors.surfaceElevated,
        selectedBackgroundColor: StreamColors.primary,
        foregroundColor: StreamColors.textSecondary,
        selectedForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return StreamColors.primary;
        return StreamColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return StreamColors.primary.withValues(alpha: 0.3);
        return StreamColors.surfaceElevated;
      }),
    ),
  );
}

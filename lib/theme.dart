import 'package:flutter/material.dart';
import 'design/stream_chart_palette.dart';
import 'design/stream_kpi_style.dart';
import 'design/stream_theme_extension.dart';
import 'design/stream_theme_palette.dart';

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
  static ThemeData get dark => build(StreamThemePalette.defaultPalette);

  static ThemeData build(
    StreamThemePalette p, {
    StreamChartStyleId chartStyle = StreamChartStyleId.automatic,
  }) {
    final isLight = p.brightness == Brightness.light;
    final basePalette = StreamChartPalette.forTheme(p);
    final chartPalette = basePalette.applyStyle(chartStyle, p);
    final scb = isLight ? p.canvas : p.surface;

    return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    scaffoldBackgroundColor: scb,
    extensions: [StreamThemeExtension(palette: p, chartPalette: chartPalette)],
    colorScheme: ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      secondary: p.primarySoft,
      surface: p.surface,
      error: p.expense,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: p.textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scb,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: p.textPrimary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: p.surface,
      selectedItemColor: p.primary,
      unselectedItemColor: p.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.lg)),
      margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceElevated,
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
        borderSide: BorderSide(color: p.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StreamRadius.md),
        borderSide: BorderSide(color: p.expense, width: 1),
      ),
      labelStyle: TextStyle(color: p.textSecondary, fontSize: 14),
      hintStyle: TextStyle(color: p.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textSecondary,
        side: BorderSide(color: p.surfaceElevated),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceElevated,
      contentTextStyle: TextStyle(color: p.textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceElevated,
      labelStyle: TextStyle(color: p.textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.full)),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(
      color: p.divider,
      thickness: 1,
      space: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.xl)),
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: p.textPrimary),
      contentTextStyle: TextStyle(fontSize: 15, color: p.textSecondary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(StreamRadius.xl)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
      elevation: 4,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: p.primary,
      headerForegroundColor: Colors.white,
      todayForegroundColor: WidgetStatePropertyAll(p.primary),
      todayBackgroundColor: WidgetStatePropertyAll(p.primary.withValues(alpha: 0.15)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: p.surfaceElevated,
        selectedBackgroundColor: p.primary,
        foregroundColor: p.textSecondary,
        selectedForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StreamRadius.md)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return p.primary;
        return p.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return p.primary.withValues(alpha: 0.3);
        return p.surfaceElevated;
      }),
    ),
  );
  }
}

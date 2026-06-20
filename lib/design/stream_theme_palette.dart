import 'package:flutter/material.dart';

enum StreamThemeId {
  streamClassic,
  forest,
  midnight,
  aurora,
  minimalSand,
  highContrast;

  String get label {
    switch (this) {
      case StreamThemeId.streamClassic:
        return 'Stream Classic';
      case StreamThemeId.forest:
        return 'Forest';
      case StreamThemeId.midnight:
        return 'Midnight';
      case StreamThemeId.aurora:
        return 'Aurora';
      case StreamThemeId.minimalSand:
        return 'Minimal Sand';
      case StreamThemeId.highContrast:
        return 'High Contrast';
    }
  }

  static StreamThemeId fromString(String value) {
    return StreamThemeId.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StreamThemeId.streamClassic,
    );
  }
}

class StreamThemePalette {
  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color primarySoft;
  final Color income;
  final Color expense;
  final Color transfer;
  final Color warning;
  final Color neutral;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;

  const StreamThemePalette({
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.primarySoft,
    required this.income,
    required this.expense,
    required this.transfer,
    required this.warning,
    required this.neutral,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
  });

  Brightness get brightness =>
      canvas.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark;

  bool get isClassicTheme => canvas.toARGB32() == _classic.canvas.toARGB32();
  bool get isForestTheme => canvas.toARGB32() == _forest.canvas.toARGB32();
  bool get isMidnightTheme => canvas.toARGB32() == _midnight.canvas.toARGB32();
  bool get isAuroraTheme => canvas.toARGB32() == _aurora.canvas.toARGB32();
  bool get isMinimalSandTheme =>
      canvas.toARGB32() == _minimalSand.canvas.toARGB32();
  bool get isHighContrastTheme =>
      canvas.toARGB32() == _highContrast.canvas.toARGB32();

  static const _classic = StreamThemePalette(
    canvas: Color(0xFF0C0E12),
    surface: Color(0xFF15171D),
    surfaceElevated: Color(0xFF1E2028),
    primary: Color(0xFF4B7BFF),
    primarySoft: Color(0xFF3A6AE8),
    income: Color(0xFF34C759),
    expense: Color(0xFFFF453A),
    transfer: Color(0xFF8E8E93),
    warning: Color(0xFFFFD60A),
    neutral: Color(0xFF8E8E93),
    textPrimary: Color(0xFFEBEBF5),
    textSecondary: Color(0xFF8E8E93),
    textMuted: Color(0xFF636366),
    divider: Color(0xFF1E2028),
  );

  static const _forest = StreamThemePalette(
    canvas: Color(0xFF07140D),
    surface: Color(0xFF102318),
    surfaceElevated: Color(0xFF163522),
    primary: Color(0xFF22C55E),
    primarySoft: Color(0xFF16A34A),
    income: Color(0xFF4ADE80),
    expense: Color(0xFFF97316),
    transfer: Color(0xFFA3A3A3),
    warning: Color(0xFFEAB308),
    neutral: Color(0xFFA3A3A3),
    textPrimary: Color(0xFFECFDF5),
    textSecondary: Color(0xFFA3A3A3),
    textMuted: Color(0xFF737373),
    divider: Color(0xFF163522),
  );

  static const _midnight = StreamThemePalette(
    canvas: Color(0xFF050816),
    surface: Color(0xFF0F172A),
    surfaceElevated: Color(0xFF1E293B),
    primary: Color(0xFF60A5FA),
    primarySoft: Color(0xFF3B82F6),
    income: Color(0xFF34D399),
    expense: Color(0xFFFB7185),
    transfer: Color(0xFFCBD5E1),
    warning: Color(0xFFFBBF24),
    neutral: Color(0xFF94A3B8),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    divider: Color(0xFF1E293B),
  );

  static const _aurora = StreamThemePalette(
    canvas: Color(0xFF100A2A),
    surface: Color(0xFF1E1B4B),
    surfaceElevated: Color(0xFF29245F),
    primary: Color(0xFF8B5CF6),
    primarySoft: Color(0xFF7C3AED),
    income: Color(0xFF10B981),
    expense: Color(0xFFF43F5E),
    transfer: Color(0xFFA5B4FC),
    warning: Color(0xFFF59E0B),
    neutral: Color(0xFF94A3B8),
    textPrimary: Color(0xFFEEF2FF),
    textSecondary: Color(0xFFA5B4FC),
    textMuted: Color(0xFF7C8DB5),
    divider: Color(0xFF29245F),
  );

  static const _minimalSand = StreamThemePalette(
    canvas: Color(0xFFFAF7F0),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF3ECE1),
    primary: Color(0xFFC08457),
    primarySoft: Color(0xFFA8653A),
    income: Color(0xFF15803D),
    expense: Color(0xFFB91C1C),
    transfer: Color(0xFF78716C),
    warning: Color(0xFFCA8A04),
    neutral: Color(0xFF78716C),
    textPrimary: Color(0xFF292524),
    textSecondary: Color(0xFF78716C),
    textMuted: Color(0xFFA8A29E),
    divider: Color(0xFFE7E5E4),
  );

  static const _highContrast = StreamThemePalette(
    canvas: Color(0xFF000000),
    surface: Color(0xFF111111),
    surfaceElevated: Color(0xFF1A1A1A),
    primary: Color(0xFFFFFF00),
    primarySoft: Color(0xFFE6E600),
    income: Color(0xFF00FF66),
    expense: Color(0xFFFF3366),
    transfer: Color(0xFFFFFFFF),
    warning: Color(0xFFFFAA00),
    neutral: Color(0xFFCCCCCC),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
    textMuted: Color(0xFF999999),
    divider: Color(0xFF333333),
  );

  static const StreamThemePalette defaultPalette = _classic;

  static StreamThemePalette of(StreamThemeId id) {
    switch (id) {
      case StreamThemeId.streamClassic:
        return _classic;
      case StreamThemeId.forest:
        return _forest;
      case StreamThemeId.midnight:
        return _midnight;
      case StreamThemeId.aurora:
        return _aurora;
      case StreamThemeId.minimalSand:
        return _minimalSand;
      case StreamThemeId.highContrast:
        return _highContrast;
    }
  }
}

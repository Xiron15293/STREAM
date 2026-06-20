import 'package:flutter/material.dart';
import 'stream_theme_palette.dart';
import 'stream_chart_palette.dart';

class StreamThemeExtension extends ThemeExtension<StreamThemeExtension> {
  final StreamThemePalette palette;
  final StreamChartPalette chartPalette;

  const StreamThemeExtension({
    required this.palette,
    required this.chartPalette,
  });

  @override
  ThemeExtension<StreamThemeExtension> copyWith({
    StreamThemePalette? palette,
    StreamChartPalette? chartPalette,
  }) {
    return StreamThemeExtension(
      palette: palette ?? this.palette,
      chartPalette: chartPalette ?? this.chartPalette,
    );
  }

  @override
  ThemeExtension<StreamThemeExtension> lerp(
    ThemeExtension<StreamThemeExtension>? other,
    double t,
  ) {
    if (other is! StreamThemeExtension) return this;
    return StreamThemeExtension(
      palette: t < 0.5 ? palette : other.palette,
      chartPalette: t < 0.5 ? chartPalette : other.chartPalette,
    );
  }

  static StreamThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<StreamThemeExtension>()!;
  }

  static StreamThemeExtension? tryOf(BuildContext context) {
    return Theme.of(context).extension<StreamThemeExtension>();
  }
}

extension StreamThemeContext on BuildContext {
  StreamThemeExtension get streamTheme =>
      StreamThemeExtension.tryOf(this) ?? _fallbackExt;
  StreamThemePalette get $palette => streamTheme.palette;
  StreamChartPalette get $chart => streamTheme.chartPalette;
}

const _fallbackPalette = StreamThemePalette(
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

const _fallbackChartPalette = StreamChartPalette(
  donutColors: [
    Color(0xFF4B7BFF),
    Color(0xFF22D3EE),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
    Color(0xFFFB7185),
    Color(0xFF818CF8),
    Color(0xFF94A3B8),
  ],
  categoryColors: [
    Color(0xFF4B7BFF),
    Color(0xFF22D3EE),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
    Color(0xFFFB7185),
    Color(0xFF818CF8),
    Color(0xFF94A3B8),
  ],
  gridColor: Color(0x20FFFFFF),
  axisTextColor: Color(0xFF8E8E93),
  legendTextColor: Color(0xFF8E8E93),
);

const _fallbackExt = StreamThemeExtension(
  palette: _fallbackPalette,
  chartPalette: _fallbackChartPalette,
);

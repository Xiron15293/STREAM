import 'package:flutter/material.dart';
import 'stream_kpi_style.dart';
import 'stream_theme_palette.dart';

class StreamChartPalette {
  final List<Color> donutColors;
  final List<Color> categoryColors;
  final Color gridColor;
  final Color axisTextColor;
  final Color legendTextColor;
  final Color cardBackground;
  final Color cardBorderColor;
  final double cardBorderWidth;
  final double cardRadius;
  final List<BoxShadow> cardShadows;
  final Color emptyStateIconColor;
  final Color emptyStateTextColor;
  final Color legendAccentColor;
  final Color horizontalTrackColor;
  final double horizontalBarHeight;
  final double horizontalBarRadius;
  final double singleBarWidth;
  final double groupedBarWidth;
  final double barTopRadius;
  final double donutCenterRadius;
  final double donutOuterRadius;
  final double donutLabelDistance;
  final double donutLegendDotSize;

  const StreamChartPalette({
    required this.donutColors,
    required this.categoryColors,
    this.gridColor = const Color(0x20FFFFFF),
    this.axisTextColor = const Color(0xFF8E8E93),
    this.legendTextColor = const Color(0xFF8E8E93),
    this.cardBackground = const Color(0xFF15171D),
    this.cardBorderColor = const Color(0xFF1E2028),
    this.cardBorderWidth = 1,
    this.cardRadius = 16,
    this.cardShadows = const [],
    this.emptyStateIconColor = const Color(0xFF636366),
    this.emptyStateTextColor = const Color(0xFF8E8E93),
    this.legendAccentColor = const Color(0xFF8E8E93),
    this.horizontalTrackColor = const Color(0xCC1E2028),
    this.horizontalBarHeight = 28,
    this.horizontalBarRadius = 4,
    this.singleBarWidth = 14,
    this.groupedBarWidth = 8,
    this.barTopRadius = 3,
    this.donutCenterRadius = 30,
    this.donutOuterRadius = 52,
    this.donutLabelDistance = 74,
    this.donutLegendDotSize = 8,
  });

  StreamChartPalette applyStyle(
    StreamChartStyleId style,
    StreamThemePalette appPalette,
  ) {
    switch (style) {
      case StreamChartStyleId.automatic:
        return this;
      case StreamChartStyleId.soft:
        return _applySoft(appPalette);
      case StreamChartStyleId.technical:
        return _applyTechnical(appPalette);
      case StreamChartStyleId.highContrast:
        return _applyHighContrast(appPalette);
      case StreamChartStyleId.editorial:
        return _applyEditorial(appPalette);
    }
  }

  StreamChartPalette _applySoft(StreamThemePalette p) {
    final isLight = p.brightness == Brightness.light;
    return StreamChartPalette(
      donutColors: donutColors.map((c) => c.withValues(alpha: 0.85)).toList(),
      categoryColors: categoryColors
          .map((c) => c.withValues(alpha: 0.85))
          .toList(),
      gridColor: isLight ? const Color(0x08000000) : const Color(0x08FFFFFF),
      axisTextColor: p.textMuted,
      legendTextColor: p.textMuted,
      cardBackground: p.surfaceElevated.withValues(alpha: isLight ? 0.78 : 0.72),
      cardBorderColor: Colors.transparent,
      cardBorderWidth: 0,
      cardRadius: 18,
      cardShadows: const [],
      emptyStateIconColor: p.textMuted,
      emptyStateTextColor: p.textSecondary,
      legendAccentColor: p.textMuted,
      horizontalTrackColor: p.surfaceElevated.withValues(
        alpha: isLight ? 0.42 : 0.68,
      ),
      horizontalBarHeight: 24,
      horizontalBarRadius: 10,
      singleBarWidth: 12,
      groupedBarWidth: 7,
      barTopRadius: 8,
      donutCenterRadius: 34,
      donutOuterRadius: 50,
      donutLabelDistance: 76,
      donutLegendDotSize: 7,
    );
  }

  StreamChartPalette _applyTechnical(StreamThemePalette p) {
    final isLight = p.brightness == Brightness.light;
    return StreamChartPalette(
      donutColors: [
        p.primary,
        p.income,
        p.expense,
        const Color(0xFF22D3EE),
        const Color(0xFFA78BFA),
        const Color(0xFFFBBF24),
        const Color(0xFF34D399),
        const Color(0xFFFB7185),
      ],
      categoryColors: [
        p.primary,
        p.income,
        p.expense,
        const Color(0xFF22D3EE),
        const Color(0xFFA78BFA),
        const Color(0xFFFBBF24),
        const Color(0xFF34D399),
        const Color(0xFFFB7185),
      ],
      gridColor: isLight ? const Color(0x30000000) : const Color(0x30FFFFFF),
      axisTextColor: p.textPrimary,
      legendTextColor: p.textPrimary,
      cardBackground: p.surface,
      cardBorderColor: p.divider.withValues(alpha: 0.95),
      cardBorderWidth: 1.3,
      cardRadius: 14,
      cardShadows: const [],
      emptyStateIconColor: p.textPrimary,
      emptyStateTextColor: p.textPrimary,
      legendAccentColor: p.textPrimary,
      horizontalTrackColor: p.surfaceElevated.withValues(
        alpha: isLight ? 0.72 : 0.88,
      ),
      horizontalBarHeight: 22,
      horizontalBarRadius: 3,
      singleBarWidth: 12,
      groupedBarWidth: 7,
      barTopRadius: 2,
      donutCenterRadius: 28,
      donutOuterRadius: 54,
      donutLabelDistance: 78,
      donutLegendDotSize: 8,
    );
  }

  StreamChartPalette _applyHighContrast(StreamThemePalette p) {
    return StreamChartPalette(
      donutColors: const [
        Color(0xFFFFFF00),
        Color(0xFF00FF66),
        Color(0xFFFF3366),
        Color(0xFF00E5FF),
        Color(0xFFAA00FF),
        Color(0xFFFF8800),
        Color(0xFF00CCFF),
        Color(0xFFFFFFFF),
      ],
      categoryColors: const [
        Color(0xFFFFFF00),
        Color(0xFF00FF66),
        Color(0xFFFF3366),
        Color(0xFF00E5FF),
        Color(0xFFAA00FF),
        Color(0xFFFF8800),
        Color(0xFF00CCFF),
        Color(0xFFFFFFFF),
      ],
      gridColor: const Color(0x50FFFFFF),
      axisTextColor: Colors.white,
      legendTextColor: Colors.white,
      cardBackground: Colors.black,
      cardBorderColor: Colors.white,
      cardBorderWidth: 1.5,
      cardRadius: 14,
      cardShadows: const [],
      emptyStateIconColor: Colors.white,
      emptyStateTextColor: Colors.white,
      legendAccentColor: Colors.white,
      horizontalTrackColor: const Color(0xFF2A2A2A),
      horizontalBarHeight: 26,
      horizontalBarRadius: 2,
      singleBarWidth: 15,
      groupedBarWidth: 9,
      barTopRadius: 2,
      donutCenterRadius: 26,
      donutOuterRadius: 56,
      donutLabelDistance: 82,
      donutLegendDotSize: 9,
    );
  }

  StreamChartPalette _applyEditorial(StreamThemePalette p) {
    final isLight = p.brightness == Brightness.light;
    return StreamChartPalette(
      donutColors: const [
        Color(0xFF6366F1),
        Color(0xFF22C55E),
        Color(0xFFEF4444),
        Color(0xFF06B6D4),
        Color(0xFF8B5CF6),
        Color(0xFFD97706),
        Color(0xFF14B8A6),
        Color(0xFF78716C),
      ],
      categoryColors: const [
        Color(0xFF6366F1),
        Color(0xFF22C55E),
        Color(0xFFEF4444),
        Color(0xFF06B6D4),
        Color(0xFF8B5CF6),
        Color(0xFFD97706),
        Color(0xFF14B8A6),
        Color(0xFF78716C),
      ],
      gridColor: isLight ? const Color(0x06000000) : const Color(0x06FFFFFF),
      axisTextColor: p.textSecondary,
      legendTextColor: p.textMuted,
      cardBackground: p.surface,
      cardBorderColor: p.divider.withValues(alpha: 0.24),
      cardBorderWidth: 0.8,
      cardRadius: 20,
      cardShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.16),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
      emptyStateIconColor: p.textSecondary,
      emptyStateTextColor: p.textSecondary,
      legendAccentColor: p.textSecondary,
      horizontalTrackColor: p.surfaceElevated.withValues(
        alpha: isLight ? 0.34 : 0.54,
      ),
      horizontalBarHeight: 20,
      horizontalBarRadius: 999,
      singleBarWidth: 10,
      groupedBarWidth: 6,
      barTopRadius: 999,
      donutCenterRadius: 36,
      donutOuterRadius: 48,
      donutLabelDistance: 72,
      donutLegendDotSize: 7,
    );
  }

  static StreamChartPalette forTheme(StreamThemePalette p) {
    if (p.isHighContrastTheme) {
      return StreamChartPalette(
        donutColors: const [
          Color(0xFFFFFF00),
          Color(0xFF00FF66),
          Color(0xFFFF3366),
          Color(0xFF00E5FF),
          Color(0xFFFF8800),
          Color(0xFFFFFFFF),
          Color(0xFFAA00FF),
          Color(0xFF00CCFF),
        ],
        categoryColors: const [
          Color(0xFFFFFF00),
          Color(0xFF00FF66),
          Color(0xFFFF3366),
          Color(0xFF00E5FF),
          Color(0xFFFF8800),
          Color(0xFFFFFFFF),
          Color(0xFFAA00FF),
          Color(0xFF00CCFF),
        ],
        gridColor: const Color(0x52FFFFFF),
        axisTextColor: p.textPrimary,
        legendTextColor: p.textPrimary,
        cardBackground: p.surface,
        cardBorderColor: p.divider,
        cardBorderWidth: 1,
        cardRadius: 16,
        cardShadows: const [],
        emptyStateIconColor: p.textMuted,
        emptyStateTextColor: p.textSecondary,
        legendAccentColor: p.textPrimary,
        horizontalTrackColor: p.surfaceElevated.withValues(alpha: 0.88),
        horizontalBarHeight: 28,
        horizontalBarRadius: 4,
        singleBarWidth: 14,
        groupedBarWidth: 8,
        barTopRadius: 3,
        donutCenterRadius: 30,
        donutOuterRadius: 52,
        donutLabelDistance: 74,
        donutLegendDotSize: 8,
      );
    }

    final isLight = p.brightness == Brightness.light;
    final grid = p.isMinimalSandTheme
        ? const Color(0x1F6B5A3A)
        : p.isMidnightTheme
        ? const Color(0x33D8E3F0)
        : p.isForestTheme
        ? const Color(0x2460A77A)
        : isLight
        ? const Color(0x20000000)
        : const Color(0x20FFFFFF);
    final axis = p.isMidnightTheme ? p.textPrimary : p.textSecondary;
    final legend = p.isMinimalSandTheme ? p.textPrimary : axis;

    return StreamChartPalette(
      donutColors: _donutFor(p),
      categoryColors: _categoryFor(p),
      gridColor: grid,
      axisTextColor: axis,
      legendTextColor: legend,
      cardBackground: p.surface,
      cardBorderColor: p.divider,
      cardBorderWidth: 1,
      cardRadius: 16,
      cardShadows: const [],
      emptyStateIconColor: p.textMuted,
      emptyStateTextColor: p.textSecondary,
      legendAccentColor: legend,
      horizontalTrackColor: p.surfaceElevated.withValues(
        alpha: isLight ? 0.55 : 0.82,
      ),
      horizontalBarHeight: 28,
      horizontalBarRadius: 4,
      singleBarWidth: 14,
      groupedBarWidth: 8,
      barTopRadius: 3,
      donutCenterRadius: 30,
      donutOuterRadius: 52,
      donutLabelDistance: 74,
      donutLegendDotSize: 8,
    );
  }

  static List<Color> _donutFor(StreamThemePalette p) {
    if (p.isForestTheme) {
      return [
        p.primary,
        p.income,
        p.warning,
        const Color(0xFF84CC16),
        const Color(0xFFF97316),
        const Color(0xFF2DD4BF),
        const Color(0xFFA3E635),
        const Color(0xFFD4D4D8),
      ];
    }
    if (p.isMidnightTheme) {
      return [
        p.primary,
        const Color(0xFF38BDF8),
        p.income,
        const Color(0xFFA78BFA),
        p.expense,
        const Color(0xFFFBBF24),
        const Color(0xFF22D3EE),
        const Color(0xFFCBD5E1),
      ];
    }
    if (p.isMinimalSandTheme) {
      return [
        p.primary,
        p.income,
        p.expense,
        const Color(0xFFB7791F),
        const Color(0xFF2C7A7B),
        const Color(0xFF9C4221),
        const Color(0xFF718096),
        const Color(0xFF8C6D46),
      ];
    }
    if (p.isAuroraTheme) {
      return [
        p.primary,
        const Color(0xFF60A5FA),
        const Color(0xFFA78BFA),
        p.income,
        p.expense,
        const Color(0xFFFBBF24),
        const Color(0xFF22D3EE),
        const Color(0xFFC4B5FD),
      ];
    }
    if (p.brightness == Brightness.light) {
      return [
        p.primary,
        const Color(0xFF0891B2),
        const Color(0xFF7C3AED),
        const Color(0xFFD97706),
        const Color(0xFF059669),
        const Color(0xFFDB2777),
        const Color(0xFF4F46E5),
        const Color(0xFF78716C),
      ];
    }
    return [
      p.primary,
      const Color(0xFF22D3EE),
      const Color(0xFFA78BFA),
      const Color(0xFFFBBF24),
      const Color(0xFF34D399),
      const Color(0xFFFB7185),
      const Color(0xFF818CF8),
      const Color(0xFF94A3B8),
    ];
  }

  static List<Color> _categoryFor(StreamThemePalette p) => _donutFor(p);
}

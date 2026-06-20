import 'package:flutter/material.dart';
import 'stream_kpi_style.dart';
import 'stream_theme_palette.dart';

class StreamChartPalette {
  final List<Color> donutColors;
  final List<Color> categoryColors;
  final Color gridColor;
  final Color axisTextColor;
  final Color legendTextColor;

  const StreamChartPalette({
    required this.donutColors,
    required this.categoryColors,
    this.gridColor = const Color(0x20FFFFFF),
    this.axisTextColor = const Color(0xFF8E8E93),
    this.legendTextColor = const Color(0xFF8E8E93),
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

import 'package:flutter/material.dart';

import 'stream_theme_palette.dart';

class StreamSurfaceTokens {
  final Color background;
  final Color border;
  final double borderWidth;
  final List<BoxShadow> shadows;

  const StreamSurfaceTokens({
    required this.background,
    required this.border,
    required this.borderWidth,
    required this.shadows,
  });

  factory StreamSurfaceTokens.card(
    StreamThemePalette palette, {
    bool elevated = false,
    bool muted = false,
  }) {
    final isLight = palette.brightness == Brightness.light;
    final isHighContrast = palette.canvas.toARGB32() == 0xFF000000;
    final background = elevated
        ? palette.surfaceElevated
        : muted
        ? palette.surfaceElevated.withValues(alpha: isLight ? 0.72 : 0.5)
        : palette.surface;

    return StreamSurfaceTokens(
      background: background,
      border: isHighContrast
          ? palette.textSecondary.withValues(alpha: 0.92)
          : palette.divider.withValues(alpha: isLight ? 0.9 : 0.82),
      borderWidth: isHighContrast ? 1.4 : 1.0,
      shadows: isHighContrast
          ? const []
          : [
              BoxShadow(
                color: isLight
                    ? const Color(0x14000000)
                    : const Color(0x22000000),
                blurRadius: elevated ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static Color onAccent(Color color) {
    return color.computeLuminance() > 0.58
        ? const Color(0xFF111111)
        : Colors.white;
  }
}

import 'package:flutter/material.dart';

import '../data/preferences_service.dart';
import '../design/stream_kpi_style.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../design/stream_theme_palette.dart';
import '../theme.dart';

enum StreamKpiSemanticType { neutral, income, expense, balance, count, warning }

enum StreamKpiLayout { auto, stacked, centered, inline }

enum StreamKpiDensity { regular, compact, tight }

/// Emphasis level for a StreamKpiCard.
///
/// * [normal] — default card styling.
/// * [hero] — stronger visual impact for hero/key cards (e.g. Dashboard net worth).
///   In High Contrast, hero cards use a strong yellow background with black text.
enum StreamKpiEmphasis { normal, hero }

class StreamKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final StreamKpiSemanticType semanticType;
  final Color? accentColor;
  final StreamKpiLayout layout;
  final StreamKpiDensity density;
  final StreamKpiEmphasis emphasis;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final bool uppercaseTitle;
  final Widget? trailing;
  final Key? cardKey;
  final Key? titleKey;
  final Key? valueKey;
  final Key? subtitleKey;

  const StreamKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.semanticType = StreamKpiSemanticType.neutral,
    this.accentColor,
    this.layout = StreamKpiLayout.auto,
    this.density = StreamKpiDensity.regular,
    this.emphasis = StreamKpiEmphasis.normal,
    this.margin,
    this.padding,
    this.width,
    this.uppercaseTitle = true,
    this.trailing,
    this.cardKey,
    this.titleKey,
    this.valueKey,
    this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width;
    return ValueListenableBuilder<String>(
      valueListenable: PreferencesService.kpiStyleNotifier,
      builder: (context, rawStyle, _) {
        final palette = context.$palette;
        final styleId = StreamKpiStyleId.fromString(rawStyle);
        final accent = accentColor ?? _resolveAccent(palette);
        final chrome = resolveKpiChrome(palette, accent, styleId, density, emphasis);
        final effectiveLayout = layout == StreamKpiLayout.auto
            ? (styleId == StreamKpiStyleId.dense
                  ? StreamKpiLayout.inline
                  : StreamKpiLayout.stacked)
            : layout;

        Widget child;
        switch (effectiveLayout) {
          case StreamKpiLayout.centered:
            child = _CenteredKpiBody(
              title: title,
              value: value,
              subtitle: subtitle,
              icon: icon,
              accent: accent,
              chrome: chrome,
              uppercaseTitle: uppercaseTitle,
              titleKey: titleKey,
              valueKey: valueKey,
              subtitleKey: subtitleKey,
            );
          case StreamKpiLayout.inline:
            child = _InlineKpiBody(
              title: title,
              value: value,
              subtitle: subtitle,
              icon: icon,
              accent: accent,
              chrome: chrome,
              uppercaseTitle: uppercaseTitle,
              titleKey: titleKey,
              valueKey: valueKey,
              subtitleKey: subtitleKey,
            );
          case StreamKpiLayout.stacked:
          case StreamKpiLayout.auto:
            child = _StackedKpiBody(
              title: title,
              value: value,
              subtitle: subtitle,
              icon: icon,
              accent: accent,
              chrome: chrome,
              uppercaseTitle: uppercaseTitle,
              titleKey: titleKey,
              valueKey: valueKey,
              subtitleKey: subtitleKey,
            );
        }

        Widget content = child;
        if (trailing != null && effectiveLayout != StreamKpiLayout.centered) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: child),
              const SizedBox(width: StreamSpacing.sm),
              Flexible(child: trailing!),
            ],
          );
        }

        final card = AnimatedContainer(
          key: cardKey,
          duration: const Duration(milliseconds: 220),
          width: resolvedWidth,
          margin: margin,
          padding: padding ?? chrome.padding,
          decoration: BoxDecoration(
            color: chrome.backgroundColor,
            gradient: chrome.gradient,
            borderRadius: BorderRadius.circular(chrome.radius),
            border: chrome.border,
            boxShadow: chrome.shadows,
          ),
          child: chrome.leftAccent
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: chrome.accentStripeWidth,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: chrome.accentStripeAlpha),
                        borderRadius: BorderRadius.circular(StreamRadius.full),
                      ),
                    ),
                    const SizedBox(width: StreamSpacing.sm),
                    Expanded(child: content),
                  ],
                )
              : content,
        );

        if (resolvedWidth != null) {
          return card;
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 92),
          child: card,
        );
      },
    );
  }

  Color _resolveAccent(StreamThemePalette palette) {
    switch (semanticType) {
      case StreamKpiSemanticType.income:
        return palette.income;
      case StreamKpiSemanticType.expense:
        return palette.expense;
      case StreamKpiSemanticType.balance:
        return palette.primary;
      case StreamKpiSemanticType.count:
        return palette.textPrimary;
      case StreamKpiSemanticType.warning:
        return palette.warning;
      case StreamKpiSemanticType.neutral:
        return palette.primary;
    }
  }
}

class _StackedKpiBody extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color accent;
  final StreamKpiChrome chrome;
  final bool uppercaseTitle;
  final Key? titleKey;
  final Key? valueKey;
  final Key? subtitleKey;

  const _StackedKpiBody({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.chrome,
    required this.uppercaseTitle,
    required this.titleKey,
    required this.valueKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleRow(
          title: title,
          icon: icon,
          accent: accent,
          style: chrome.titleStyle,
          uppercaseTitle: uppercaseTitle,
          titleKey: titleKey,
        ),
        SizedBox(height: chrome.valueSpacing),
        Text(
          value,
          key: valueKey,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: chrome.valueStyle.copyWith(color: accent),
        ),
        if (subtitle != null) ...[
          SizedBox(height: chrome.subtitleSpacing),
          Text(
            subtitle!,
            key: subtitleKey,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: chrome.subtitleStyle,
          ),
        ],
      ],
    );
  }
}

class _InlineKpiBody extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color accent;
  final StreamKpiChrome chrome;
  final bool uppercaseTitle;
  final Key? titleKey;
  final Key? valueKey;
  final Key? subtitleKey;

  const _InlineKpiBody({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.chrome,
    required this.uppercaseTitle,
    required this.titleKey,
    required this.valueKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _TitleRow(
                title: title,
                icon: icon,
                accent: accent,
                style: chrome.titleStyle,
                uppercaseTitle: uppercaseTitle,
                titleKey: titleKey,
              ),
            ),
            const SizedBox(width: StreamSpacing.xs),
            Flexible(
              child: Text(
                value,
                key: valueKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: chrome.valueStyle.copyWith(color: accent),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: chrome.subtitleSpacing),
          Text(
            subtitle!,
            key: subtitleKey,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: chrome.subtitleStyle,
          ),
        ],
      ],
    );
  }
}

class _CenteredKpiBody extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color accent;
  final StreamKpiChrome chrome;
  final bool uppercaseTitle;
  final Key? titleKey;
  final Key? valueKey;
  final Key? subtitleKey;

  const _CenteredKpiBody({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.chrome,
    required this.uppercaseTitle,
    required this.titleKey,
    required this.valueKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: chrome.centeredIconSize, color: accent),
          const SizedBox(height: StreamSpacing.xs),
        ],
        Text(
          value,
          key: valueKey,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: chrome.valueStyle.copyWith(color: accent),
        ),
        SizedBox(height: chrome.subtitleSpacing),
        Text(
          uppercaseTitle ? title.toUpperCase() : title,
          key: titleKey,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: chrome.titleStyle,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: StreamSpacing.xs),
          Text(
            subtitle!,
            key: subtitleKey,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: chrome.subtitleStyle,
          ),
        ],
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color accent;
  final TextStyle style;
  final bool uppercaseTitle;
  final Key? titleKey;

  const _TitleRow({
    required this.title,
    required this.icon,
    required this.accent,
    required this.style,
    required this.uppercaseTitle,
    required this.titleKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: style.fontSize != null ? style.fontSize! + 1 : 12, color: accent),
          const SizedBox(width: StreamSpacing.xs),
        ],
        Expanded(
          child: Text(
            uppercaseTitle ? title.toUpperCase() : title,
            key: titleKey,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class StreamKpiChrome {
  final Color backgroundColor;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow> shadows;
  final EdgeInsets padding;
  final double radius;
  final bool leftAccent;
  final double accentStripeWidth;
  final double accentStripeAlpha;
  final TextStyle titleStyle;
  final TextStyle valueStyle;
  final TextStyle subtitleStyle;
  final double valueSpacing;
  final double subtitleSpacing;
  final double centeredIconSize;

  const StreamKpiChrome({
    required this.backgroundColor,
    required this.gradient,
    required this.border,
    required this.shadows,
    required this.padding,
    required this.radius,
    required this.leftAccent,
    required this.accentStripeWidth,
    required this.accentStripeAlpha,
    required this.titleStyle,
    required this.valueStyle,
    required this.subtitleStyle,
    required this.valueSpacing,
    required this.subtitleSpacing,
    required this.centeredIconSize,
  });

  StreamKpiChrome copyWith({
    Color? backgroundColor,
    Gradient? gradient,
    bool clearGradient = false,
    Border? border,
    bool clearBorder = false,
    List<BoxShadow>? shadows,
    EdgeInsets? padding,
    double? radius,
    bool? leftAccent,
    double? accentStripeWidth,
    double? accentStripeAlpha,
    TextStyle? titleStyle,
    TextStyle? valueStyle,
    TextStyle? subtitleStyle,
    double? valueSpacing,
    double? subtitleSpacing,
    double? centeredIconSize,
  }) {
    return StreamKpiChrome(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: clearGradient ? null : gradient ?? this.gradient,
      border: clearBorder ? null : border ?? this.border,
      shadows: shadows ?? this.shadows,
      padding: padding ?? this.padding,
      radius: radius ?? this.radius,
      leftAccent: leftAccent ?? this.leftAccent,
      accentStripeWidth: accentStripeWidth ?? this.accentStripeWidth,
      accentStripeAlpha: accentStripeAlpha ?? this.accentStripeAlpha,
      titleStyle: titleStyle ?? this.titleStyle,
      valueStyle: valueStyle ?? this.valueStyle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      valueSpacing: valueSpacing ?? this.valueSpacing,
      subtitleSpacing: subtitleSpacing ?? this.subtitleSpacing,
      centeredIconSize: centeredIconSize ?? this.centeredIconSize,
    );
  }
}

/// Clamp an alpha value to the valid [0.0, 1.0] range.
double safeAlpha(double value) => value.clamp(0.0, 1.0);

/// Returns a base alpha modifier and surface character for each theme.
/// Used by resolveKpiChrome to produce distinctly different chrome per theme.
Color _themeAccentBase(StreamThemePalette palette, Color accent) {
  // Blend the accent color with a theme-specific secondary to create
  // a recognizable character per theme.
  if (palette.isForestTheme) {
    return Color.lerp(accent, const Color(0xFF22C55E), 0.3)!;
  }
  if (palette.isMidnightTheme) {
    return Color.lerp(accent, const Color(0xFF38BDF8), 0.25)!;
  }
  if (palette.isAuroraTheme) {
    return Color.lerp(accent, const Color(0xFFA78BFA), 0.3)!;
  }
  if (palette.isMinimalSandTheme) {
    return Color.lerp(accent, const Color(0xFFC08457), 0.2)!;
  }
  if (palette.isHighContrastTheme) {
    return Color.lerp(accent, const Color(0xFFFFFF00), 0.4)!;
  }
  // Classic default
  return Color.lerp(accent, const Color(0xFF4B7BFF), 0.2)!;
}

/// Select the border color per theme and style — ensures every theme has
/// a visibly distinct border tone.
Color _themeBorderColor(StreamThemePalette palette, Color accent, double alpha) {
  if (palette.isForestTheme) return const Color(0xFF22C55E).withValues(alpha: alpha);
  if (palette.isMidnightTheme) return const Color(0xFF38BDF8).withValues(alpha: alpha);
  if (palette.isAuroraTheme) return const Color(0xFFA78BFA).withValues(alpha: alpha);
  if (palette.isMinimalSandTheme) return const Color(0xFFC08457).withValues(alpha: alpha);
  if (palette.isHighContrastTheme) return const Color(0xFFFFFF00).withValues(alpha: alpha);
  return accent.withValues(alpha: alpha);
}

/// Shared resolver used by StreamKpiCard and Dashboard _BalanceHero.
/// Produces recognizably different chrome for every theme x style x emphasis combination.
StreamKpiChrome resolveKpiChrome(
  StreamThemePalette palette,
  Color accent,
  StreamKpiStyleId styleId,
  StreamKpiDensity density,
  StreamKpiEmphasis emphasis,
) {
  final baseSurface = StreamSurfaceTokens.card(palette, elevated: true);
  final isHighContrast = palette.isHighContrastTheme;
  final isForest = palette.isForestTheme;
  final isMidnight = palette.isMidnightTheme;
  final isAurora = palette.isAuroraTheme;
  final isSand = palette.isMinimalSandTheme;
  final isHero = emphasis == StreamKpiEmphasis.hero;
  final compact = density == StreamKpiDensity.compact;
  final tight = density == StreamKpiDensity.tight;

  final heroPaddingMul = isHero ? 1.3 : 1.0;
  final heroFontMul = isHero ? 1.2 : 1.0;
  final heroBorderMul = isHero ? 1.5 : 1.0;

  EdgeInsets paddingBase(bool tight, bool compact) {
    final hPad = tight ? 8.0 : compact ? 10.0 : StreamSpacing.md.toDouble();
    final vPad = tight ? 6.0 : compact ? 8.0 : StreamSpacing.md.toDouble();
    return EdgeInsets.symmetric(
      horizontal: hPad * heroPaddingMul,
      vertical: vPad * heroPaddingMul,
    );
  }

  // Theme-specific accent: blend accent with a theme secondary for character.
  final themeAccent = _themeAccentBase(palette, accent);

  // For High Contrast, distinct chrome per style regardless of hero/normal.
  if (isHighContrast) {
    return _highContrastChrome(styleId, tight, compact, isHero);
  }

  // ---- Baby / normal chrome per style and theme ----
  final titleStyle = StreamTypography.micro.copyWith(
    fontSize: (tight ? 9 : compact ? 10 : 11) * (isHero ? 1.1 : 1.0),
    color: palette.textSecondary,
    letterSpacing: styleId == StreamKpiStyleId.dense ? 0.8 : 0.5,
  );
  final subtitleStyle = StreamTypography.micro.copyWith(
    fontSize: (tight ? 8 : 9) * (isHero ? 1.1 : 1.0),
    color: palette.textMuted,
  );

  // Factor: amplify per-style character for hero.
  final aMul = isHero ? 2.0 : 1.0;
  final bWidth = (isHero ? 1.5 : 1.0) * (styleId == StreamKpiStyleId.outline ? 1.4 : 1.0);

  switch (styleId) {
    case StreamKpiStyleId.dense:
      return StreamKpiChrome(
        backgroundColor: palette.surfaceElevated,
        gradient: isForest
            ? LinearGradient(colors: [const Color(0xFF22C55E).withValues(alpha: safeAlpha(0.08 * aMul)), palette.surfaceElevated])
            : isHero
                ? LinearGradient(colors: [themeAccent.withValues(alpha: 0.15), palette.surfaceElevated])
                : null,
        border: Border.all(
          color: _themeBorderColor(palette, themeAccent, safeAlpha(0.15 * aMul)),
          width: baseSurface.borderWidth * bWidth,
        ),
        shadows: const [],
        padding: EdgeInsets.symmetric(
          horizontal: (tight ? 6 : compact ? 8 : 10) * heroPaddingMul,
          vertical: (tight ? 4 : compact ? 5 : 6) * heroPaddingMul,
        ),
        radius: compact ? 8 : 10,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle.copyWith(
          fontSize: (tight ? 7.5 : compact ? 8 : 8.5) * heroFontMul,
          letterSpacing: 1.0,
        ),
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: (tight ? 10 : compact ? 11 : 12) * heroFontMul,
          fontWeight: isHero ? FontWeight.w900 : FontWeight.w700,
          height: 1,
        ),
        subtitleStyle: subtitleStyle.copyWith(fontSize: (tight ? 7 : 7.5) * heroFontMul),
        valueSpacing: 4,
        subtitleSpacing: 2,
        centeredIconSize: 12,
      );

    case StreamKpiStyleId.glass:
      return StreamKpiChrome(
        backgroundColor: palette.surfaceElevated.withValues(alpha: isHero ? 0.45 : 0.55),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeAccent.withValues(alpha: safeAlpha((isAurora ? 0.30 : isForest ? 0.22 : 0.18) * aMul)),
            palette.surface.withValues(alpha: isHero ? 0.85 : 0.92),
          ],
        ),
        border: Border.all(
          color: _themeBorderColor(palette, themeAccent, safeAlpha((isAurora ? 0.40 : 0.25) * aMul)),
          width: baseSurface.borderWidth * bWidth,
        ),
        shadows: baseSurface.shadows,
        padding: paddingBase(tight, compact),
        radius: isHero ? 20 : StreamRadius.lg,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle.copyWith(color: palette.textPrimary.withValues(alpha: 0.8)),
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: (tight ? 12 : compact ? 13 : 18) * heroFontMul,
          fontWeight: isHero ? FontWeight.w900 : FontWeight.w700,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: compact ? 4 : StreamSpacing.xs,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );

    case StreamKpiStyleId.outline:
      return StreamKpiChrome(
        backgroundColor: palette.surface.withValues(alpha: isHero ? 0.3 : 0.5),
        gradient: null,
        border: Border.all(
          color: _themeBorderColor(palette, themeAccent, safeAlpha(0.55 * aMul)),
          width: (isHero ? 2.5 : 1.5) * heroBorderMul,
        ),
        shadows: const [],
        padding: paddingBase(tight, compact),
        radius: 8,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle,
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: (tight ? 12 : compact ? 13 : 18) * heroFontMul,
          fontWeight: isHero ? FontWeight.w900 : FontWeight.w600,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: compact ? 4 : StreamSpacing.xs,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );

    case StreamKpiStyleId.solid:
      final solidAlpha = isHero ? 0.35 : (palette.brightness == Brightness.light ? 0.14 : 0.18);
      final bg = isMidnight
          ? const Color(0xFF38BDF8).withValues(alpha: isHero ? 0.40 : 0.20)
          : isForest
              ? const Color(0xFF22C55E).withValues(alpha: isHero ? 0.50 : 0.22)
              : isSand
                  ? const Color(0xFFC08457).withValues(alpha: isHero ? 0.35 : 0.15)
                  : isAurora
                      ? const Color(0xFFA78BFA).withValues(alpha: isHero ? 0.40 : 0.20)
                      : accent.withValues(alpha: solidAlpha);
      return StreamKpiChrome(
        backgroundColor: bg,
        gradient: null,
        border: null,
        shadows: const [],
        padding: paddingBase(tight, compact),
        radius: isHero ? 16 : StreamRadius.lg,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle.copyWith(color: palette.textPrimary),
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: (tight ? 12 : compact ? 13 : 18) * heroFontMul,
          fontWeight: FontWeight.w900,
        ),
        subtitleStyle: subtitleStyle.copyWith(color: palette.textSecondary),
        valueSpacing: compact ? 4 : StreamSpacing.xs,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );

    case StreamKpiStyleId.split:
      return StreamKpiChrome(
        backgroundColor: palette.surface,
        gradient: null,
        border: Border.all(
          color: _themeBorderColor(palette, themeAccent, safeAlpha(0.4 * aMul)),
          width: baseSurface.borderWidth * (isHero ? 1.5 : 1.0),
        ),
        shadows: baseSurface.shadows,
        padding: paddingBase(tight, compact),
        radius: StreamRadius.lg,
        leftAccent: true,
        accentStripeWidth: isHero ? (tight ? 6 : 8) : (tight ? 3 : 4),
        accentStripeAlpha: 0.95,
        titleStyle: titleStyle,
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: (tight ? 12 : compact ? 13 : 16) * heroFontMul,
          fontWeight: isHero ? FontWeight.w900 : FontWeight.w700,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: compact ? 4 : StreamSpacing.xs,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );

    case StreamKpiStyleId.automatic:
    case StreamKpiStyleId.minimal:
      return StreamKpiChrome(
        backgroundColor: palette.surface,
        gradient: isAurora
            ? LinearGradient(colors: [const Color(0xFFA78BFA).withValues(alpha: safeAlpha(0.10 * aMul)), palette.surface])
            : isHero
                ? LinearGradient(colors: [themeAccent.withValues(alpha: 0.12), palette.surface])
                : null,
        border: Border.all(
          color: baseSurface.border.withValues(alpha: isHero ? 0.6 : 0.3),
          width: baseSurface.borderWidth * (isHero ? 1.5 : 1.0),
        ),
        shadows: baseSurface.shadows,
        padding: tight
            ? EdgeInsets.symmetric(horizontal: 8, vertical: 7 * heroPaddingMul)
            : compact
                ? EdgeInsets.symmetric(horizontal: 10, vertical: 9 * heroPaddingMul)
                : EdgeInsets.all(StreamSpacing.md * heroPaddingMul),
        radius: StreamRadius.lg,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle,
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: (tight ? 12 : compact ? 13 : 20) * heroFontMul,
          fontWeight: isHero ? FontWeight.w900 : FontWeight.w700,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: compact ? 4 : StreamSpacing.sm,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );
  }
}

/// High Contrast chrome: each style keeps its own distinct look.
StreamKpiChrome _highContrastChrome(StreamKpiStyleId styleId, bool tight, bool compact, bool isHero) {
  const hcYellow = Color(0xFFFFFF00);
  const hcBlack = Colors.black;
  const hcWhite = Colors.white;
  final sc = isHero ? 1.2 : 1.0; // hero scale

  EdgeInsets pad(double h, double v) => EdgeInsets.symmetric(
        horizontal: h * sc,
        vertical: v * sc,
      );

  TextStyle titleStyle(double size) => StreamTypography.micro.copyWith(
        fontSize: size * sc,
        color: hcBlack,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  TextStyle valueStyle(double size) => StreamTypography.amountLarge.copyWith(
        fontSize: size * sc,
        color: hcBlack,
        fontWeight: FontWeight.w900,
      );

  // Helper: fill common defaults
  StreamKpiChrome hc(bool left, double stripeW, double stripeA, Gradient? g) => StreamKpiChrome(
        backgroundColor: hcYellow,
        gradient: g,
        border: Border.all(color: hcWhite, width: 1.0),
        shadows: const [],
        padding: pad(12, 10),
        radius: 12,
        leftAccent: left,
        accentStripeWidth: stripeW,
        accentStripeAlpha: stripeA,
        titleStyle: titleStyle(10),
        valueStyle: valueStyle(20),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: 9 * sc,
          color: hcBlack.withValues(alpha: 0.7),
        ),
        valueSpacing: StreamSpacing.xs,
        subtitleSpacing: 6,
        centeredIconSize: 16,
      );

  switch (styleId) {
    case StreamKpiStyleId.dense:
      return hc(false, 0, 0, null).copyWith(
        backgroundColor: hcYellow,
        border: Border.all(color: hcWhite, width: 1.0),
        padding: pad(tight ? 8 : compact ? 10 : 14, tight ? 4 : compact ? 6 : 10),
        radius: 8,
        titleStyle: titleStyle(tight ? 8 : 10),
        valueStyle: valueStyle(tight ? 14 : 18),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: (tight ? 7 : 9) * sc,
          color: hcBlack.withValues(alpha: 0.75),
        ),
        valueSpacing: 4,
        subtitleSpacing: 2,
        centeredIconSize: 12,
      );
    case StreamKpiStyleId.glass:
      return hc(false, 0, 0, LinearGradient(colors: [hcWhite.withValues(alpha: 0.3), hcYellow])).copyWith(
        backgroundColor: hcYellow.withValues(alpha: 0.85),
        padding: pad(tight ? 10 : compact ? 14 : 20, tight ? 8 : compact ? 10 : 16),
        radius: 20,
      );
    case StreamKpiStyleId.outline:
      return hc(false, 0, 0, null).copyWith(
        backgroundColor: hcBlack,
        border: Border.all(color: hcYellow, width: 2.0 * sc),
        padding: pad(tight ? 10 : compact ? 14 : 20, tight ? 8 : compact ? 10 : 16),
        radius: 8,
        titleStyle: titleStyle(tight ? 9 : 11).copyWith(color: hcYellow),
        valueStyle: valueStyle(tight ? 18 : 26).copyWith(color: hcYellow),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: (tight ? 8 : 10) * sc,
          color: hcYellow.withValues(alpha: 0.75),
        ),
      );
    case StreamKpiStyleId.solid:
      return hc(false, 0, 0, null).copyWith(
        backgroundColor: hcYellow,
        clearBorder: true,
        padding: pad(tight ? 10 : compact ? 14 : 20, tight ? 8 : compact ? 10 : 16),
        radius: 16,
        titleStyle: titleStyle(tight ? 9 : 11).copyWith(fontWeight: FontWeight.w700),
        valueStyle: valueStyle(tight ? 18 : 28),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: (tight ? 8 : 10) * sc,
          color: hcBlack.withValues(alpha: 0.8),
        ),
      );
    case StreamKpiStyleId.split:
      return hc(true, tight ? 6 : 8, 0.95, null).copyWith(
        backgroundColor: hcBlack,
        border: Border.all(color: hcYellow, width: 1.2 * sc),
        padding: pad(tight ? 10 : compact ? 14 : 20, tight ? 8 : compact ? 10 : 16),
        titleStyle: titleStyle(tight ? 9 : 11).copyWith(color: hcYellow),
        valueStyle: valueStyle(tight ? 18 : 26).copyWith(color: hcYellow),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: (tight ? 8 : 10) * sc,
          color: hcYellow.withValues(alpha: 0.75),
        ),
      );
    case StreamKpiStyleId.automatic:
    case StreamKpiStyleId.minimal:
      return hc(false, 0, 0, null).copyWith(
        backgroundColor: hcYellow,
        border: Border.all(color: hcWhite, width: 1.5 * sc),
        padding: pad(tight ? 10 : compact ? 14 : 20, tight ? 8 : compact ? 10 : 16),
        valueStyle: valueStyle(tight ? 18 : 26).copyWith(fontWeight: FontWeight.w800),
      );
  }
}

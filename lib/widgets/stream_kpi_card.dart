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
}

/// Shared resolver used by StreamKpiCard and Dashboard _BalanceHero.
/// Package-visible for reuse across screens.
StreamKpiChrome resolveKpiChrome(
  StreamThemePalette palette,
  Color accent,
  StreamKpiStyleId styleId,
  StreamKpiDensity density,
  StreamKpiEmphasis emphasis,
) {
  final baseSurface = StreamSurfaceTokens.card(palette, elevated: true);
  final isHighContrast = palette.isHighContrastTheme;
  final isHero = emphasis == StreamKpiEmphasis.hero;
  final compact = density == StreamKpiDensity.compact;
  final tight = density == StreamKpiDensity.tight;

  // Scaling factors for hero emphasis: scale up visual impact per style.
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

  final titleStyle = StreamTypography.micro.copyWith(
    fontSize: (tight ? 9 : compact ? 10 : 11) * (isHero ? 1.1 : 1.0),
    color: palette.textSecondary,
    letterSpacing: styleId == StreamKpiStyleId.dense ? 0.8 : 0.5,
  );
  final subtitleStyle = StreamTypography.micro.copyWith(
    fontSize: (tight ? 8 : 9) * (isHero ? 1.1 : 1.0),
    color: palette.textMuted,
  );

  // High Contrast hero override
  if (isHero && isHighContrast) {
    return _buildHighContrastHeroChrome(palette, styleId, tight, compact);
  }

  switch (styleId) {
    case StreamKpiStyleId.dense:
      final vPad = tight ? 4.0 : compact ? 5.0 : 6.0;
      return StreamKpiChrome(
        backgroundColor: palette.surfaceElevated,
        gradient: null,
        border: Border.all(
          color: baseSurface.border,
          width: baseSurface.borderWidth * heroBorderMul,
        ),
        shadows: const [],
        padding: EdgeInsets.symmetric(
          horizontal: (tight ? 6 : compact ? 8 : 10) * heroPaddingMul,
          vertical: vPad * heroPaddingMul,
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
        backgroundColor: palette.surfaceElevated.withValues(alpha: 0.55),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isHero ? 0.30 : 0.18),
            palette.surface.withValues(alpha: isHero ? 0.88 : 0.92),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isHero ? 0.5 : 0.25),
          width: baseSurface.borderWidth * heroBorderMul,
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
        backgroundColor: palette.surface.withValues(alpha: 0.5),
        gradient: null,
        border: Border.all(
          color: accent.withValues(alpha: isHero ? 0.95 : 0.55),
          width: (isHighContrast ? 2.0 : 1.5) * heroBorderMul,
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
      final solidAlpha = isHero
          ? (isHighContrast ? 0.50 : 0.35)
          : (isHighContrast ? 0.24 : palette.brightness == Brightness.light ? 0.14 : 0.18);
      return StreamKpiChrome(
        backgroundColor: accent.withValues(alpha: solidAlpha),
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
          color: accent.withValues(alpha: isHero ? 0.7 : 0.4),
          width: (isHero ? 1.5 : baseSurface.borderWidth) * heroBorderMul,
        ),
        shadows: isHighContrast ? const [] : baseSurface.shadows,
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
        gradient: isHero
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.20),
                  palette.surfaceElevated,
                ],
              )
            : null,
        border: Border.all(
          color: baseSurface.border.withValues(alpha: isHero ? 0.6 : 0.3),
          width: baseSurface.borderWidth * heroBorderMul,
        ),
        shadows: isHighContrast ? const [] : baseSurface.shadows,
        padding: tight
            ? EdgeInsets.symmetric(horizontal: 8, vertical: 7)
            : compact
            ? EdgeInsets.symmetric(horizontal: 10, vertical: 9)
            : EdgeInsets.all(StreamSpacing.md),
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

/// High Contrast hero chrome per style.
/// Each style keeps its character even in High Contrast hero mode.
StreamKpiChrome _buildHighContrastHeroChrome(
  StreamThemePalette palette,
  StreamKpiStyleId styleId,
  bool tight,
  bool compact,
) {
  // Default HC hero: yellow background, black text.
  const hcYellow = Color(0xFFFFFF00);
  const hcBlack = Colors.black;
  const hcWhite = Colors.white;

  switch (styleId) {
    case StreamKpiStyleId.dense:
      return StreamKpiChrome(
        backgroundColor: hcYellow,
        gradient: null,
        border: Border.all(color: hcWhite, width: 1.0),
        shadows: const [],
        padding: EdgeInsets.symmetric(
          horizontal: tight ? 8 : compact ? 10 : 14,
          vertical: tight ? 4 : compact ? 6 : 10,
        ),
        radius: 8,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 8 : 10,
          color: hcBlack,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: tight ? 14 : 18,
          color: hcBlack,
          fontWeight: FontWeight.w900,
        ),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 7 : 9,
          color: hcBlack.withValues(alpha: 0.75),
        ),
        valueSpacing: 4,
        subtitleSpacing: 2,
        centeredIconSize: 12,
      );
    case StreamKpiStyleId.glass:
      return StreamKpiChrome(
        backgroundColor: hcYellow.withValues(alpha: 0.85),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hcWhite.withValues(alpha: 0.3),
            hcYellow,
          ],
        ),
        border: Border.all(color: hcWhite, width: 1.2),
        shadows: const [],
        padding: EdgeInsets.symmetric(
          horizontal: tight ? 10 : compact ? 14 : 20,
          vertical: tight ? 8 : compact ? 10 : 16,
        ),
        radius: 20,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 9 : 11,
          color: hcBlack,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        valueStyle: StreamTypography.amountLarge.copyWith(
          fontSize: tight ? 18 : 26,
          color: hcBlack,
          fontWeight: FontWeight.w900,
        ),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 8 : 10,
          color: hcBlack.withValues(alpha: 0.7),
        ),
        valueSpacing: StreamSpacing.xs,
        subtitleSpacing: 6,
        centeredIconSize: 18,
      );
    case StreamKpiStyleId.outline:
      return StreamKpiChrome(
        backgroundColor: hcBlack,
        gradient: null,
        border: Border.all(color: hcYellow, width: 2.0),
        shadows: const [],
        padding: EdgeInsets.symmetric(
          horizontal: tight ? 10 : compact ? 14 : 20,
          vertical: tight ? 8 : compact ? 10 : 16,
        ),
        radius: 8,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 9 : 11,
          color: hcYellow,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        valueStyle: StreamTypography.amountLarge.copyWith(
          fontSize: tight ? 18 : 26,
          color: hcYellow,
          fontWeight: FontWeight.w900,
        ),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 8 : 10,
          color: hcYellow.withValues(alpha: 0.75),
        ),
        valueSpacing: StreamSpacing.xs,
        subtitleSpacing: 6,
        centeredIconSize: 18,
      );
    case StreamKpiStyleId.solid:
      return StreamKpiChrome(
        backgroundColor: hcYellow,
        gradient: null,
        border: null,
        shadows: const [],
        padding: EdgeInsets.symmetric(
          horizontal: tight ? 10 : compact ? 14 : 20,
          vertical: tight ? 8 : compact ? 10 : 16,
        ),
        radius: 16,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 9 : 11,
          color: hcBlack,
          fontWeight: FontWeight.w700,
        ),
        valueStyle: StreamTypography.amountLarge.copyWith(
          fontSize: tight ? 18 : 28,
          color: hcBlack,
          fontWeight: FontWeight.w900,
        ),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 8 : 10,
          color: hcBlack.withValues(alpha: 0.8),
        ),
        valueSpacing: StreamSpacing.xs,
        subtitleSpacing: 6,
        centeredIconSize: 18,
      );
    case StreamKpiStyleId.split:
      return StreamKpiChrome(
        backgroundColor: hcBlack,
        gradient: null,
        border: Border.all(color: hcYellow, width: 1.2),
        shadows: const [],
        padding: EdgeInsets.symmetric(
          horizontal: tight ? 10 : compact ? 14 : 20,
          vertical: tight ? 8 : compact ? 10 : 16,
        ),
        radius: StreamRadius.lg,
        leftAccent: true,
        accentStripeWidth: tight ? 6 : 8,
        accentStripeAlpha: 0.95,
        titleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 9 : 11,
          color: hcYellow,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        valueStyle: StreamTypography.amountLarge.copyWith(
          fontSize: tight ? 18 : 26,
          color: hcYellow,
          fontWeight: FontWeight.w900,
        ),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 8 : 10,
          color: hcYellow.withValues(alpha: 0.75),
        ),
        valueSpacing: StreamSpacing.xs,
        subtitleSpacing: 6,
        centeredIconSize: 18,
      );
    case StreamKpiStyleId.automatic:
    case StreamKpiStyleId.minimal:
      return StreamKpiChrome(
        backgroundColor: hcYellow,
        gradient: null,
        border: Border.all(color: hcWhite, width: 1.5),
        shadows: const [],
        padding: EdgeInsets.symmetric(
          horizontal: tight ? 10 : compact ? 14 : 20,
          vertical: tight ? 8 : compact ? 10 : 16,
        ),
        radius: StreamRadius.lg,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 9 : 11,
          color: hcBlack,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        valueStyle: StreamTypography.amountLarge.copyWith(
          fontSize: tight ? 18 : 26,
          color: hcBlack,
          fontWeight: FontWeight.w800,
        ),
        subtitleStyle: StreamTypography.micro.copyWith(
          fontSize: tight ? 8 : 10,
          color: hcBlack.withValues(alpha: 0.7),
        ),
        valueSpacing: StreamSpacing.xs,
        subtitleSpacing: 6,
        centeredIconSize: 18,
      );
  }
}

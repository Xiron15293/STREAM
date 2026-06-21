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

class StreamKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final StreamKpiSemanticType semanticType;
  final Color? accentColor;
  final StreamKpiLayout layout;
  final StreamKpiDensity density;
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
        final chrome = _resolveChrome(palette, accent, styleId, density);
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
  final _StreamKpiChrome chrome;
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
  final _StreamKpiChrome chrome;
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
  final _StreamKpiChrome chrome;
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

class _StreamKpiChrome {
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

  const _StreamKpiChrome({
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

_StreamKpiChrome _resolveChrome(
  StreamThemePalette palette,
  Color accent,
  StreamKpiStyleId styleId,
  StreamKpiDensity density,
) {
  final baseSurface = StreamSurfaceTokens.card(palette, elevated: true);
  final isHighContrast = palette.isHighContrastTheme;
  final compact = density == StreamKpiDensity.compact;
  final tight = density == StreamKpiDensity.tight;

  final EdgeInsets regularPadding = tight
      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
      : compact
      ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
      : const EdgeInsets.all(StreamSpacing.md);

  final titleStyle = StreamTypography.micro.copyWith(
    fontSize: tight ? 9 : compact ? 10 : 11,
    color: palette.textSecondary,
    letterSpacing: styleId == StreamKpiStyleId.dense ? 0.8 : 0.5,
  );
  final subtitleStyle = StreamTypography.micro.copyWith(
    fontSize: tight ? 8 : 9,
    color: palette.textMuted,
  );

  switch (styleId) {
    case StreamKpiStyleId.dense:
      return _StreamKpiChrome(
        backgroundColor: palette.surfaceElevated,
        gradient: null,
        border: Border.all(color: baseSurface.border, width: baseSurface.borderWidth),
        shadows: isHighContrast ? const [] : const [],
        padding: tight
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
            : compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        radius: StreamRadius.md,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle.copyWith(fontSize: tight ? 8.5 : compact ? 9 : 8.5),
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: tight ? 11 : compact ? 12 : 12,
          height: 1,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: 6,
        subtitleSpacing: 4,
        centeredIconSize: 14,
      );
    case StreamKpiStyleId.glass:
      return _StreamKpiChrome(
        backgroundColor: palette.surfaceElevated.withValues(alpha: 0.72),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: palette.brightness == Brightness.light ? 0.12 : 0.18),
            palette.surface.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: baseSurface.border.withValues(alpha: 0.7),
          width: baseSurface.borderWidth,
        ),
        shadows: baseSurface.shadows,
        padding: regularPadding,
        radius: StreamRadius.lg,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle,
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: tight ? 12 : compact ? 13 : 18,
          height: compact ? 1.1 : 1.05,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: compact ? 4 : StreamSpacing.xs,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );
    case StreamKpiStyleId.outline:
      return _StreamKpiChrome(
        backgroundColor: palette.surface,
        gradient: null,
        border: Border.all(
          color: accent.withValues(alpha: isHighContrast ? 0.95 : 0.42),
          width: isHighContrast ? 1.4 : 1.1,
        ),
        shadows: const [],
        padding: regularPadding,
        radius: StreamRadius.lg,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle,
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: tight ? 12 : compact ? 13 : 18,
          height: compact ? 1.1 : 1.05,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: compact ? 4 : StreamSpacing.xs,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );
    case StreamKpiStyleId.solid:
      return _StreamKpiChrome(
        backgroundColor: accent.withValues(
          alpha: isHighContrast ? 0.24 : palette.brightness == Brightness.light ? 0.14 : 0.18,
        ),
        gradient: null,
        border: null,
        shadows: const [],
        padding: regularPadding,
        radius: StreamRadius.lg,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle,
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: tight ? 12 : compact ? 13 : 18,
          height: compact ? 1.1 : 1.05,
        ),
        subtitleStyle: subtitleStyle.copyWith(
          color: palette.textSecondary.withValues(alpha: 0.9),
        ),
        valueSpacing: compact ? 4 : StreamSpacing.xs,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );
    case StreamKpiStyleId.split:
      return _StreamKpiChrome(
        backgroundColor: palette.surface,
        gradient: null,
        border: Border.all(color: baseSurface.border, width: baseSurface.borderWidth),
        shadows: isHighContrast ? const [] : baseSurface.shadows,
        padding: regularPadding,
        radius: StreamRadius.lg,
        leftAccent: true,
        accentStripeWidth: tight ? 3 : 4,
        accentStripeAlpha: 0.95,
        titleStyle: titleStyle,
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: tight ? 12 : compact ? 13 : 16,
          height: compact ? 1.1 : 1.05,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: compact ? 4 : StreamSpacing.xs,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );
    case StreamKpiStyleId.automatic:
    case StreamKpiStyleId.minimal:
      return _StreamKpiChrome(
        backgroundColor: palette.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: palette.brightness == Brightness.light ? 0.08 : 0.12),
            palette.surface,
          ],
        ),
        border: Border.all(color: baseSurface.border, width: baseSurface.borderWidth),
        shadows: isHighContrast ? const [] : baseSurface.shadows,
        padding: tight
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 7)
            : compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 9)
            : const EdgeInsets.all(StreamSpacing.md),
        radius: StreamRadius.lg,
        leftAccent: false,
        accentStripeWidth: 0,
        accentStripeAlpha: 0,
        titleStyle: titleStyle,
        valueStyle: StreamTypography.captionBold.copyWith(
          fontSize: tight ? 12 : compact ? 13 : 20,
          height: compact ? 1.1 : 1.05,
        ),
        subtitleStyle: subtitleStyle,
        valueSpacing: compact ? 4 : StreamSpacing.sm,
        subtitleSpacing: compact ? 4 : 8,
        centeredIconSize: 15,
      );
  }
}

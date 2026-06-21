import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/design/stream_kpi_style.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/widgets/stream_kpi_card.dart';

void main() {
  test('automatic resolves to theme-recommended styles', () {
    expect(
      resolveEffectiveKpiStyle(
        StreamThemePalette.of(StreamThemeId.streamClassic),
        StreamKpiStyleId.automatic,
      ),
      StreamKpiStyleId.glass,
    );
    expect(
      resolveEffectiveKpiStyle(
        StreamThemePalette.of(StreamThemeId.forest),
        StreamKpiStyleId.automatic,
      ),
      StreamKpiStyleId.glass,
    );
    expect(
      resolveEffectiveKpiStyle(
        StreamThemePalette.of(StreamThemeId.midnight),
        StreamKpiStyleId.automatic,
      ),
      StreamKpiStyleId.outline,
    );
    expect(
      resolveEffectiveKpiStyle(
        StreamThemePalette.of(StreamThemeId.aurora),
        StreamKpiStyleId.automatic,
      ),
      StreamKpiStyleId.split,
    );
    expect(
      resolveEffectiveKpiStyle(
        StreamThemePalette.of(StreamThemeId.minimalSand),
        StreamKpiStyleId.automatic,
      ),
      StreamKpiStyleId.minimal,
    );
    expect(
      resolveEffectiveKpiStyle(
        StreamThemePalette.of(StreamThemeId.highContrast),
        StreamKpiStyleId.automatic,
      ),
      StreamKpiStyleId.solid,
    );
  });

  test('automatic is not always minimal and manual styles bypass mapping', () {
    final aurora = StreamThemePalette.of(StreamThemeId.aurora);
    final midnight = StreamThemePalette.of(StreamThemeId.midnight);

    expect(
      resolveEffectiveKpiStyle(aurora, StreamKpiStyleId.automatic),
      isNot(StreamKpiStyleId.minimal),
    );
    expect(
      resolveEffectiveKpiStyle(midnight, StreamKpiStyleId.automatic),
      StreamKpiStyleId.outline,
    );
    expect(
      resolveEffectiveKpiStyle(aurora, StreamKpiStyleId.minimal),
      StreamKpiStyleId.minimal,
    );
    expect(
      resolveEffectiveKpiStyle(midnight, StreamKpiStyleId.glass),
      StreamKpiStyleId.glass,
    );
  });

  test('automatic chrome can differ meaningfully from minimal chrome', () {
    final aurora = StreamThemePalette.of(StreamThemeId.aurora);
    final automatic = resolveKpiChrome(
      aurora,
      aurora.primary,
      StreamKpiStyleId.automatic,
      StreamKpiDensity.regular,
      StreamKpiEmphasis.normal,
    );
    final minimal = resolveKpiChrome(
      aurora,
      aurora.primary,
      StreamKpiStyleId.minimal,
      StreamKpiDensity.regular,
      StreamKpiEmphasis.normal,
    );

    expect(automatic.leftAccent, isTrue);
    expect(minimal.leftAccent, isFalse);
    expect(automatic.border, isNotNull);
    expect(minimal.border, isNotNull);
    expect(automatic.accentStripeWidth, greaterThan(minimal.accentStripeWidth));
  });
}

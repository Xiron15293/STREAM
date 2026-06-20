import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/screens/settings_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.themeIdNotifier.value = StreamThemeId.streamClassic.name;
    PreferencesService.kpiStyleNotifier.value = 'dense';
    PreferencesService.chartStyleNotifier.value = 'technical';
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
  });

  Future<void> pumpSettings(
    WidgetTester tester,
    StreamThemeId themeId, {
    Size size = const Size(390, 844),
  }) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: SettingsScreen(db: AppDatabase(), onManageProfiles: () {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  BoxDecoration sectionDecorationByTitle(WidgetTester tester, String title) {
    final titleFinder = find.text(title, skipOffstage: false).first;
    final ancestors = find.ancestor(
      of: titleFinder,
      matching: find.byType(DecoratedBox, skipOffstage: false),
    );

    for (final element in ancestors.evaluate()) {
      final widget = element.widget;
      if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
        final decoration = widget.decoration as BoxDecoration;
        if (decoration.color != null) return decoration;
      }
    }

    throw StateError('No section decoration found for $title');
  }

  Text tileText(WidgetTester tester, String label) {
    return tester.widget<Text>(find.text(label, skipOffstage: false).last);
  }

  AnimatedContainer tileContainerByTitle(WidgetTester tester, String title) {
    final tileFinder = find.text(title, skipOffstage: false).last;
    return tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: tileFinder,
            matching: find.byType(AnimatedContainer, skipOffstage: false),
          )
          .first,
    );
  }

  Future<void> revealText(WidgetTester tester, String title) async {
    final finder = find.text(title, skipOffstage: false);
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTile(WidgetTester tester, String title) async {
    await revealText(tester, title);
    await tester.tap(find.text(title, skipOffstage: false).last);
    await tester.pumpAndSettle();
  }

  group('SettingsScreen theme visibility', () {
    testWidgets('changes background with Forest theme', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.forest);
      await pumpSettings(tester, StreamThemeId.forest);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, palette.canvas);
    });

    testWidgets('changes background with Minimal Sand theme', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.minimalSand);
      await pumpSettings(tester, StreamThemeId.minimalSand);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, palette.canvas);
    });

    testWidgets('changes background with High Contrast theme', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.highContrast);
      await pumpSettings(tester, StreamThemeId.highContrast);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, palette.canvas);
    });

    testWidgets('section cards use theme surface and divider', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.forest);
      await pumpSettings(tester, StreamThemeId.forest);

      const sectionTitles = [
        'Gestisci esportazione e ripristino dei dati del dispositivo.',
        'Configura soglie e colori della heatmap Movimenti.',
        'Scegli il simbolo usato per mostrare gli importi.',
        'Personalizza l\'interfaccia dell\'app.',
        'Gestisci il profilo attivo e le configurazioni collegate.',
        'Personalizza il modello visuale della schermata categorie.',
        'Azioni distruttive e manutenzione dei dati locali.',
      ];

      for (final title in sectionTitles) {
        await revealText(tester, title);
        final decoration = sectionDecorationByTitle(tester, title);
        expect(decoration.color, palette.surface);
        expect((decoration.border! as Border).top.color, palette.divider);
      }
    });

    testWidgets('main settings tiles use theme text colors', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.minimalSand);
      await pumpSettings(tester, StreamThemeId.minimalSand);
      await revealText(tester, 'Modello categoria');
      await revealText(tester, 'Reset dati app');

      final categoryTitle = tileText(tester, 'Modello categoria');
      final resetTitle = tileText(tester, 'Reset dati app');
      final resetSubtitle = tileText(
        tester,
        'Cancella dati utente e ripristina i default',
      );

      expect(categoryTitle.style?.color, palette.textPrimary);
      expect(resetTitle.style?.color, palette.textPrimary);
      expect(resetSubtitle.style?.color, palette.textSecondary);
    });

    testWidgets('backup tile uses theme colors', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.forest);
      await pumpSettings(tester, StreamThemeId.forest);

      final title = tileText(tester, 'Backup & Restore');
      final subtitle = tileText(
        tester,
        'Apri la schermata di esportazione e ripristino',
      );

      expect(title.style?.color, palette.textPrimary);
      expect(subtitle.style?.color, palette.textSecondary);
    });

    testWidgets('restore and danger tile use theme colors', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.highContrast);
      await pumpSettings(tester, StreamThemeId.highContrast);
      await revealText(tester, 'Reset dati app');

      final resetTitle = tileText(tester, 'Reset dati app');
      final resetSubtitle = tileText(
        tester,
        'Cancella dati utente e ripristina i default',
      );
      final resetContainer = tileContainerByTitle(tester, 'Reset dati app');
      final decoration = resetContainer.decoration as BoxDecoration;

      expect(resetTitle.style?.color, palette.textPrimary);
      expect(resetSubtitle.style?.color, palette.textSecondary);
      expect(decoration.color, palette.expense.withValues(alpha: 0.12));
      expect((decoration.border! as Border).top.color, isNot(palette.divider));
    });

    testWidgets('appearance section uses theme colors', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.aurora);
      await pumpSettings(tester, StreamThemeId.aurora);
      await revealText(tester, 'Aspetto');

      final decoration = sectionDecorationByTitle(
        tester,
        'Personalizza l\'interfaccia dell\'app.',
      );
      final themeTitle = tileText(tester, 'Tema app');
      final kpiTitle = tileText(tester, 'Stile KPI');
      final chartsTitle = tileText(tester, 'Stile grafici');

      expect(decoration.color, palette.surface);
      expect(themeTitle.style?.color, palette.textPrimary);
      expect(kpiTitle.style?.color, palette.textPrimary);
      expect(chartsTitle.style?.color, palette.textPrimary);
    });

    testWidgets('theme app picker uses theme colors', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.forest);
      PreferencesService.themeIdNotifier.value = StreamThemeId.forest.name;
      await pumpSettings(tester, StreamThemeId.forest);
      await openTile(tester, 'Tema app');

      final sheet = tester.widget<Container>(
        find.byKey(const Key('picker_sheet_tema_app')),
      );
      final decoration = sheet.decoration as BoxDecoration;
      final title = tileText(tester, 'Tema app');
      final selectedTitle = tileText(tester, 'Forest');

      expect(decoration.color, palette.surface);
      expect(title.style?.color, palette.textPrimary);
      expect(selectedTitle.style?.color, palette.primary);
    });

    testWidgets('KPI picker uses theme colors', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.minimalSand);
      await pumpSettings(tester, StreamThemeId.minimalSand);
      await openTile(tester, 'Stile KPI');

      final sheet = tester.widget<Container>(
        find.byKey(const Key('picker_sheet_stile_kpi')),
      );
      final decoration = sheet.decoration as BoxDecoration;
      final selectedTitle = tileText(tester, 'Dense');

      expect(decoration.color, palette.surface);
      expect(selectedTitle.style?.color, palette.primary);
    });

    testWidgets('chart picker uses theme colors', (tester) async {
      final palette = StreamThemePalette.of(StreamThemeId.highContrast);
      await pumpSettings(tester, StreamThemeId.highContrast);
      await openTile(tester, 'Stile grafici');

      final sheet = tester.widget<Container>(
        find.byKey(const Key('picker_sheet_stile_grafici')),
      );
      final decoration = sheet.decoration as BoxDecoration;
      final selectedTitle = tileText(tester, 'Tecnico');

      expect(decoration.color, palette.surface);
      expect(selectedTitle.style?.color, palette.primary);
    });

    testWidgets('Minimal Sand keeps text visible against background', (
      tester,
    ) async {
      final palette = StreamThemePalette.of(StreamThemeId.minimalSand);
      await pumpSettings(tester, StreamThemeId.minimalSand);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      final background = scaffold.backgroundColor;
      final title = tileText(tester, 'Valuta');
      final subtitle = tileText(tester, 'EUR €');

      expect(title.style?.color, palette.textPrimary);
      expect(subtitle.style?.color, palette.textSecondary);
      expect(title.style?.color, isNot(background));
      expect(subtitle.style?.color, isNot(background));
    });

    testWidgets('High Contrast keeps text visible against background', (
      tester,
    ) async {
      final palette = StreamThemePalette.of(StreamThemeId.highContrast);
      await pumpSettings(tester, StreamThemeId.highContrast);
      await revealText(tester, 'Tema app');

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      final background = scaffold.backgroundColor;
      final title = tileText(tester, 'Tema app');
      final subtitle = tileText(tester, 'Stream Classic');

      expect(title.style?.color, palette.textPrimary);
      expect(subtitle.style?.color, palette.textSecondary);
      expect(title.style?.color, isNot(background));
      expect(subtitle.style?.color, isNot(background));
    });

    testWidgets('small viewport does not overflow', (tester) async {
      await pumpSettings(
        tester,
        StreamThemeId.minimalSand,
        size: const Size(320, 480),
      );

      await openTile(tester, 'Tema app');
      await tester.tap(find.text('Stream Classic', skipOffstage: false).last);
      await tester.pumpAndSettle();

      await revealText(tester, 'Reset dati app');
      await tester.tap(find.text('Reset dati app', skipOffstage: false).last);
      await tester.pumpAndSettle();

      expect(find.text('Reset dati app?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

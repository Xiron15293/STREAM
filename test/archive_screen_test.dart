import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/screens/accounts_screen.dart';
import 'package:stream_app/screens/beneficiaries_screen.dart';
import 'package:stream_app/screens/categories_screen.dart';
import 'package:stream_app/screens/movements_screen.dart';

ThemeData _testTheme() => ThemeData(useMaterial3: true).copyWith(
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'movements_view_mode': 'listHeatmap',
    });
  });

  testWidgets('ArchiveScreen mostra Movimenti Conti Categorie Beneficiari', (
    tester,
  ) async {
    final db = AppDatabase();
    await tester.pumpWidget(MaterialApp(theme: _testTheme(), home: MainScaffold(db: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bottom_nav_archive')).hitTestable());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('archive_section_movements')), findsOneWidget);
    expect(find.byKey(const Key('archive_section_accounts')), findsOneWidget);
    expect(find.byKey(const Key('archive_section_categories')), findsOneWidget);
    expect(
      find.byKey(const Key('archive_section_beneficiaries')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('archive_section_calendar')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SegmentedButton<int>),
        matching: find.text('Calendario'),
      ),
      findsNothing,
    );

    final segmentedButton = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(segmentedButton.segments.length, 4);

    expect(find.byType(MovementsScreen), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('archive_section_accounts')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AccountsScreen), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('archive_section_categories')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesScreen), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('archive_section_movements')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MovementsScreen), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('archive_section_beneficiaries')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BeneficiariesScreen), findsOneWidget);
  });
}

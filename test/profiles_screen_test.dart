import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/models/profile.dart';
import 'package:stream_app/screens/profiles_screen.dart';
import 'package:stream_app/screens/settings_screen.dart';
import 'package:stream_app/services/profiles_controller.dart';
import 'package:stream_app/theme.dart';

class FakeProfilesController implements ProfilesController {
  FakeProfilesController() {
    _profiles.add(
      Profile(
        id: 'main',
        name: 'Principale',
        dbFileName: 'stream.db',
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      ),
    );
    _activeId = 'main';
  }

  final List<Profile> _profiles = [];
  String? _activeId;

  @override
  List<Profile> get profiles => List.unmodifiable(_profiles);

  @override
  Profile? get activeProfile =>
      _profiles.firstWhereOrNull((p) => p.id == _activeId);

  @override
  String? get activeProfileId => _activeId;

  @override
  Future<Profile> createProfile(String name) async {
    final id = 'profile_${_profiles.length}';
    final profile = Profile(
      id: id,
      name: name,
      dbFileName: 'stream_profile_$id.db',
      createdAt: DateTime(2026, 6, 2),
      updatedAt: DateTime(2026, 6, 2),
    );
    _profiles.add(profile);
    return profile;
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((p) => p.id == profileId);
    if (_activeId == profileId) _activeId = 'main';
  }

  @override
  Future<String> getDatabasePath(Profile profile) async {
    return '/fake/${profile.dbFileName}';
  }

  @override
  Future<List<Profile>> loadProfiles() async => profiles;

  @override
  Future<void> renameProfile(String profileId, String name) async {
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index >= 0) {
      _profiles[index] = _profiles[index].copyWith(name: name);
    }
  }

  @override
  Future<void> switchProfile(String profileId) async {
    _activeId = profileId;
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: StreamTheme.dark,
      home: child,
    );
  }

  testWidgets('settings hides profile section without callback', (tester) async {
    await tester.pumpWidget(
      wrap(SettingsScreen(db: AppDatabase())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_profile_section')), findsNothing);
  });

  testWidgets('settings opens ProfilesScreen with real callback', (tester) async {
    final controller = FakeProfilesController();

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => SettingsScreen(
            db: AppDatabase(),
            onManageProfiles: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfilesScreen(
                    profileService: controller,
                    activeProfileId: controller.activeProfileId,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_active_profile_tile')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_active_profile_tile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profiles_screen')), findsOneWidget);
    expect(find.byKey(const Key('profiles_profile_item_main')), findsOneWidget);
  });

  testWidgets('profiles screen can create and show a new profile', (tester) async {
    final controller = FakeProfilesController();

    await tester.pumpWidget(
      wrap(
        ProfilesScreen(
          profileService: controller,
          activeProfileId: controller.activeProfileId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profiles_create_profile')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile_create_name_field')),
      'Profilo Test B',
    );
    await tester.tap(find.byKey(const Key('profile_create_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Profilo creato'), findsOneWidget);
    await tester.tap(find.text('Resta qui'));
    await tester.pumpAndSettle();

    expect(find.text('Profilo Test B'), findsOneWidget);
  });
}

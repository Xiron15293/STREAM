import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/sqlite_service.dart';
import '../models/profile.dart';
import 'profiles_controller.dart';

class ProfileService implements ProfilesController {
  ProfileService({this.testBasePath});

  static const _registryFileName = 'profiles.json';

  final String? testBasePath;

  List<Profile> _profiles = const [];
  Profile? _activeProfile;
  bool _initialized = false;

  @override
  List<Profile> get profiles => List.unmodifiable(_profiles);

  @override
  Profile? get activeProfile => _activeProfile;

  @override
  String? get activeProfileId => _activeProfile?.id;

  Future<void> initialize() async {
    if (_initialized) return;
    await loadProfiles();
    _initialized = true;
  }

  @override
  Future<List<Profile>> loadProfiles() async {
    final registry = await _loadRegistry();
    var loadedProfiles = registry.profiles;
    if (loadedProfiles.isEmpty) {
      loadedProfiles = [Profile.main()];
    }

    final healed = _healProfiles(loadedProfiles);
    final activeId = _resolveActiveProfileId(
      requestedId: registry.activeProfileId,
      profiles: healed,
    );

    _profiles = healed;
    _activeProfile = healed.firstWhere((p) => p.id == activeId);
    await _saveRegistry();
    return profiles;
  }

  @override
  Future<Profile> createProfile(String name) async {
    await initialize();

    final cleanedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanedName.isEmpty) {
      throw StateError('Il nome profilo non può essere vuoto');
    }

    final now = DateTime.now();
    final id = 'p_${now.microsecondsSinceEpoch}';
    final profile = Profile(
      id: id,
      name: cleanedName,
      dbFileName: Profile.defaultDbFileNameFor(id),
      createdAt: now,
      updatedAt: now,
    );

    final dbPath = await getDatabasePath(profile);
    final sqlite = SQLiteService();
    await sqlite.open(path: dbPath);
    await sqlite.close();

    _profiles = [..._profiles, profile];
    await _saveRegistry();
    return profile;
  }

  @override
  Future<void> switchProfile(String profileId) async {
    await initialize();
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index < 0) throw StateError('Profilo $profileId non trovato');
    _activeProfile = _profiles[index];
    await _saveRegistry();
  }

  @override
  Future<void> renameProfile(String profileId, String name) async {
    await initialize();

    final cleanedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanedName.isEmpty) {
      throw StateError('Il nome profilo non può essere vuoto');
    }

    _profiles = _profiles.map((profile) {
      if (profile.id != profileId) return profile;
      return profile.copyWith(
        name: cleanedName,
        updatedAt: DateTime.now(),
      );
    }).toList(growable: false);

    _activeProfile = _profiles.where((p) => p.id == activeProfileId).firstOrNull;
    await _saveRegistry();
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    await initialize();
    if (profileId == 'main') {
      throw StateError('Il profilo principale non può essere eliminato');
    }

    final profile = _profiles.where((p) => p.id == profileId).firstOrNull;
    if (profile == null) throw StateError('Profilo $profileId non trovato');

    final remaining = _profiles.where((p) => p.id != profileId).toList(growable: false);
    if (remaining.isEmpty) {
      throw StateError('Deve esistere almeno un profilo');
    }

    final dbPath = await getDatabasePath(profile);
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    _profiles = _healProfiles(remaining);
    final nextActiveId = activeProfileId == profileId
        ? _resolveActiveProfileId(requestedId: null, profiles: _profiles)
        : _resolveActiveProfileId(requestedId: activeProfileId, profiles: _profiles);
    _activeProfile = _profiles.firstWhere((p) => p.id == nextActiveId);
    await _saveRegistry();
  }

  @override
  Future<String> getDatabasePath(Profile profile) async {
    final dir = await _baseDir();
    await Directory(dir).create(recursive: true);
    return p.join(dir, profile.dbFileName);
  }

  Future<String> _baseDir() async {
    return testBasePath ?? await getDatabasesPath();
  }

  Future<String> _registryPath() async {
    return p.join(await _baseDir(), _registryFileName);
  }

  List<Profile> _healProfiles(List<Profile> profiles) {
    final usedNames = <String>{};
    final healed = <Profile>[];

    final sorted = [...profiles]..sort((a, b) {
      if (a.isMain && !b.isMain) return -1;
      if (!a.isMain && b.isMain) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });

    for (final profile in sorted) {
      final expected = Profile.defaultDbFileNameFor(profile.id);
      var dbFileName = profile.isMain ? 'stream.db' : profile.dbFileName;

      final invalidForSecondary =
          !profile.isMain &&
          (dbFileName.trim().isEmpty ||
              dbFileName == 'stream.db' ||
              usedNames.contains(dbFileName));

      if (profile.isMain) {
        dbFileName = 'stream.db';
      } else if (invalidForSecondary) {
        dbFileName = expected;
        if (usedNames.contains(dbFileName)) {
          dbFileName =
              'stream_profile_${profile.id}_${healed.length}.db';
        }
      }

      usedNames.add(dbFileName);
      healed.add(profile.copyWith(dbFileName: dbFileName));
    }

    if (!healed.any((p) => p.isMain)) {
      final main = Profile.main();
      return [main, ...healed];
    }

    return healed;
  }

  String _resolveActiveProfileId({
    required String? requestedId,
    required List<Profile> profiles,
  }) {
    if (requestedId != null && profiles.any((p) => p.id == requestedId)) {
      return requestedId;
    }
    final main = profiles.where((p) => p.isMain).firstOrNull;
    return (main ?? profiles.first).id;
  }

  Future<_ProfilesRegistry> _loadRegistry() async {
    final file = File(await _registryPath());
    if (!await file.exists()) {
      return const _ProfilesRegistry(profiles: [], activeProfileId: null);
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return const _ProfilesRegistry(profiles: [], activeProfileId: null);
      }

      final rawProfiles = decoded['profiles'];
      final profiles = rawProfiles is List
          ? rawProfiles
                .whereType<Map>()
                .map((p) => Profile.fromJson(Map<String, dynamic>.from(p)))
                .toList(growable: false)
          : const <Profile>[];
      final activeProfileId = decoded['activeProfileId'] as String?;

      return _ProfilesRegistry(
        profiles: profiles,
        activeProfileId: activeProfileId,
      );
    } catch (_) {
      return const _ProfilesRegistry(profiles: [], activeProfileId: null);
    }
  }

  Future<void> _saveRegistry() async {
    final file = File(await _registryPath());
    final payload = jsonEncode({
      'activeProfileId': activeProfileId,
      'profiles': _profiles.map((p) => p.toJson()).toList(),
    });
    await file.writeAsString(payload);
  }
}

class _ProfilesRegistry {
  final List<Profile> profiles;
  final String? activeProfileId;

  const _ProfilesRegistry({
    required this.profiles,
    required this.activeProfileId,
  });
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

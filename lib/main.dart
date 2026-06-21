import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/database.dart';
import 'data/sqlite_service.dart';
import 'design/stream_kpi_style.dart';
import 'design/stream_theme_palette.dart';
import 'models/profile.dart';
import 'screens/charts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/profiles_screen.dart';
import 'screens/settings_screen.dart';
import 'data/preferences_service.dart';
import 'services/profile_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final profileService = ProfileService();
  await profileService.initialize();
  await PreferencesService.loadCurrency();
  await PreferencesService.loadThemeId();
  await PreferencesService.loadKpiStyleId();
  await PreferencesService.loadChartStyleId();
  await PreferencesService.loadHiddenChartIds();
  runApp(ProfileAwareStreamApp(profileService: profileService));
}

class StreamApp extends StatefulWidget {
  final AppDatabase db;
  final Widget? home;

  const StreamApp({super.key, required this.db, this.home});

  @override
  State<StreamApp> createState() => _StreamAppState();
}

class _StreamAppState extends State<StreamApp> {
  late ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _rebuildTheme();
    PreferencesService.themeIdNotifier.addListener(_onPreferenceChanged);
    PreferencesService.chartStyleNotifier.addListener(_onPreferenceChanged);
  }

  @override
  void dispose() {
    PreferencesService.themeIdNotifier.removeListener(_onPreferenceChanged);
    PreferencesService.chartStyleNotifier.removeListener(_onPreferenceChanged);
    super.dispose();
  }

  void _onPreferenceChanged() {
    _rebuildTheme();
  }

  void _rebuildTheme() {
    setState(() {
      _theme = StreamTheme.build(
        StreamThemePalette.of(
          StreamThemeId.fromString(PreferencesService.themeIdNotifier.value),
        ),
        chartStyle: StreamChartStyleId.fromString(
          PreferencesService.chartStyleNotifier.value,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STREAM',
      theme: _theme,
      debugShowCheckedModeBanner: false,
      home: widget.home ?? MainScaffold(db: widget.db),
    );
  }
}

class ProfileAwareStreamApp extends StatefulWidget {
  final ProfileService profileService;

  const ProfileAwareStreamApp({super.key, required this.profileService});

  @override
  State<ProfileAwareStreamApp> createState() => _ProfileAwareStreamAppState();
}

class _ProfileAwareStreamAppState extends State<ProfileAwareStreamApp> {
  AppDatabase? _db;
  Profile? _activeProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveProfileDb();
  }

  @override
  void dispose() {
    _closeCurrentDb();
    super.dispose();
  }

  Future<void> _loadActiveProfileDb() async {
    final profile =
        widget.profileService.activeProfile ??
        (await widget.profileService.loadProfiles()).first;
    await _switchToProfile(profile.id, initialLoad: true);
  }

  Future<void> _closeCurrentDb() async {
    await _db?.sqliteService?.close();
  }

  Future<void> _switchToProfile(
    String profileId, {
    bool initialLoad = false,
  }) async {
    if (!initialLoad) {
      await widget.profileService.switchProfile(profileId);
    }
    final profile = widget.profileService.profiles.firstWhere(
      (p) => p.id == profileId,
    );
    final dbPath = await widget.profileService.getDatabasePath(profile);
    final sqlite = SQLiteService();
    await sqlite.open(path: dbPath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    final oldDb = _db;
    setState(() {
      _activeProfile = profile;
      _db = db;
      _loading = false;
    });
    await oldDb?.sqliteService?.close();
  }

  void _openProfiles(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilesScreen(
          profileService: widget.profileService,
          activeProfileId: widget.profileService.activeProfileId,
          onProfileSelected: (profile) {
            _switchToProfile(profile.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _db == null || _activeProfile == null) {
      return MaterialApp(
        title: 'STREAM',
        theme: StreamTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return StreamApp(
      db: _db!,
      home: Builder(
        builder: (context) => MainScaffold(
          key: ValueKey('main_scaffold_${_activeProfile!.id}'),
          db: _db!,
          activeProfileId: _activeProfile!.id,
          onManageProfiles: () => _openProfiles(context),
        ),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final AppDatabase db;
  final VoidCallback? onManageProfiles;
  final String? activeProfileId;

  const MainScaffold({
    super.key,
    required this.db,
    this.onManageProfiles,
    this.activeProfileId,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(db: widget.db, activeProfileId: widget.activeProfileId),
      ArchiveScreen(db: widget.db),
      ChartsScreen(db: widget.db),
      SettingsScreen(db: widget.db, onManageProfiles: widget.onManageProfiles),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: StreamColors.divider, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            BottomNavigationBarItem(
              icon: KeyedSubtree(
                key: Key('bottom_nav_dashboard'),
                child: Icon(Icons.dashboard),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: KeyedSubtree(
                key: Key('bottom_nav_archive'),
                child: Icon(Icons.folder),
              ),
              label: 'Archivio',
            ),
            BottomNavigationBarItem(
              icon: KeyedSubtree(
                key: Key('bottom_nav_charts'),
                child: Icon(Icons.bar_chart),
              ),
              label: 'Grafici',
            ),
            BottomNavigationBarItem(
              icon: KeyedSubtree(
                key: Key('bottom_nav_settings'),
                child: Icon(Icons.settings),
              ),
              label: 'Impostazioni',
            ),
          ],
        ),
      ),
    );
  }
}

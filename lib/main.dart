import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/database.dart';
import 'data/sqlite_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final sqlite = SQLiteService();
  await sqlite.open();
  final db = AppDatabase(sqlite: sqlite);
  await db.initialize();
  runApp(StreamApp(db: db));
}

class StreamApp extends StatelessWidget {
  final AppDatabase db;

  const StreamApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STREAM',
      theme: StreamTheme.dark,
      debugShowCheckedModeBanner: false,
      home: MainScaffold(db: db),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final AppDatabase db;

  const MainScaffold({super.key, required this.db});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final AppDatabase _db = widget.db;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(db: _db),
      ArchiveScreen(db: _db),
      SettingsScreen(db: _db),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: StreamColors.divider, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
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

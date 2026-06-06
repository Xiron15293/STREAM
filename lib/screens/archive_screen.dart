import 'package:flutter/material.dart';
import '../data/database.dart';
import 'movements_screen.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';

class ArchiveScreen extends StatefulWidget {
  final AppDatabase db;

  const ArchiveScreen({super.key, required this.db});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  int _selectedSection = 0;

  static const _sections = ['Movimenti', 'Conti', 'Categorie'];
  static const _icons = [
    Icons.swap_vert,
    Icons.account_balance,
    Icons.category,
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      MovementsScreen(db: widget.db),
      AccountsScreen(db: widget.db),
      CategoriesScreen(db: widget.db),
    ];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: List.generate(3, (i) {
                  return ButtonSegment<int>(
                    value: i,
                    label: Text(_sections[i]),
                    icon: Icon(_icons[i], size: 18),
                  );
                }),
                selected: {_selectedSection},
                onSelectionChanged: (Set<int> v) {
                  setState(() => _selectedSection = v.first);
                },
                showSelectedIcon: false,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: IndexedStack(
              index: _selectedSection,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }
}

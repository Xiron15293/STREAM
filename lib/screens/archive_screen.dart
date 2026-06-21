import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_theme_extension.dart';
import 'movements_screen.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'beneficiaries_screen.dart';

class ArchiveScreen extends StatefulWidget {
  final AppDatabase db;

  const ArchiveScreen({super.key, required this.db});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  int _selectedSection = 0;

  static const _sections = [
    'Movimenti',
    'Conti',
    'Categorie',
    'Benefic.',
  ]; // shortened to fit in one line
  static const _icons = [
    Icons.swap_vert,
    Icons.account_balance,
    Icons.category,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return SafeArea(
      child: Container(
        color: p.canvas,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: List.generate(_sections.length, (i) {
                    return ButtonSegment<int>(
                      value: i,
                      label: KeyedSubtree(
                        key: i == 0
                            ? const Key('archive_section_movements')
                            : i == 1
                            ? const Key('archive_section_accounts')
                            : i == 2
                            ? const Key('archive_section_categories')
                            : const Key('archive_section_beneficiaries'),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_icons[i], size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _sections[i],
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                      ),
                      icon: const SizedBox.shrink(),
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
                children: [
                  MovementsScreen(
                    key: const Key('archive_movements_screen'),
                    db: widget.db,
                  ),
                  AccountsScreen(
                    key: const Key('archive_accounts_screen'),
                    db: widget.db,
                  ),
                  CategoriesScreen(
                    key: const Key('archive_categories_screen'),
                    db: widget.db,
                  ),
                  BeneficiariesScreen(
                    key: const Key('archive_beneficiaries_screen'),
                    db: widget.db,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_icon_library.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../widgets/grouped_movements_list.dart';
import '../widgets/icon_picker.dart';
import '../widgets/time_filter_bar.dart';

class CategoriesScreen extends StatefulWidget {
  final AppDatabase db;

  const CategoriesScreen({super.key, required this.db});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  MovementType _selectedType = MovementType.expense;
  String _layoutMode = PreferencesService.defaultCategoryLayout;

  @override
  void initState() {
    super.initState();
    _loadLayoutMode();
    PreferencesService.categoryLayoutNotifier.addListener(_onLayoutChanged);
  }

  @override
  void dispose() {
    PreferencesService.categoryLayoutNotifier.removeListener(_onLayoutChanged);
    super.dispose();
  }

  void _onLayoutChanged() {
    if (mounted) {
      setState(() => _layoutMode = PreferencesService.categoryLayoutNotifier.value);
    }
  }

  Future<void> _loadLayoutMode() async {
    final mode = await PreferencesService.loadCategoryLayout();
    if (mounted) {
      setState(() => _layoutMode = mode);
    }
  }

  void _showAddDialog() {
    _showCategoryForm(context, db: widget.db, preferredType: _selectedType);
  }

  double _computeTypeTotal() {
    return widget.db.movements
        .where((m) => m.type == _selectedType)
        .fold<double>(0.0, (sum, m) => sum + m.amount);
  }

  String _formatMoney(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)} €';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorie')),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          final all = widget.db.categories;
          final filtered =
              all.where((c) => c.type == _selectedType && !c.archived).toList();
          final archivedList =
              all.where((c) => c.archived && c.type == _selectedType).toList();
          final total = _computeTypeTotal();

          return Column(
            children: [
              Padding(
                key: const Key('categories_type_filter'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SegmentedButton<MovementType>(
                  segments: const [
                    ButtonSegment(
                      value: MovementType.expense,
                      label: KeyedSubtree(
                        key: Key('categories_filter_expense'),
                        child: Text('Uscite'),
                      ),
                    ),
                    ButtonSegment(
                      value: MovementType.income,
                      label: KeyedSubtree(
                        key: Key('categories_filter_income'),
                        child: Text('Entrate'),
                      ),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<MovementType> v) {
                    setState(() => _selectedType = v.first);
                  },
                  showSelectedIcon: false,
                ),
              ),
              _buildTypeSummaryCard(total, filtered.length, archivedList.length),
              const SizedBox(height: 4),
              Expanded(child: _buildLayout(filtered, archivedList)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('categories_fab'),
        heroTag: 'categories_fab',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTypeSummaryCard(double total, int activeCount, int archivedCount) {
    final isIncome = _selectedType == MovementType.income;
    final typeColor = isIncome ? StreamColors.income : StreamColors.expense;
    final typeLabel = isIncome ? 'Entrate' : 'Uscite';

    return Padding(
      key: const Key('categories_type_summary_card'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: StreamColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    key: const Key('categories_summary_title'),
                    style: StreamTypography.captionBold.copyWith(
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatMoney(total),
                    style: StreamTypography.amount.copyWith(color: typeColor),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                  Text(
                    '$activeCount ${activeCount == 1 ? 'attiva' : 'attive'}',
                    key: const Key('categories_summary_active_count'),
                    style: StreamTypography.caption.copyWith(
                      color: StreamColors.textSecondary,
                    ),
                  ),
                if (archivedCount > 0)
                    Text(
                      '$archivedCount ${archivedCount == 1 ? 'archiviata' : 'archiviate'}',
                      key: const Key('categories_summary_archived_count'),
                      style: StreamTypography.micro.copyWith(
                        color: StreamColors.textMuted,
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(List<Category> active, List<Category> archived) {
    switch (_layoutMode) {
      case 'groupedList':
        return _buildGroupedList(active, archived);
      case 'streamCards':
        return _buildStreamCards(active, archived);
      default:
        return _buildCleanList(active, archived);
    }
  }

  Widget _buildCleanList(List<Category> active, List<Category> archived) {
    return ListView(
      key: const Key('categories_layout_clean_list'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        ...active.map((c) => _CleanListTile(
              key: Key('category_card_${c.id}'),
              category: c,
              db: widget.db,
              onTap: () => _showCategoryMovements(context, widget.db, c),
              onEdit: () => _showCategoryForm(context, db: widget.db, existing: c),
              onChanged: () => setState(() {}),
            )),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 12),
          KeyedSubtree(
            key: const Key('categories_archived_section'),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Archiviate (${archived.length})',
                style: StreamTypography.captionBold.copyWith(
                  color: StreamColors.textSecondary,
                ),
              ),
            ),
          ),
          ...archived.map((c) => _CleanListTile(
                key: Key('category_card_${c.id}'),
                category: c,
                db: widget.db,
                onTap: () => _showCategoryMovements(context, widget.db, c),
                onEdit: () => _showCategoryForm(context, db: widget.db, existing: c),
                onChanged: () => setState(() {}),
              )),
        ],
        if (active.isEmpty && archived.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'Nessuna categoria',
                style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupedList(List<Category> active, List<Category> archived) {
    final sorted = List<Category>.from(active)
      ..sort((a, b) {
        final countA = widget.db.movements.where((m) => m.categoryId == a.id).length;
        final countB = widget.db.movements.where((m) => m.categoryId == b.id).length;
        return countB.compareTo(countA);
      });
    final topCount = math.min(3, sorted.length);
    final top = sorted.take(topCount).toList();
    final rest = sorted.skip(topCount).toList();

    return ListView(
      key: const Key('categories_layout_grouped_list'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (top.isNotEmpty)
          KeyedSubtree(
            key: const Key('categories_top_group'),
            child: Container(
              decoration: BoxDecoration(
                color: StreamColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(
                      _selectedType == MovementType.income
                          ? 'TOP ENTRATE'
                          : 'TOP USCITE',
                      style: StreamTypography.captionBold.copyWith(
                        color: StreamColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ...List.generate(top.length, (i) {
                    final c = top[i];
                    return Column(
                      children: [
                        const Divider(height: 0, indent: 56, thickness: 0.5),
                        _GroupedListTile(
                          key: Key('category_card_${c.id}'),
                          category: c,
                          db: widget.db,
                          onTap: () =>
                              _showCategoryMovements(context, widget.db, c),
                          onEdit: () =>
                              _showCategoryForm(context, db: widget.db, existing: c),
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildExpandableSection(
            keyValue: 'categories_active_group',
            title: 'Tutte le categorie',
            count: rest.length,
            items: rest,
          ),
        ],
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildExpandableSection(
            keyValue: 'categories_archived_group',
            title: 'Archiviate',
            count: archived.length,
            items: archived,
          ),
        ],
        if (active.isEmpty && archived.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'Nessuna categoria',
                style: StreamTypography.body.copyWith(
                    color: StreamColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String keyValue,
    required String title,
    required int count,
    required List<Category> items,
  }) {
    return KeyedSubtree(
      key: Key(keyValue),
      child: Material(
        color: StreamColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        type: MaterialType.card,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            '$title ($count)',
            style: StreamTypography.captionBold.copyWith(
              color: StreamColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          children: List.generate(items.length, (i) {
            final c = items[i];
            return Column(
              children: [
                const Divider(height: 0, indent: 56, thickness: 0.5),
                _GroupedListTile(
                  key: Key('category_card_${c.id}'),
                  category: c,
                  db: widget.db,
                  onTap: () =>
                      _showCategoryMovements(context, widget.db, c),
                  onEdit: () =>
                      _showCategoryForm(context, db: widget.db, existing: c),
                  onChanged: () => setState(() {}),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStreamCards(List<Category> active, List<Category> archived) {
    return CustomScrollView(
      key: const Key('categories_layout_stream_cards'),
      slivers: [
        if (active.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, archived.isEmpty ? 80 : 0),
            sliver: SliverGrid(
              key: const Key('categories_stream_card_grid'),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = active[index];
                  final movCount = widget.db.movements
                      .where((m) => m.categoryId == c.id)
                      .length;
                  final total = widget.db.movements
                      .where((m) => m.categoryId == c.id)
                      .fold<double>(0.0, (sum, m) => sum + m.amount);
                  return KeyedSubtree(
                    key: const Key('categories_stream_category_card'),
                    child: _StreamCardGridTile(
                      key: Key('category_card_${c.id}'),
                      category: c,
                      movementCount: movCount,
                      totalAmount: total,
                      db: widget.db,
                      onTap: () =>
                          _showCategoryMovements(context, widget.db, c),
                      onEdit: () => _showCategoryForm(
                          context, db: widget.db, existing: c),
                      onChanged: () => setState(() {}),
                    ),
                  );
                },
                childCount: active.length,
              ),
            ),
          ),
        if (archived.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: const Key('categories_archived_section'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Archiviate (${archived.length})',
                  style: StreamTypography.captionBold.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = archived[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GroupedListTile(
                      key: Key('category_card_${c.id}'),
                      category: c,
                      db: widget.db,
                      onTap: () => _showCategoryMovements(
                          context, widget.db, c),
                      onEdit: () => _showCategoryForm(
                          context, db: widget.db, existing: c),
                      onChanged: () => setState(() {}),
                    ),
                  );
                },
                childCount: archived.length,
              ),
            ),
          ),
        ],
        if (active.isEmpty && archived.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Nessuna categoria',
                  style: StreamTypography.body.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCategoryForm(BuildContext context,
      {required AppDatabase db, Category? existing, MovementType? preferredType}) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        db: db,
        existing: existing,
        preferredType: preferredType,
        onChanged: () => setState(() {}),
      ),
    );
  }

  void _showCategoryMovements(
    BuildContext context,
    AppDatabase db,
    Category category,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CategoryMovementsSheet(db: db, category: category),
    );
  }
}

class _CleanListTile extends StatelessWidget {
  final Category category;
  final AppDatabase db;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onChanged;

  const _CleanListTile({
    super.key,
    required this.category,
    required this.db,
    required this.onTap,
    required this.onEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = StreamIconLibrary.getIcon(category.iconKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(category.color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconData, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    style: category.archived
                        ? StreamTypography.body.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: StreamColors.textSecondary,
                          )
                        : StreamTypography.body,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'archive':
                        db.archiveCategory(category.id);
                        onChanged();
                        break;
                      case 'restore':
                        db.restoreCategory(category.id);
                        onChanged();
                        break;
                      case 'delete':
                        _tryDelete(context);
                        break;
                    }
                  },
                  icon: Icon(Icons.more_horiz, size: 18, color: StreamColors.textMuted),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    if (!category.archived)
                      const PopupMenuItem(value: 'archive', child: Text('Archivia')),
                    if (category.archived)
                      const PopupMenuItem(value: 'restore', child: Text('Ripristina')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Elimina', style: TextStyle(color: StreamColors.expense)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _tryDelete(BuildContext context) {
    if (db.categoryHasMovements(category.id)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Impossibile eliminare'),
          content: Text(
              'La categoria "${category.name}" contiene movimenti.\n\n'
              'Archiviala o riassegna i movimenti prima di eliminarla.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare categoria?'),
          content: Text(
              'La categoria "${category.name}" sarà eliminata definitivamente.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            TextButton(
              onPressed: () {
                db.deleteCategory(category.id);
                onChanged();
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: StreamColors.expense),
              child: const Text('Elimina'),
            ),
          ],
        ),
      );
    }
  }
}

class _GroupedListTile extends StatelessWidget {
  final Category category;
  final AppDatabase db;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onChanged;

  const _GroupedListTile({
    super.key,
    required this.category,
    required this.db,
    required this.onTap,
    required this.onEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = StreamIconLibrary.getIcon(category.iconKey);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(category.color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: category.archived
                    ? StreamTypography.body.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: StreamColors.textSecondary,
                      )
                    : StreamTypography.body,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'archive':
                    db.archiveCategory(category.id);
                    onChanged();
                    break;
                  case 'restore':
                    db.restoreCategory(category.id);
                    onChanged();
                    break;
                  case 'delete':
                    _tryDelete(context);
                    break;
                }
              },
              icon: Icon(Icons.more_horiz, size: 18, color: StreamColors.textMuted),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                if (!category.archived)
                  const PopupMenuItem(value: 'archive', child: Text('Archivia')),
                if (category.archived)
                  const PopupMenuItem(value: 'restore', child: Text('Ripristina')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Elimina', style: TextStyle(color: StreamColors.expense)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _tryDelete(BuildContext context) {
    if (db.categoryHasMovements(category.id)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Impossibile eliminare'),
          content: Text(
              'La categoria "${category.name}" contiene movimenti.\n\n'
              'Archiviala o riassegna i movimenti prima di eliminarla.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare categoria?'),
          content: Text(
              'La categoria "${category.name}" sarà eliminata definitivamente.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            TextButton(
              onPressed: () {
                db.deleteCategory(category.id);
                onChanged();
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: StreamColors.expense),
              child: const Text('Elimina'),
            ),
          ],
        ),
      );
    }
  }
}

class _StreamCardGridTile extends StatelessWidget {
  final Category category;
  final int movementCount;
  final double totalAmount;
  final AppDatabase db;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onChanged;

  const _StreamCardGridTile({
    super.key,
    required this.category,
    required this.movementCount,
    required this.totalAmount,
    required this.db,
    required this.onTap,
    required this.onEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = StreamIconLibrary.getIcon(category.iconKey);
    final sign = totalAmount >= 0 ? '+' : '';
    final formattedTotal = '$sign${totalAmount.toStringAsFixed(2)} €';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StreamColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: StreamColors.surfaceElevated, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(category.color),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(iconData, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'archive':
                          db.archiveCategory(category.id);
                          onChanged();
                          break;
                        case 'restore':
                          db.restoreCategory(category.id);
                          onChanged();
                          break;
                        case 'delete':
                          _tryDelete(context);
                          break;
                      }
                    },
                    icon: Icon(Icons.more_horiz,
                        size: 18, color: StreamColors.textMuted),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                      if (!category.archived)
                        const PopupMenuItem(
                            value: 'archive', child: Text('Archivia')),
                      if (category.archived)
                        const PopupMenuItem(
                            value: 'restore', child: Text('Ripristina')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Elimina',
                            style: TextStyle(color: StreamColors.expense)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: category.archived
                    ? StreamTypography.bodyBold.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: StreamColors.textSecondary,
                      )
                    : StreamTypography.bodyBold,
              ),
              const SizedBox(height: 6),
              Text(
                formattedTotal,
                style: StreamTypography.amount.copyWith(
                  fontSize: 16,
                  color: StreamColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                movementCount == 1
                    ? '$movementCount movimento'
                    : '$movementCount movimenti',
                style: StreamTypography.micro.copyWith(
                  color: StreamColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _tryDelete(BuildContext context) {
    if (db.categoryHasMovements(category.id)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Impossibile eliminare'),
          content: Text(
              'La categoria "${category.name}" contiene movimenti.\n\n'
              'Archiviala o riassegna i movimenti prima di eliminarla.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare categoria?'),
          content: Text(
              'La categoria "${category.name}" sarà eliminata definitivamente.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            TextButton(
              onPressed: () {
                db.deleteCategory(category.id);
                onChanged();
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: StreamColors.expense),
              child: const Text('Elimina'),
            ),
          ],
        ),
      );
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final AppDatabase db;
  final Category? existing;
  final MovementType? preferredType;
  final VoidCallback onChanged;

  const _CategoryFormDialog({
    required this.db,
    this.existing,
    this.preferredType,
    required this.onChanged,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _nameCtrl;
  late MovementType _type;
  int _color = 0xFF42A5F5;
  String _iconKey = StreamIconLibrary.defaultCategoryIcon;
  bool _typeLocked = false;
  String? _typeLockMessage;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    if (e != null) {
      _type = e.type;
      _color = e.color;
      _iconKey = e.iconKey;
      if (widget.db.categoryHasMovements(e.id)) {
        _typeLocked = true;
        _typeLockMessage =
            'Tipo non modificabile: la categoria contiene movimenti.';
      }
    } else {
      _type = widget.preferredType ?? MovementType.expense;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isDuplicateName {
    final name = _nameCtrl.text.trim().toLowerCase();
    if (name.isEmpty) return false;
    return widget.db.categories.any((c) =>
        c.name.toLowerCase() == name &&
        c.id != (widget.existing?.id ?? ''));
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome')),
      );
      return;
    }
    if (_isDuplicateName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esiste già una categoria con questo nome')),
      );
      return;
    }

    if (widget.existing != null) {
      widget.db.updateCategory(
        widget.existing!.id,
        name,
        _color,
        type: _typeLocked ? null : _type,
        iconKey: _iconKey,
      );
    } else {
      widget.db.addCategory(name, _type, _color, iconKey: _iconKey);
    }

    widget.onChanged();
    Navigator.pop(context);
  }

  Future<void> _pickIcon() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => IconPickerDialog(
        currentIconKey: _iconKey,
        isAccount: false,
      ),
    );
    if (result != null) {
      setState(() => _iconKey = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewIcon = StreamIconLibrary.getIcon(_iconKey);
    return AlertDialog(
      title: Text(widget.existing != null ? 'Modifica categoria' : 'Nuova categoria'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
            ),
            if (widget.existing == null) ...[
              const SizedBox(height: 16),
              SegmentedButton<MovementType>(
                segments: const [
                  ButtonSegment(value: MovementType.expense, label: Text('Uscita')),
                  ButtonSegment(value: MovementType.income, label: Text('Entrata')),
                ],
                selected: {_type},
                onSelectionChanged: (set) =>
                    setState(() => _type = set.first),
              ),
            ],
            if (_typeLocked) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: StreamColors.warning),
                  const SizedBox(width: 8),
                  Text(_typeLockMessage!,
                      style: TextStyle(fontSize: 12, color: StreamColors.warning)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Icona', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
                GestureDetector(
                  onTap: _pickIcon,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: StreamColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(previewIcon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(StreamIconLibrary.getLabel(_iconKey),
                            style: StreamTypography.caption),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: StreamColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Colore', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
            const SizedBox(height: 12),
            ColorPicker(
              currentColor: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla')),
        FilledButton(
          onPressed: _save,
          child: Text(widget.existing != null ? 'Salva' : 'Crea'),
        ),
      ],
    );
  }
}

class _CategoryMovementsSheet extends StatefulWidget {
  final AppDatabase db;
  final Category category;

  const _CategoryMovementsSheet({
    required this.db,
    required this.category,
  });

  @override
  State<_CategoryMovementsSheet> createState() => _CategoryMovementsSheetState();
}

class _CategoryMovementsSheetState extends State<_CategoryMovementsSheet> {
  late TimeFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
  }

  List<Movement> get _categoryMovements {
    return widget.db.movements
        .where((m) =>
            m.categoryId == widget.category.id &&
            m.type == widget.category.type)
        .toList()
        .filterByTime(_filter);
  }

  double get _periodTotal {
    return _categoryMovements.fold<double>(
      0.0,
      (sum, m) => sum + m.amount,
    );
  }

  String get _totalLabel =>
      widget.category.type == MovementType.income ? 'Totale entrate' : 'Totale spese';

  @override
  Widget build(BuildContext context) {
    final movements = _categoryMovements;
    final hasMovements = movements.isNotEmpty;

    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) => FractionallySizedBox(
        heightFactor: 0.95,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Movimenti categoria', style: StreamTypography.h2),
                  ),
                  IconButton(
                    key: const Key('category_movements_close_button'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                widget.category.name,
                key: const Key('category_movements_name'),
                style: StreamTypography.h3.copyWith(
                  color: StreamColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: _totalLabel,
                    value: _formatMoney(_periodTotal),
                    key: const Key('category_movements_total'),
                  ),
                  _StatChip(
                    label: 'Numero movimenti',
                    value: '${movements.length}',
                    key: const Key('category_movements_count'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TimeFilterBar(
                activeFilter: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: hasMovements
                    ? GroupedMovementsList(
                        movements: movements,
                        db: widget.db,
                        showNotes: true,
                      )
                    : Center(
                        child: Text(
                          'Nessun movimento in questo periodo',
                          style: StreamTypography.body.copyWith(
                            color: StreamColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} €';
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StreamColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: StreamTypography.amount.copyWith(
              color: StreamColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

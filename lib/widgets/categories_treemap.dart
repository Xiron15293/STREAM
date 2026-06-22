import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/movement.dart';
import '../theme.dart';
import '../utils/filter_ux_copy.dart';
import '../utils/heatmap_utils.dart';

enum CategoriesTreemapSort { totalDesc, totalAsc, nameAsc, countDesc }

class CategoriesTreemapItem {
  final Category category;
  final double total;
  final int movementCount;

  const CategoriesTreemapItem({
    required this.category,
    required this.total,
    required this.movementCount,
  });
}

class CategoriesTreemap extends StatefulWidget {
  final List<Category> categories;
  final List<Movement> movements;
  final ValueChanged<Category> onCategoryTap;

  const CategoriesTreemap({
    super.key,
    required this.categories,
    required this.movements,
    required this.onCategoryTap,
  });

  @override
  State<CategoriesTreemap> createState() => _CategoriesTreemapState();
}

class _CategoriesTreemapState extends State<CategoriesTreemap> {
  CategoriesTreemapSort _sort = CategoriesTreemapSort.totalDesc;

  @override
  Widget build(BuildContext context) {
    final items = _sortedItems();

    return Column(
      key: const Key('categories_layout_treemap'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Treemap categorie',
                  style: StreamTypography.captionBold.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
              ),
              PopupMenuButton<CategoriesTreemapSort>(
                key: const Key('categories_treemap_sort_button'),
                initialValue: _sort,
                tooltip: 'Ordina treemap',
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    key: Key('categories_treemap_sort_total_desc'),
                    value: CategoriesTreemapSort.totalDesc,
                    child: Text('Totale decrescente'),
                  ),
                  PopupMenuItem(
                    key: Key('categories_treemap_sort_total_asc'),
                    value: CategoriesTreemapSort.totalAsc,
                    child: Text('Totale crescente'),
                  ),
                  PopupMenuItem(
                    key: Key('categories_treemap_sort_name_asc'),
                    value: CategoriesTreemapSort.nameAsc,
                    child: Text('Nome A-Z'),
                  ),
                  PopupMenuItem(
                    key: Key('categories_treemap_sort_count_desc'),
                    value: CategoriesTreemapSort.countDesc,
                    child: Text('Numero movimenti decrescente'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: StreamColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(StreamRadius.sm),
                    border: Border.all(color: StreamColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, size: 16),
                      const SizedBox(width: 6),
                      Text(_sortLabel, style: StreamTypography.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const _TreemapEmpty()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final rows = _buildRows(items);
                      final minHeight = rows.length * 82.0;
                      final height = math.max(constraints.maxHeight, minHeight);

                      return SingleChildScrollView(
                        key: const Key('categories_treemap'),
                        child: SizedBox(
                          height: height,
                          child: _TreemapRows(
                            rows: rows,
                            totalAmount: items.fold<double>(
                              0,
                              (sum, item) => sum + item.total,
                            ),
                            onCategoryTap: widget.onCategoryTap,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<CategoriesTreemapItem> _sortedItems() {
    final movementByCategory = <String, List<Movement>>{};
    for (final movement in widget.movements) {
      if (movement.isTransfer) continue;
      movementByCategory
          .putIfAbsent(movement.categoryId, () => <Movement>[])
          .add(movement);
    }

    final items = widget.categories
        .map((category) {
          final movements =
              (movementByCategory[category.id] ?? const <Movement>[])
                  .where((movement) => movement.type == category.type)
                  .toList();
          return CategoriesTreemapItem(
            category: category,
            total: movements.fold<double>(0, (sum, m) => sum + m.amount),
            movementCount: movements.length,
          );
        })
        .where((item) => item.total > 0 && item.movementCount > 0)
        .toList();

    items.sort((a, b) {
      switch (_sort) {
        case CategoriesTreemapSort.totalDesc:
          final total = b.total.compareTo(a.total);
          return total != 0
              ? total
              : a.category.name.compareTo(b.category.name);
        case CategoriesTreemapSort.totalAsc:
          final total = a.total.compareTo(b.total);
          return total != 0
              ? total
              : a.category.name.compareTo(b.category.name);
        case CategoriesTreemapSort.nameAsc:
          return a.category.name.compareTo(b.category.name);
        case CategoriesTreemapSort.countDesc:
          final count = b.movementCount.compareTo(a.movementCount);
          return count != 0 ? count : b.total.compareTo(a.total);
      }
    });
    return items;
  }

  List<List<CategoriesTreemapItem>> _buildRows(
    List<CategoriesTreemapItem> items,
  ) {
    if (items.length <= 2) return [items];

    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    final targetRows = math.sqrt(items.length).ceil().clamp(2, 6);
    final targetRowTotal = total / targetRows;
    final rows = <List<CategoriesTreemapItem>>[];
    var current = <CategoriesTreemapItem>[];
    var currentTotal = 0.0;

    for (final item in items) {
      final shouldWrap =
          current.isNotEmpty &&
          currentTotal >= targetRowTotal &&
          rows.length < targetRows - 1;
      if (shouldWrap) {
        rows.add(current);
        current = <CategoriesTreemapItem>[];
        currentTotal = 0;
      }
      current.add(item);
      currentTotal += item.total;
    }
    if (current.isNotEmpty) rows.add(current);
    return rows;
  }

  String get _sortLabel {
    switch (_sort) {
      case CategoriesTreemapSort.totalDesc:
        return 'Totale ↓';
      case CategoriesTreemapSort.totalAsc:
        return 'Totale ↑';
      case CategoriesTreemapSort.nameAsc:
        return 'Nome A-Z';
      case CategoriesTreemapSort.countDesc:
        return 'Movimenti ↓';
    }
  }
}

class _TreemapRows extends StatelessWidget {
  final List<List<CategoriesTreemapItem>> rows;
  final double totalAmount;
  final ValueChanged<Category> onCategoryTap;

  const _TreemapRows({
    required this.rows,
    required this.totalAmount,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((row) {
        final rowTotal = row.fold<double>(0, (sum, item) => sum + item.total);
        return Expanded(
          flex: math.max(1, (rowTotal / totalAmount * 1000).round()),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: row.map((item) {
              return Expanded(
                flex: math.max(1, (item.total / rowTotal * 1000).round()),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: _TreemapTile(
                    item: item,
                    onTap: () => onCategoryTap(item.category),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _TreemapTile extends StatelessWidget {
  final CategoriesTreemapItem item;
  final VoidCallback onTap;

  const _TreemapTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(item.category.color);
    final foreground = color.computeLuminance() > 0.45
        ? Colors.black.withValues(alpha: 0.82)
        : Colors.white;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(StreamRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('categories_treemap_tile'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxHeight < 92 || constraints.maxWidth < 132;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.category.name,
                    key: const Key('categories_treemap_label'),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: StreamTypography.captionBold.copyWith(
                      color: foreground,
                      letterSpacing: 0,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatHeatmapAmount(item.total),
                        key: const Key('categories_treemap_amount'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StreamTypography.amount.copyWith(
                          color: foreground,
                          fontSize: compact ? 14 : 17,
                          letterSpacing: 0,
                        ),
                      ),
                      if (!compact)
                        Text(
                          item.movementCount == 1
                              ? '1 movimento'
                              : '${item.movementCount} movimenti',
                          key: const Key('categories_treemap_count'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StreamTypography.micro.copyWith(
                            color: foreground.withValues(alpha: 0.78),
                            letterSpacing: 0,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TreemapEmpty extends StatelessWidget {
  const _TreemapEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('categories_treemap_empty'),
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              FilterUxCopy.noDataTitle,
              textAlign: TextAlign.center,
              style: StreamTypography.bodyBold.copyWith(
                color: StreamColors.textSecondary,
              ),
            ),
            const SizedBox(height: StreamSpacing.xs),
            Text(
              FilterUxCopy.noDataSubtitle,
              textAlign: TextAlign.center,
              style: StreamTypography.caption.copyWith(
                color: StreamColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

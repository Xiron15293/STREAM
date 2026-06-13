import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';

class PeriodCategoryTreemap extends StatelessWidget {
  final List<Movement> movements;
  final List<Category> categories;
  final TimeFilter filter;
  final MovementType? selectedType;

  const PeriodCategoryTreemap({
    super.key,
    required this.movements,
    required this.categories,
    required this.filter,
    this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveType = selectedType ?? MovementType.expense;
    if (effectiveType == MovementType.transfer) {
      return _TreemapShell(
        title: _titleForFilter(filter),
        child: _EmptyTreemap(
          key: const Key('period_category_treemap_transfer_empty'),
          message: 'I trasferimenti non sono distribuiti per categoria.',
        ),
      );
    }

    final totals = _categoryTotals(effectiveType);
    if (totals.isEmpty) {
      return _TreemapShell(
        title: _titleForFilter(filter),
        child: const _EmptyTreemap(
          key: Key('period_category_treemap_empty'),
          message: 'Nessuna categoria nel periodo',
        ),
      );
    }

    final totalAmount = totals.fold<double>(0, (sum, item) => sum + item.total);
    return _TreemapShell(
      title: _titleForFilter(filter),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final blockHeight = width < 360 ? 76.0 : 88.0;

          return Wrap(
            spacing: StreamSpacing.sm,
            runSpacing: StreamSpacing.sm,
            children: totals.map((item) {
              final ratio = totalAmount == 0 ? 0.0 : item.total / totalAmount;
              final minWidth = width < 360 ? width : 132.0;
              final maxWidth = math.max(minWidth, width);
              final blockWidth = (width * math.max(0.28, ratio)).clamp(
                minWidth,
                maxWidth,
              );

              return SizedBox(
                width: blockWidth,
                height: blockHeight,
                child: _TreemapBlock(item: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  List<_CategoryTotal> _categoryTotals(MovementType type) {
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final totals = <String, double>{};

    for (final movement in movements) {
      if (movement.type != type) continue;
      totals.update(
        movement.categoryId,
        (value) => value + movement.amount,
        ifAbsent: () => movement.amount,
      );
    }

    final items = totals.entries.where((entry) => entry.value > 0).map((entry) {
      final category = categoryById[entry.key];
      return _CategoryTotal(
        label: category?.name ?? 'Categoria',
        total: entry.value,
        color: Color(category?.color ?? 0xFF8E8E93),
      );
    }).toList();

    items.sort((a, b) {
      final amountCompare = b.total.compareTo(a.total);
      if (amountCompare != 0) return amountCompare;
      return a.label.compareTo(b.label);
    });
    return items;
  }

  String _titleForFilter(TimeFilter filter) {
    switch (filter.mode) {
      case TimeFilterMode.day:
        return 'Categorie del giorno';
      case TimeFilterMode.week:
        return 'Categorie della settimana';
      case TimeFilterMode.month:
        return 'Categorie del mese';
      case TimeFilterMode.year:
        return 'Categorie dell\'anno';
      case TimeFilterMode.customRange:
        return 'Categorie del periodo';
    }
  }
}

class _TreemapShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _TreemapShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('period_category_treemap'),
      padding: const EdgeInsets.fromLTRB(
        StreamSpacing.lg,
        StreamSpacing.sm,
        StreamSpacing.lg,
        StreamSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: StreamTypography.captionBold),
          const SizedBox(height: StreamSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _TreemapBlock extends StatelessWidget {
  final _CategoryTotal item;

  const _TreemapBlock({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.color;
    return Container(
      key: const Key('period_category_treemap_block'),
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            key: const Key('period_category_treemap_label'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StreamTypography.captionBold.copyWith(
              color: StreamColors.textPrimary,
            ),
          ),
          Text(
            formatHeatmapAmount(item.total),
            key: const Key('period_category_treemap_amount'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StreamTypography.amount.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyTreemap extends StatelessWidget {
  final String message;

  const _EmptyTreemap({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: StreamColors.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Text(
        message,
        style: StreamTypography.caption.copyWith(
          color: StreamColors.textSecondary,
        ),
      ),
    );
  }
}

class _CategoryTotal {
  final String label;
  final double total;
  final Color color;

  const _CategoryTotal({
    required this.label,
    required this.total,
    required this.color,
  });
}

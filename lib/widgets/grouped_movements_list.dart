import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../data/database.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/daily_group.dart';
import '../theme.dart';
import 'movement_card.dart';
import 'day_header.dart';

class GroupedMovementsList extends StatelessWidget {
  final List<Movement> movements;
  final AppDatabase db;
  final bool showNotes;
  final ScrollController? scrollController;
  final MovementType? filterType;
  final Widget? topWidget;
  final bool useSliver;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function(Movement)? onEdit;
  final void Function(Movement)? onDuplicate;
  final void Function(Movement)? onSaveAsFavorite;
  final void Function(Movement)? onAddQuick;
  final void Function(Movement)? onDelete;

  const GroupedMovementsList({
    super.key,
    required this.movements,
    required this.db,
    this.showNotes = false,
    this.scrollController,
    this.filterType,
    this.topWidget,
    this.useSliver = false,
    this.shrinkWrap = false,
    this.physics,
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onAddQuick,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups = groupMovementsByDay(movements);
    final totalItems = groups.fold<int>(
      0,
      (sum, g) => sum + 1 + g.movements.length,
    );

    if (useSliver) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          StreamSpacing.lg,
          0,
          StreamSpacing.lg,
          0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildItem(context, index, groups),
            childCount: totalItems,
          ),
        ),
      );
    }

    if (topWidget != null) {
      return CustomScrollView(
        controller: scrollController,
        shrinkWrap: shrinkWrap,
        physics: physics,
        slivers: [
          SliverToBoxAdapter(child: topWidget),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              StreamSpacing.lg,
              0,
              StreamSpacing.lg,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildItem(context, index, groups),
                childCount: totalItems,
              ),
            ),
          ),
          if (!shrinkWrap) const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.fromLTRB(
        StreamSpacing.lg,
        0,
        StreamSpacing.lg,
        80,
      ),
      itemCount: totalItems,
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
      itemBuilder: (context, index) => _buildItem(context, index, groups),
    );
  }

  Widget? _buildItem(
    BuildContext context,
    int index,
    List<DailyMovementGroup> groups,
  ) {
    int cursor = 0;
    for (final group in groups) {
      final groupTotal = 1 + group.movements.length;
      if (index < cursor + groupTotal) {
        final localIdx = index - cursor;
        if (localIdx == 0) {
          return DayHeader(group: group, filterType: filterType);
        }
        final m = group.movements[localIdx - 1];
        final cat = db.categories
            .where((c) => c.id == m.categoryId)
            .firstOrNull;
        final acc = db.accounts.where((a) => a.id == m.accountId).firstOrNull;
        final destinationAcc = m.destinationAccountId == null
            ? null
            : db.accounts
                  .where((a) => a.id == m.destinationAccountId)
                  .firstOrNull;
        final subcat = m.subcategoryId == null
            ? null
            : db.subcategories.where((s) => s.id == m.subcategoryId).firstOrNull;
        return MovementCard(
          movement: m,
          category: cat,
          subcategory: subcat,
          account: acc,
          destinationAccount: destinationAcc,
          showNotes: showNotes,
          showDate: false,
          onEdit: onEdit != null ? () => onEdit!(m) : null,
          onDuplicate: onDuplicate != null ? () => onDuplicate!(m) : null,
          onSaveAsFavorite: onSaveAsFavorite != null
              ? () => onSaveAsFavorite!(m)
              : null,
          onAddQuick: onAddQuick != null
              ? () => onAddQuick!(m)
              : null,
          onDelete: onDelete != null ? () => onDelete!(m) : null,
        );
      }
      cursor += groupTotal;
    }
    return null;
  }
}

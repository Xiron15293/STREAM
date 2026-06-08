import 'package:flutter/material.dart';
import '../data/database.dart';
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
  final void Function(Movement)? onEdit;
  final void Function(Movement)? onDuplicate;
  final void Function(Movement)? onSaveAsFavorite;
  final void Function(Movement)? onDelete;

  const GroupedMovementsList({
    super.key,
    required this.movements,
    required this.db,
    this.showNotes = false,
    this.scrollController,
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups = groupMovementsByDay(movements);
    final totalItems = groups.fold<int>(0, (sum, g) => sum + 1 + g.movements.length);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, 0, StreamSpacing.lg, 80),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        int cursor = 0;
        for (final group in groups) {
          final groupTotal = 1 + group.movements.length;
          if (index < cursor + groupTotal) {
            final localIdx = index - cursor;
            if (localIdx == 0) {
              return DayHeader(group: group);
            }
            final m = group.movements[localIdx - 1];
            final cat = db.categories.where((c) => c.id == m.categoryId).firstOrNull;
            final acc = db.accounts.where((a) => a.id == m.accountId).firstOrNull;
            final destinationAcc = m.destinationAccountId == null
                ? null
                : db.accounts.where((a) => a.id == m.destinationAccountId).firstOrNull;
            return MovementCard(
              movement: m,
              category: cat,
              account: acc,
              destinationAccount: destinationAcc,
              showNotes: showNotes,
              showDate: false,
              onEdit: onEdit != null ? () => onEdit!(m) : null,
              onDuplicate: onDuplicate != null ? () => onDuplicate!(m) : null,
              onSaveAsFavorite: onSaveAsFavorite != null ? () => onSaveAsFavorite!(m) : null,
              onDelete: onDelete != null ? () => onDelete!(m) : null,
            );
          }
          cursor += groupTotal;
        }
        return null;
      },
    );
  }
}

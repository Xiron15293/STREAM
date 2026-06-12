import 'package:flutter/material.dart';
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/account.dart';
import '../theme.dart';

class MovementCard extends StatelessWidget {
  final Movement movement;
  final Category? category;
  final Subcategory? subcategory;
  final Account? account;
  final Account? destinationAccount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onSaveAsFavorite;
  final VoidCallback? onDelete;
  final bool showNotes;
  final bool showDate;

  const MovementCard({
    super.key,
    required this.movement,
    this.category,
    this.subcategory,
    this.account,
    this.destinationAccount,
    this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onDelete,
    this.showNotes = false,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTransfer = movement.type == MovementType.transfer;
    final iconData = isTransfer
        ? Icons.swap_horiz
        : category != null
        ? StreamIconLibrary.getIcon(category!.iconKey)
        : Icons.help_outline;
    final hasPopup =
        onEdit != null ||
        onDuplicate != null ||
        onSaveAsFavorite != null ||
        onDelete != null;

    return Container(
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(StreamRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(StreamSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(category?.color ?? 0xFF636366),
                        borderRadius: BorderRadius.circular(StreamRadius.sm),
                      ),
                      child: Icon(iconData, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: StreamSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movement.title,
                            style: StreamTypography.bodyBold,
                          ),
                          const SizedBox(height: 2),
                          if (isTransfer)
                            _MetadataRow(
                              icon: Icons.swap_horiz,
                              iconColor: StreamColors.textMuted,
                              text:
                                  'Da ${account?.name ?? movement.accountId} → ${destinationAccount?.name ?? movement.destinationAccountId ?? defaultAccountId}',
                            )
                          else if (category != null)
                            _MetadataRow(
                              icon: StreamIconLibrary.getIcon(
                                category!.iconKey,
                              ),
                              iconColor: Color(category!.color),
                              text: category!.name,
                            )
                          else
                            _MetadataRow(
                              icon: Icons.help_outline,
                              iconColor: StreamColors.textMuted,
                              text: movement.categoryId,
                            ),
                          if (subcategory != null && category != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: _MetadataRow(
                                icon: StreamIconLibrary.getIcon(
                                  subcategory!.iconKey ?? category!.iconKey,
                                ),
                                iconColor: Color(
                                  subcategory!.color ?? category!.color,
                                ),
                                text: subcategory!.name,
                              ),
                            ),
                          if (!isTransfer && account != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: _MetadataRow(
                                icon: StreamIconLibrary.getAccountIcon(
                                  account!.iconKey,
                                ),
                                iconColor: Color(account!.color),
                                text: account!.name,
                              ),
                            ),
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                _formatDate(movement.date),
                                style: StreamTypography.caption.copyWith(
                                  color: StreamColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: StreamSpacing.sm),
                    Text(
                      isTransfer
                          ? '${movement.amount.toStringAsFixed(2)} €'
                          : '${movement.type == MovementType.expense ? '-' : '+'}${movement.amount.toStringAsFixed(2)} €',
                      style: StreamTypography.amount.copyWith(
                        color: isTransfer
                            ? StreamColors.textSecondary
                            : movement.type == MovementType.expense
                            ? StreamColors.expense
                            : StreamColors.income,
                      ),
                    ),
                    if (hasPopup) ...[
                      const SizedBox(width: StreamSpacing.xs),
                      _PopupMenu(
                        onEdit: onEdit,
                        onDuplicate: onDuplicate,
                        onSaveAsFavorite: onSaveAsFavorite,
                        onDelete: onDelete,
                      ),
                    ],
                  ],
                ),
                if (showNotes &&
                    movement.note != null &&
                    movement.note!.isNotEmpty) ...[
                  const SizedBox(height: StreamSpacing.sm),
                  _NoteBox(note: movement.note!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _MetadataRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _MetadataRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: StreamTypography.caption.copyWith(
                color: StreamColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String note;

  const _NoteBox({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StreamSpacing.sm),
      decoration: BoxDecoration(
        color: StreamColors.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.notes_rounded, size: 14, color: StreamColors.textMuted),
          const SizedBox(width: StreamSpacing.sm),
          Expanded(
            child: Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: StreamTypography.caption.copyWith(
                color: StreamColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onSaveAsFavorite;
  final VoidCallback? onDelete;

  const _PopupMenu({
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onDelete,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare movimento?'),
        content: const Text('Questa operazione non può essere annullata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: StreamColors.expense),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('movement_card_action'),
      icon: Icon(Icons.more_horiz, size: 20, color: StreamColors.textMuted),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        if (onEdit != null) {
          items.add(
            const PopupMenuItem(
              value: 'modifica',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Modifica'),
                dense: true,
              ),
            ),
          );
        }
        if (onDuplicate != null) {
          items.add(
            const PopupMenuItem(
              value: 'duplica',
              child: ListTile(
                leading: Icon(Icons.copy, size: 20),
                title: Text('Duplica'),
                dense: true,
              ),
            ),
          );
        }
        if (onSaveAsFavorite != null) {
          items.add(
            const PopupMenuItem(
              value: 'preferito',
              child: ListTile(
                leading: Icon(Icons.favorite_border, size: 20),
                title: Text('Salva preferito'),
                dense: true,
              ),
            ),
          );
        }
        if (onDelete != null) {
          items.add(
            PopupMenuItem(
              value: 'elimina',
              child: ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: StreamColors.expense,
                ),
                title: Text(
                  'Elimina',
                  style: TextStyle(color: StreamColors.expense),
                ),
                dense: true,
              ),
            ),
          );
        }
        return items;
      },
      onSelected: (value) {
        switch (value) {
          case 'modifica':
            onEdit?.call();
          case 'duplica':
            onDuplicate?.call();
          case 'preferito':
            onSaveAsFavorite?.call();
          case 'elimina':
            _confirmDelete(context);
        }
      },
    );
  }
}

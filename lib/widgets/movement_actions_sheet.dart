import 'package:flutter/material.dart';

import '../design/stream_theme_extension.dart';
import '../theme.dart';

Future<void> showMovementActionsSheet(
  BuildContext context, {
  VoidCallback? onEdit,
  VoidCallback? onDuplicate,
  VoidCallback? onSaveAsFavorite,
  VoidCallback? onAddQuick,
  VoidCallback? onDelete,
}) async {
  final p = context.$palette;
  final hasActions =
      onEdit != null ||
      onDuplicate != null ||
      onSaveAsFavorite != null ||
      onAddQuick != null ||
      onDelete != null;
  if (!hasActions) return;

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      Future<void> closeAndRun(Future<void> Function() action) async {
        Navigator.of(sheetContext).pop();
        await action();
      }

      Future<void> confirmDelete() async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare movimento?'),
            content: const Text('Questa operazione non può essere annullata.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: p.expense),
                child: const Text('Elimina'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          onDelete?.call();
        }
      }

      Widget actionTile({
        required Key key,
        required IconData icon,
        required String label,
        required Future<void> Function() onTap,
        Color? color,
      }) {
        return ListTile(
          key: key,
          leading: Icon(icon, color: color),
          title: Text(
            label,
            style: color == null ? null : TextStyle(color: color),
          ),
          onTap: () => closeAndRun(onTap),
        );
      }

      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: StreamSpacing.sm),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: p.divider,
                  borderRadius: BorderRadius.circular(StreamRadius.full),
                ),
              ),
              const SizedBox(height: StreamSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StreamSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Azioni movimento',
                        style: StreamTypography.h3.copyWith(
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('movement_actions_close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(Icons.close, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                actionTile(
                  key: const Key('movement_action_edit'),
                  icon: Icons.edit,
                  label: 'Modifica',
                  onTap: () async => onEdit(),
                ),
              if (onDuplicate != null)
                actionTile(
                  key: const Key('movement_action_duplicate'),
                  icon: Icons.copy,
                  label: 'Duplica',
                  onTap: () async => onDuplicate(),
                ),
              if (onSaveAsFavorite != null)
                actionTile(
                  key: const Key('movement_action_favorite'),
                  icon: Icons.favorite_border,
                  label: 'Salva preferito',
                  onTap: () async => onSaveAsFavorite(),
                ),
              if (onAddQuick != null)
                actionTile(
                  key: const Key('movement_action_quick'),
                  icon: Icons.flash_on,
                  label: 'Salva rapido',
                  onTap: () async => onAddQuick(),
                ),
              if (onDelete != null)
                actionTile(
                  key: const Key('movement_action_delete'),
                  icon: Icons.delete_outline,
                  label: 'Elimina',
                  color: p.expense,
                  onTap: () async => confirmDelete(),
                ),
              const SizedBox(height: StreamSpacing.lg),
            ],
          ),
        ),
      );
    },
  );
}

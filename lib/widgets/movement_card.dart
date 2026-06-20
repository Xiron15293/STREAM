import 'package:flutter/material.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/beneficiary_profile.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/account.dart';
import '../theme.dart';
import '../utils/currency_formatter.dart';
import 'category_subcategory_selector.dart';
import 'movement_actions_sheet.dart';

class MovementCard extends StatelessWidget {
  final Movement movement;
  final Category? category;
  final Subcategory? subcategory;
  final Account? account;
  final Account? destinationAccount;
  final String? beneficiaryDisplayName;
  final String? beneficiaryIconKey;
  final int? beneficiaryColor;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onSaveAsFavorite;
  final VoidCallback? onAddQuick;
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
    this.beneficiaryDisplayName,
    this.beneficiaryIconKey,
    this.beneficiaryColor,
    this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onAddQuick,
    this.onDelete,
    this.showNotes = false,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final surface = StreamSurfaceTokens.card(p);
    final isTransfer = movement.type == MovementType.transfer;
    final resolvedSelection = category == null
        ? null
        : CategorySubcategoryResolvedSelection(
            category: category!,
            subcategory: subcategory,
          );
    final editAction = onEdit ?? onTap;
    final iconData = isTransfer
        ? Icons.swap_horiz
        : resolvedSelection != null
        ? StreamIconLibrary.getIcon(resolvedSelection.iconKey)
        : Icons.help_outline;
    final hasPopup =
        editAction != null ||
        onDuplicate != null ||
        onSaveAsFavorite != null ||
        onAddQuick != null ||
        onDelete != null;

    return Container(
      decoration: BoxDecoration(
        color: surface.background,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: Border.all(color: surface.border, width: surface.borderWidth),
        boxShadow: surface.shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('movement_card_${movement.id}'),
          borderRadius: BorderRadius.circular(StreamRadius.md),
          onTap: editAction,
          onLongPress: hasPopup
              ? () => showMovementActionsSheet(
                  context,
                  onEdit: editAction,
                  onDuplicate: onDuplicate,
                  onSaveAsFavorite: onSaveAsFavorite,
                  onAddQuick: onAddQuick,
                  onDelete: onDelete,
                )
              : null,
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
                        color: Color(
                          resolvedSelection?.color ??
                              category?.color ??
                              0xFF636366,
                        ),
                        borderRadius: BorderRadius.circular(StreamRadius.sm),
                      ),
                      child: Icon(
                        iconData,
                        color: StreamSurfaceTokens.onAccent(
                          Color(
                            resolvedSelection?.color ??
                                category?.color ??
                                0xFF636366,
                          ),
                        ),
                        size: 16,
                      ),
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
                              iconColor: p.textMuted,
                              text:
                                  'Da ${account?.name ?? movement.accountId} → ${destinationAccount?.name ?? movement.destinationAccountId ?? defaultAccountId}',
                            )
                          else if (category != null)
                            _MetadataRow(
                              icon: StreamIconLibrary.getIcon(
                                resolvedSelection!.iconKey,
                              ),
                              iconColor: Color(resolvedSelection.color),
                              text: resolvedSelection.label,
                            )
                          else
                            _MetadataRow(
                              icon: Icons.help_outline,
                              iconColor: p.textMuted,
                              text: movement.categoryId,
                            ),
                          if (!isTransfer &&
                              movement.payee != null &&
                              movement.payee!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: _MetadataRow(
                                icon: StreamIconLibrary.getIcon(
                                  beneficiaryIconKey ??
                                      BeneficiaryProfile.defaultIconKey,
                                ),
                                iconColor: Color(
                                  beneficiaryColor ??
                                      StreamColorPalette.defaultColor,
                                ),
                                text:
                                    beneficiaryDisplayName ??
                                    movement.payee!.trim(),
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
                                  color: p.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: StreamSpacing.sm),
                    Text(
                      isTransfer
                          ? formatMovementCurrency(movement.amount)
                          : formatMovementCurrency(
                              movement.type == MovementType.expense
                                  ? -movement.amount
                                  : movement.amount,
                              showPositiveSign: true,
                            ),
                      style: StreamTypography.amount.copyWith(
                        color: isTransfer
                            ? p.textSecondary
                            : movement.type == MovementType.expense
                            ? p.expense
                            : p.income,
                      ),
                    ),
                    if (hasPopup) ...[
                      const SizedBox(width: StreamSpacing.xs),
                      MovementCardPopupMenu(
                        onEdit: editAction,
                        onDuplicate: onDuplicate,
                        onSaveAsFavorite: onSaveAsFavorite,
                        onAddQuick: onAddQuick,
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
                color: context.$palette.textSecondary,
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
        color: context.$palette.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notes_rounded,
            size: 14,
            color: context.$palette.textMuted,
          ),
          const SizedBox(width: StreamSpacing.sm),
          Expanded(
            child: Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: StreamTypography.caption.copyWith(
                color: context.$palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MovementCardPopupMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onSaveAsFavorite;
  final VoidCallback? onAddQuick;
  final VoidCallback? onDelete;

  const MovementCardPopupMenu({
    super.key,
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onAddQuick,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('movement_card_action'),
      onPressed: () => showMovementActionsSheet(
        context,
        onEdit: onEdit,
        onDuplicate: onDuplicate,
        onSaveAsFavorite: onSaveAsFavorite,
        onAddQuick: onAddQuick,
        onDelete: onDelete,
      ),
      icon: Icon(Icons.more_horiz, size: 20, color: context.$palette.textMuted),
    );
  }
}

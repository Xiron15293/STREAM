import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_icon_library.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/subcategory.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/duplicate_date_selector.dart';
import '../widgets/categories_treemap.dart';
import '../widgets/grouped_movements_list.dart';
import '../widgets/icon_picker.dart';
import '../widgets/movement_picker.dart';
import '../widgets/time_filter_bar.dart';

bool _isConvertibleCategory(String name) {
  final trimmed = name.trim();
  final parenOpen = trimmed.lastIndexOf('(');
  if (parenOpen < 1) return false;
  final parenClose = trimmed.indexOf(')', parenOpen);
  if (parenClose < 0 || parenClose != trimmed.length - 1) return false;
  final parentName = trimmed.substring(0, parenOpen).trim();
  final subName = trimmed.substring(parenOpen + 1, parenClose).trim();
  return parentName.isNotEmpty && subName.isNotEmpty;
}

void _showConvertDialog(
  BuildContext context,
  AppDatabase db,
  Category category,
  VoidCallback onChanged,
) {
  showDialog(
    context: context,
    builder: (ctx) {
      final trimmed = category.name.trim();
      final parenOpen = trimmed.lastIndexOf('(');
      if (parenOpen < 1) return const SizedBox.shrink();
      final parenClose = trimmed.indexOf(')', parenOpen);
      if (parenClose < 0) return const SizedBox.shrink();
      final parentName = trimmed.substring(0, parenOpen).trim();
      final subName = trimmed.substring(parenOpen + 1, parenClose).trim();
      return AlertDialog(
        title: const Text('Converti in sottocategoria?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La categoria "${category.name}" verrà archiviata. '
              'I movimenti collegati saranno spostati in "$parentName" '
              'con sottocategoria "$subName".',
            ),
            const SizedBox(height: 12),
            Text(
              'Questa operazione non può essere annullata.',
              style: TextStyle(fontSize: 12, color: StreamColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('category_convert_to_subcategory_cancel'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            key: const Key('category_convert_to_subcategory_confirm'),
            onPressed: () {
              final report = db.convertFlatCategoryToSubcategory(category.id);
              Navigator.pop(ctx);

              if (report != null && context.mounted) {
                _showConvertReport(context, report);
              }
              onChanged();
            },
            child: const Text('Converti'),
          ),
        ],
      );
    },
  );
}

void _showConvertReport(BuildContext context, CategoryConversionReport report) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Conversione completata'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reportRow('Categoria madre', report.parentCategoryName),
          _reportRow('Sottocategoria', report.subcategoryName),
          _reportRow(
            'Categoria madre',
            report.parentCategoryCreated ? 'Creata' : 'Riutilizzata',
          ),
          _reportRow(
            'Sottocategoria',
            report.subcategoryCreated ? 'Creata' : 'Riutilizzata',
          ),
          const Divider(height: 16),
          _reportRow('Movimenti aggiornati', '${report.movementsUpdated}'),
          _reportRow(
            'Movimenti rapidi aggiornati',
            '${report.quickMovementsUpdated}',
          ),
          _reportRow(
            'Preferiti aggiornati',
            '${report.favoriteMovementsUpdated}',
          ),
          _reportRow(
            'Categoria vecchia',
            report.oldCategoryArchived ? 'Archiviata' : 'Errore',
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Widget _reportRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

int _countMovementsForCategory(AppDatabase db, String categoryId) {
  return db.movements.where((m) => m.categoryId == categoryId).length;
}

int _countMovementsForSubcategory(AppDatabase db, String subcategoryId) {
  return db.movements.where((m) => m.subcategoryId == subcategoryId).length;
}

int _countQuickForCategory(AppDatabase db, String categoryId) {
  return db.quickMovements.where((q) => q.categoryId == categoryId).length;
}

int _countQuickForSubcategory(AppDatabase db, String subcategoryId) {
  return db.quickMovements
      .where((q) => q.subcategoryId == subcategoryId)
      .length;
}

int _countFavForCategory(AppDatabase db, String categoryId) {
  return db.favoriteMovements.where((f) => f.categoryId == categoryId).length;
}

int _countFavForSubcategory(AppDatabase db, String subcategoryId) {
  return db.favoriteMovements
      .where((f) => f.subcategoryId == subcategoryId)
      .length;
}

class _ChildSubOption {
  final String subcategoryId;
  final String subcategoryName;
  String action = 'move';
  String? targetSubcategoryId;
  String? createTargetSubcategoryName;
  TextEditingController? newSubCtrl;

  _ChildSubOption({required this.subcategoryId, required this.subcategoryName});
}

void _showCategoryMergeDialog(
  BuildContext context,
  AppDatabase db,
  Category sourceCategory,
  VoidCallback onChanged,
) {
  String? selectedTargetCategoryId;
  String? selectedTargetSubcategoryId;
  bool createNewSubcategory = false;
  final newSubNameCtrl = TextEditingController();

  final childSubs = db
      .getSubcategoriesForCategory(sourceCategory.id)
      .where((s) => !s.archived)
      .toList();
  final childOptions = <_ChildSubOption>[
    for (final s in childSubs)
      _ChildSubOption(subcategoryId: s.id, subcategoryName: s.name),
  ];

  final movCount = _countMovementsForCategory(db, sourceCategory.id);
  final quickCount = _countQuickForCategory(db, sourceCategory.id);
  final favCount = _countFavForCategory(db, sourceCategory.id);

  showDialog(
    context: context,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final sameTypeCats =
              db.categories
                  .where(
                    (c) =>
                        c.type == sourceCategory.type &&
                        !c.archived &&
                        c.id != sourceCategory.id,
                  )
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          List<Subcategory> availableSubs = [];
          if (selectedTargetCategoryId != null) {
            availableSubs = db.getActiveSubcategoriesForCategory(
              selectedTargetCategoryId!,
            );
          }

          String previewText = '';
          if (selectedTargetCategoryId != null) {
            final targetCatName = _catNameFromDb(db, selectedTargetCategoryId!);
            if (createNewSubcategory && newSubNameCtrl.text.trim().isNotEmpty) {
              previewText =
                  'Verranno spostati $movCount movimenti, '
                  '$quickCount rapidi e $favCount preferiti verso '
                  '"$targetCatName / ${newSubNameCtrl.text.trim()}".';
            } else if (selectedTargetSubcategoryId != null) {
              final targetSubName = _subcatNameFromDb(
                db,
                selectedTargetSubcategoryId!,
              );
              previewText =
                  'Verranno spostati $movCount movimenti, '
                  '$quickCount rapidi e $favCount preferiti verso '
                  '"$targetCatName / $targetSubName".';
            } else {
              previewText =
                  'Verranno spostati $movCount movimenti, '
                  '$quickCount rapidi e $favCount preferiti verso '
                  '"$targetCatName".';
            }
          }

          final canConfirm =
              selectedTargetCategoryId != null &&
              (createNewSubcategory
                  ? newSubNameCtrl.text.trim().isNotEmpty
                  : true);

          return AlertDialog(
            key: const Key('category_merge_dialog'),
            title: const Text('Unisci categoria'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scegli dove spostare tutti i movimenti collegati a '
                    '"${sourceCategory.name}".',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La categoria sorgente verrà archiviata, non eliminata.',
                    style: TextStyle(
                      fontSize: 12,
                      color: StreamColors.textSecondary,
                    ),
                  ),
                  if (movCount > 0 || quickCount > 0 || favCount > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Coinvolti: $movCount movimenti, $quickCount rapidi, $favCount preferiti',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Categoria destinazione',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('category_merge_target_category_picker'),
                    value: selectedTargetCategoryId,
                    decoration: const InputDecoration(
                      hintText: 'Seleziona categoria...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: sameTypeCats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedTargetCategoryId = val;
                        selectedTargetSubcategoryId = null;
                        createNewSubcategory = false;
                        newSubNameCtrl.clear();
                      });
                    },
                  ),
                  if (selectedTargetCategoryId != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Sottocategoria destinazione (opzionale)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      key: const Key(
                        'category_merge_target_subcategory_picker',
                      ),
                      value: createNewSubcategory
                          ? null
                          : selectedTargetSubcategoryId,
                      decoration: const InputDecoration(
                        hintText: 'Nessuna sottocategoria',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Nessuna sottocategoria'),
                        ),
                        ...availableSubs.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        ),
                        const DropdownMenuItem<String?>(
                          value: '__create__',
                          key: Key('category_merge_create_subcategory_option'),
                          child: Text('Crea nuova sottocategoria...'),
                        ),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == '__create__') {
                            createNewSubcategory = true;
                            selectedTargetSubcategoryId = null;
                          } else {
                            createNewSubcategory = false;
                            selectedTargetSubcategoryId = val;
                          }
                        });
                      },
                    ),
                    if (createNewSubcategory) ...[
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('category_merge_new_subcategory_input'),
                        controller: newSubNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nome nuova sottocategoria',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                  ],
                  // Child subcategories section
                  if (childOptions.isNotEmpty &&
                      selectedTargetCategoryId != null) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Sottocategorie figlie (${childOptions.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scegli cosa fare di ogni sottocategoria di "${sourceCategory.name}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: StreamColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...childOptions.map((opt) {
                      final targetSubsForChild =
                          selectedTargetCategoryId != null
                          ? db.getActiveSubcategoriesForCategory(
                              selectedTargetCategoryId!,
                            )
                          : <Subcategory>[];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.subcategoryName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              key: Key('child_sub_action_${opt.subcategoryId}'),
                              value: opt.action,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'move',
                                  child: Text('Sposta in destinazione'),
                                ),
                                DropdownMenuItem(
                                  value: 'merge',
                                  child: Text('Unisci a sottocategoria...'),
                                ),
                                DropdownMenuItem(
                                  value: 'archive',
                                  child: Text('Archivia'),
                                ),
                                DropdownMenuItem(
                                  value: 'keep',
                                  child: Text('Mantieni (non archiviare)'),
                                ),
                              ],
                              onChanged: (val) {
                                setDialogState(() {
                                  opt.action = val!;
                                  if (val != 'merge') {
                                    opt.targetSubcategoryId = null;
                                    opt.createTargetSubcategoryName = null;
                                    opt.newSubCtrl?.dispose();
                                    opt.newSubCtrl = null;
                                  }
                                });
                              },
                            ),
                            if (opt.action == 'merge') ...[
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String?>(
                                key: Key(
                                  'child_sub_merge_target_${opt.subcategoryId}',
                                ),
                                value: opt.targetSubcategoryId,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Seleziona o crea...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Seleziona...'),
                                  ),
                                  ...targetSubsForChild.map(
                                    (s) => DropdownMenuItem<String?>(
                                      value: s.id,
                                      child: Text(s.name),
                                    ),
                                  ),
                                  const DropdownMenuItem<String?>(
                                    value: '__create__',
                                    child: Text('Crea nuova...'),
                                  ),
                                ],
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == '__create__') {
                                      opt.targetSubcategoryId = null;
                                      if (opt.newSubCtrl == null) {
                                        opt.newSubCtrl =
                                            TextEditingController();
                                      }
                                    } else {
                                      opt.targetSubcategoryId = val;
                                      opt.newSubCtrl?.dispose();
                                      opt.newSubCtrl = null;
                                    }
                                  });
                                },
                              ),
                              if (opt.newSubCtrl != null) ...[
                                const SizedBox(height: 4),
                                TextField(
                                  key: Key(
                                    'child_sub_create_name_${opt.subcategoryId}',
                                  ),
                                  controller: opt.newSubCtrl,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Nome nuova sottocategoria',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                  if (previewText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      key: const Key('category_merge_preview'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: StreamColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        previewText,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const Key('category_merge_cancel'),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla'),
              ),
              FilledButton(
                key: const Key('category_merge_confirm'),
                onPressed: canConfirm
                    ? () {
                        final childActions = childOptions.isEmpty
                            ? null
                            : childOptions.map((opt) {
                                String? mergeTargetSubId;
                                String? mergeCreateName;
                                if (opt.action == 'merge') {
                                  if (opt.newSubCtrl != null &&
                                      opt.newSubCtrl!.text.trim().isNotEmpty) {
                                    mergeCreateName = opt.newSubCtrl!.text
                                        .trim();
                                  } else {
                                    mergeTargetSubId = opt.targetSubcategoryId;
                                  }
                                }
                                return ChildSubcategoryAction(
                                  subcategoryId: opt.subcategoryId,
                                  action: opt.action,
                                  targetSubcategoryId: mergeTargetSubId,
                                  createTargetSubcategoryName: mergeCreateName,
                                );
                              }).toList();
                        final request = CategoryMergeRequest(
                          sourceCategoryId: sourceCategory.id,
                          targetCategoryId: selectedTargetCategoryId!,
                          targetSubcategoryId: createNewSubcategory
                              ? null
                              : selectedTargetSubcategoryId,
                          createTargetSubcategoryName: createNewSubcategory
                              ? newSubNameCtrl.text.trim()
                              : null,
                          archiveSource: true,
                          archiveEmptySourceCategory: false,
                          childSubcategoryActions: childActions,
                        );
                        final report = db.mergeCategoryOrSubcategory(request);
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          _showMergeReport(context, report);
                        }
                        onChanged();
                      }
                    : null,
                child: const Text('Conferma unione'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _catNameFromDb(AppDatabase db, String id) {
  try {
    return db.categories.firstWhere((c) => c.id == id).name;
  } catch (_) {
    return id;
  }
}

String _subcatNameFromDb(AppDatabase db, String? id) {
  if (id == null) return '';
  try {
    return db.subcategories.firstWhere((s) => s.id == id).name;
  } catch (_) {
    return id;
  }
}

void _showSubcategoryMergeDialog(
  BuildContext context,
  AppDatabase db,
  Subcategory sourceSubcategory,
  VoidCallback onChanged,
) {
  String? selectedTargetCategoryId;
  String? selectedTargetSubcategoryId;
  bool createNewSubcategory = false;
  final newSubNameCtrl = TextEditingController();

  final sourceCategory = db.categories
      .where((c) => c.id == sourceSubcategory.categoryId)
      .firstOrNull;
  final sourceCatName = sourceCategory?.name ?? sourceSubcategory.categoryId;

  final movCount = _countMovementsForSubcategory(db, sourceSubcategory.id);
  final quickCount = _countQuickForSubcategory(db, sourceSubcategory.id);
  final favCount = _countFavForSubcategory(db, sourceSubcategory.id);

  if (!context.mounted) return;

  showDialog(
    context: context,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final sameTypeCats =
              db.categories
                  .where(
                    (c) =>
                        c.type ==
                            (sourceCategory?.type ?? MovementType.expense) &&
                        !c.archived,
                  )
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          List<Subcategory> availableSubs = [];
          if (selectedTargetCategoryId != null) {
            availableSubs = db.getActiveSubcategoriesForCategory(
              selectedTargetCategoryId!,
            );
          }

          String previewText = '';
          if (selectedTargetCategoryId != null) {
            final targetCatName = _catNameFromDb(db, selectedTargetCategoryId!);
            if (createNewSubcategory && newSubNameCtrl.text.trim().isNotEmpty) {
              previewText =
                  'Verranno spostati $movCount movimenti, '
                  '$quickCount rapidi e $favCount preferiti verso '
                  '"$targetCatName / ${newSubNameCtrl.text.trim()}".';
            } else if (selectedTargetSubcategoryId != null) {
              final targetSubName = _subcatNameFromDb(
                db,
                selectedTargetSubcategoryId!,
              );
              previewText =
                  'Verranno spostati $movCount movimenti, '
                  '$quickCount rapidi e $favCount preferiti verso '
                  '"$targetCatName / $targetSubName".';
            } else {
              previewText =
                  'Verranno spostati $movCount movimenti, '
                  '$quickCount rapidi e $favCount preferiti verso '
                  '"$targetCatName".';
            }
          }

          final canConfirm =
              selectedTargetCategoryId != null &&
              (createNewSubcategory
                  ? newSubNameCtrl.text.trim().isNotEmpty
                  : true);

          return AlertDialog(
            key: const Key('subcategory_merge_dialog'),
            title: const Text('Unisci sottocategoria'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scegli dove spostare i movimenti collegati a '
                    '"$sourceCatName / ${sourceSubcategory.name}".',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La sottocategoria sorgente verrà archiviata, non eliminata.',
                    style: TextStyle(
                      fontSize: 12,
                      color: StreamColors.textSecondary,
                    ),
                  ),
                  if (movCount > 0 || quickCount > 0 || favCount > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Coinvolti: $movCount movimenti, $quickCount rapidi, $favCount preferiti',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Categoria destinazione',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('subcategory_merge_target_category_picker'),
                    value: selectedTargetCategoryId,
                    decoration: const InputDecoration(
                      hintText: 'Seleziona categoria...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: sameTypeCats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedTargetCategoryId = val;
                        selectedTargetSubcategoryId = null;
                        createNewSubcategory = false;
                        newSubNameCtrl.clear();
                      });
                    },
                  ),
                  if (selectedTargetCategoryId != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Sottocategoria destinazione (opzionale)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      key: const Key(
                        'subcategory_merge_target_subcategory_picker',
                      ),
                      value: createNewSubcategory
                          ? null
                          : selectedTargetSubcategoryId,
                      decoration: const InputDecoration(
                        hintText: 'Nessuna',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Nessuna'),
                        ),
                        ...availableSubs.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        ),
                        const DropdownMenuItem<String?>(
                          value: '__create__',
                          key: Key(
                            'subcategory_merge_create_subcategory_option',
                          ),
                          child: Text('Crea nuova sottocategoria...'),
                        ),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == '__create__') {
                            createNewSubcategory = true;
                            selectedTargetSubcategoryId = null;
                          } else {
                            createNewSubcategory = false;
                            selectedTargetSubcategoryId = val;
                          }
                        });
                      },
                    ),
                    if (createNewSubcategory) ...[
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key(
                          'subcategory_merge_new_subcategory_input',
                        ),
                        controller: newSubNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nome nuova sottocategoria',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                  ],
                  if (previewText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      key: const Key('subcategory_merge_preview'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: StreamColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        previewText,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const Key('subcategory_merge_cancel'),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla'),
              ),
              FilledButton(
                key: const Key('subcategory_merge_confirm'),
                onPressed: canConfirm
                    ? () {
                        final request = CategoryMergeRequest(
                          sourceCategoryId: sourceSubcategory.categoryId,
                          sourceSubcategoryId: sourceSubcategory.id,
                          targetCategoryId: selectedTargetCategoryId!,
                          targetSubcategoryId: createNewSubcategory
                              ? null
                              : selectedTargetSubcategoryId,
                          createTargetSubcategoryName: createNewSubcategory
                              ? newSubNameCtrl.text.trim()
                              : null,
                          archiveSource: true,
                          archiveEmptySourceCategory: false,
                        );
                        final report = db.mergeCategoryOrSubcategory(request);
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          _showMergeReport(context, report);
                        }
                        onChanged();
                      }
                    : null,
                child: const Text('Conferma unione'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showMergeReport(BuildContext context, CategoryMergeReport report) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('category_merge_report'),
      title: Text(
        report.sourceType == 'subcategory'
            ? 'Unione sottocategoria completata'
            : 'Unione categoria completata',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.warnings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: StreamColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.warnings
                    .map(
                      (w) => Text(
                        w,
                        style: TextStyle(
                          fontSize: 12,
                          color: StreamColors.warning,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (report.sourceType == 'subcategory') ...[
            _reportRow('Categoria sorgente', report.sourceCategoryName),
            _reportRow(
              'Sottocategoria sorgente',
              report.sourceSubcategoryName ?? '',
            ),
          ] else ...[
            _reportRow('Categoria sorgente', report.sourceCategoryName),
          ],
          _reportRow('Categoria destinazione', report.targetCategoryName),
          if (report.targetSubcategoryName != null &&
              report.targetSubcategoryName!.isNotEmpty)
            _reportRow(
              'Sottocategoria destinaz.',
              report.targetSubcategoryName!,
            ),
          if (report.targetSubcategoryCreated)
            _reportRow('Nuova sottocat.', 'Creata'),
          const Divider(height: 16),
          _reportRow('Movimenti aggiornati', '${report.movementsUpdated}'),
          _reportRow(
            'Movimenti rapidi agg.',
            '${report.quickMovementsUpdated}',
          ),
          _reportRow(
            'Preferiti aggiornati',
            '${report.favoriteMovementsUpdated}',
          ),
          const Divider(height: 16),
          if (report.childSubcategoriesMoved > 0 ||
              report.childSubcategoriesMerged > 0 ||
              report.childSubcategoriesArchived > 0 ||
              report.childSubcategoriesKept > 0) ...[
            const Divider(height: 16),
            _reportRow(
              'Sottocat. figlie spostate',
              '${report.childSubcategoriesMoved}',
            ),
            _reportRow(
              'Sottocat. figlie unite',
              '${report.childSubcategoriesMerged}',
            ),
            _reportRow(
              'Sottocat. figlie archiviate',
              '${report.childSubcategoriesArchived}',
            ),
            _reportRow(
              'Sottocat. figlie mantenute',
              '${report.childSubcategoriesKept}',
            ),
            if (report.childSubcategoryDetails.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...report.childSubcategoryDetails.map((d) {
                final actionLabel = switch (d.action) {
                  'move' => 'Spostata',
                  'merge' => 'Unita',
                  'archive' => 'Archiviata',
                  _ => 'Mantenuta',
                };
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    ' • ${d.subcategoryName}: $actionLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: StreamColors.textSecondary,
                    ),
                  ),
                );
              }),
            ],
          ],
          if (report.sourceType == 'subcategory') ...[
            _reportRow(
              'Sottocat. sorgente',
              report.sourceSubcategoryArchived ? 'Archiviata' : '-',
            ),
            if (report.emptySourceCategoryArchived)
              _reportRow('Categoria vuota', 'Archiviata'),
          ] else ...[
            _reportRow(
              'Categoria sorgente',
              report.sourceCategoryArchived ? 'Archiviata' : '-',
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          key: const Key('category_merge_report_ok'),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class CategoriesScreen extends StatefulWidget {
  final AppDatabase db;

  const CategoriesScreen({super.key, required this.db});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  MovementType _selectedType = MovementType.expense;
  String _layoutMode = PreferencesService.defaultCategoryLayout;
  late TimeFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
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
      setState(
        () => _layoutMode = PreferencesService.categoryLayoutNotifier.value,
      );
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

  List<Movement> _periodTypeMovements() {
    return widget.db.movements
        .filterByTime(_filter)
        .where((m) => m.type == _selectedType)
        .toList();
  }

  List<Movement> _categoryPeriodMovements(
    Category category,
    List<Movement> periodTypeMovements,
  ) {
    return periodTypeMovements
        .where((m) => m.categoryId == category.id && m.type == category.type)
        .toList();
  }

  double _computeTypeTotal(List<Movement> periodTypeMovements) {
    return periodTypeMovements.fold<double>(0.0, (sum, m) => sum + m.amount);
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
          final filtered = all
              .where((c) => c.type == _selectedType && !c.archived)
              .toList();
          final archivedList = all
              .where((c) => c.archived && c.type == _selectedType)
              .toList();
          final periodTypeMovements = _periodTypeMovements();
          final total = _computeTypeTotal(periodTypeMovements);

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: KeyedSubtree(
                  key: const Key('categories_time_filter'),
                  child: TimeFilterBar(
                    activeFilter: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
              ),
              _buildTypeSummaryCard(
                total,
                filtered.length,
                archivedList.length,
                periodTypeMovements.length,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _buildLayout(
                  filtered,
                  archivedList,
                  periodTypeMovements,
                ),
              ),
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

  Widget _buildTypeSummaryCard(
    double total,
    int activeCount,
    int archivedCount,
    int movementCount,
  ) {
    final isIncome = _selectedType == MovementType.income;
    final typeColor = isIncome ? StreamColors.income : StreamColors.expense;
    final typeLabel = isIncome ? 'Entrate' : 'Uscite';

    return Padding(
      key: const Key('categories_type_summary_card'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        key: const Key('categories_period_summary'),
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
                    key: const Key('categories_period_total'),
                    style: StreamTypography.amount.copyWith(color: typeColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$movementCount ${movementCount == 1 ? 'movimento' : 'movimenti'} nel periodo',
                    key: const Key('categories_period_movement_count'),
                    style: StreamTypography.micro.copyWith(
                      color: StreamColors.textMuted,
                    ),
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

  Widget _buildLayout(
    List<Category> active,
    List<Category> archived,
    List<Movement> periodTypeMovements,
  ) {
    switch (_layoutMode) {
      case 'treemap':
        return CategoriesTreemap(
          categories: active,
          movements: periodTypeMovements,
          onCategoryTap: (category) =>
              _showCategoryMovements(context, widget.db, category),
        );
      case 'groupedList':
        return _buildGroupedList(active, archived, periodTypeMovements);
      case 'streamCards':
        return _buildStreamCards(active, archived, periodTypeMovements);
      default:
        return _buildCleanList(active, archived);
    }
  }

  Widget _buildCleanList(List<Category> active, List<Category> archived) {
    return ListView(
      key: const Key('categories_layout_clean_list'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        ...active.map(
          (c) => _CleanListTile(
            key: Key('category_card_${c.id}'),
            category: c,
            db: widget.db,
            onTap: () => _showCategoryMovements(context, widget.db, c),
            onEdit: () =>
                _showCategoryForm(context, db: widget.db, existing: c),
            onChanged: () => setState(() {}),
          ),
        ),
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
          ...archived.map(
            (c) => _CleanListTile(
              key: Key('category_card_${c.id}'),
              category: c,
              db: widget.db,
              onTap: () => _showCategoryMovements(context, widget.db, c),
              onEdit: () =>
                  _showCategoryForm(context, db: widget.db, existing: c),
              onChanged: () => setState(() {}),
            ),
          ),
        ],
        if (active.isEmpty && archived.isEmpty)
          Padding(
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
      ],
    );
  }

  Widget _buildGroupedList(
    List<Category> active,
    List<Category> archived,
    List<Movement> periodTypeMovements,
  ) {
    final sorted = List<Category>.from(active)
      ..sort((a, b) {
        final countA = _categoryPeriodMovements(a, periodTypeMovements).length;
        final countB = _categoryPeriodMovements(b, periodTypeMovements).length;
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
                          onEdit: () => _showCategoryForm(
                            context,
                            db: widget.db,
                            existing: c,
                          ),
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
                  color: StreamColors.textSecondary,
                ),
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
                  onTap: () => _showCategoryMovements(context, widget.db, c),
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

  Widget _buildStreamCards(
    List<Category> active,
    List<Category> archived,
    List<Movement> periodTypeMovements,
  ) {
    return CustomScrollView(
      key: const Key('categories_layout_stream_cards'),
      slivers: [
        if (active.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, archived.isEmpty ? 80 : 0),
            sliver: SliverGrid(
              key: const Key('categories_stream_card_grid'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final c = active[index];
                final categoryMovements = _categoryPeriodMovements(
                  c,
                  periodTypeMovements,
                );
                final movCount = categoryMovements.length;
                final total = categoryMovements.fold<double>(
                  0.0,
                  (sum, m) => sum + m.amount,
                );
                return KeyedSubtree(
                  key: const Key('categories_stream_category_card'),
                  child: _StreamCardGridTile(
                    key: Key('category_card_${c.id}'),
                    category: c,
                    movementCount: movCount,
                    totalAmount: total,
                    db: widget.db,
                    onTap: () => _showCategoryMovements(context, widget.db, c),
                    onEdit: () =>
                        _showCategoryForm(context, db: widget.db, existing: c),
                    onChanged: () => setState(() {}),
                  ),
                );
              }, childCount: active.length),
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
              delegate: SliverChildBuilderDelegate((context, index) {
                final c = archived[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GroupedListTile(
                    key: Key('category_card_${c.id}'),
                    category: c,
                    db: widget.db,
                    onTap: () => _showCategoryMovements(context, widget.db, c),
                    onEdit: () =>
                        _showCategoryForm(context, db: widget.db, existing: c),
                    onChanged: () => setState(() {}),
                  ),
                );
              }, childCount: archived.length),
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

  void _showCategoryForm(
    BuildContext context, {
    required AppDatabase db,
    Category? existing,
    MovementType? preferredType,
  }) {
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
      builder: (_) => _CategoryMovementsSheet(
        db: db,
        category: category,
        initialFilter: _filter,
      ),
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
                      case 'convert':
                        _showConvertDialog(context, db, category, onChanged);
                        break;
                      case 'merge':
                        _showCategoryMergeDialog(
                          context,
                          db,
                          category,
                          onChanged,
                        );
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
                  icon: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: StreamColors.textMuted,
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    if (!category.archived &&
                        _isConvertibleCategory(category.name))
                      const PopupMenuItem(
                        key: Key('category_convert_to_subcategory_action'),
                        value: 'convert',
                        child: Text('Converti in sottocategoria'),
                      ),
                    if (!category.archived)
                      const PopupMenuItem(
                        key: Key('category_merge_action'),
                        value: 'merge',
                        child: Text('Unisci...'),
                      ),
                    if (!category.archived)
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Archivia'),
                      ),
                    if (category.archived)
                      const PopupMenuItem(
                        value: 'restore',
                        child: Text('Ripristina'),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Elimina',
                        style: TextStyle(color: StreamColors.expense),
                      ),
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
            'Archiviala o riassegna i movimenti prima di eliminarla.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare categoria?'),
          content: Text(
            'La categoria "${category.name}" sarà eliminata definitivamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                db.deleteCategory(category.id);
                onChanged();
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(
                foregroundColor: StreamColors.expense,
              ),
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
                  case 'convert':
                    _showConvertDialog(context, db, category, onChanged);
                    break;
                  case 'merge':
                    _showCategoryMergeDialog(context, db, category, onChanged);
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
              icon: Icon(
                Icons.more_horiz,
                size: 18,
                color: StreamColors.textMuted,
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                if (!category.archived && _isConvertibleCategory(category.name))
                  const PopupMenuItem(
                    key: Key('category_convert_to_subcategory_action'),
                    value: 'convert',
                    child: Text('Converti in sottocategoria'),
                  ),
                if (!category.archived)
                  const PopupMenuItem(
                    key: Key('category_merge_action'),
                    value: 'merge',
                    child: Text('Unisci...'),
                  ),
                if (!category.archived)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Archivia'),
                  ),
                if (category.archived)
                  const PopupMenuItem(
                    value: 'restore',
                    child: Text('Ripristina'),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Elimina',
                    style: TextStyle(color: StreamColors.expense),
                  ),
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
            'Archiviala o riassegna i movimenti prima di eliminarla.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare categoria?'),
          content: Text(
            'La categoria "${category.name}" sarà eliminata definitivamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                db.deleteCategory(category.id);
                onChanged();
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(
                foregroundColor: StreamColors.expense,
              ),
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
                        case 'convert':
                          _showConvertDialog(context, db, category, onChanged);
                          break;
                        case 'merge':
                          _showCategoryMergeDialog(
                            context,
                            db,
                            category,
                            onChanged,
                          );
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
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: StreamColors.textMuted,
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifica'),
                      ),
                      if (!category.archived &&
                          _isConvertibleCategory(category.name))
                        const PopupMenuItem(
                          key: Key('category_convert_to_subcategory_action'),
                          value: 'convert',
                          child: Text('Converti in sottocategoria'),
                        ),
                      if (!category.archived)
                        const PopupMenuItem(
                          key: Key('category_merge_action'),
                          value: 'merge',
                          child: Text('Unisci...'),
                        ),
                      if (!category.archived)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Text('Archivia'),
                        ),
                      if (category.archived)
                        const PopupMenuItem(
                          value: 'restore',
                          child: Text('Ripristina'),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Elimina',
                          style: TextStyle(color: StreamColors.expense),
                        ),
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
            'Archiviala o riassegna i movimenti prima di eliminarla.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare categoria?'),
          content: Text(
            'La categoria "${category.name}" sarà eliminata definitivamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                db.deleteCategory(category.id);
                onChanged();
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(
                foregroundColor: StreamColors.expense,
              ),
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

  Category? get _currentExisting {
    final existingId = widget.existing?.id;
    if (existingId == null) return null;
    return widget.db.categories.where((c) => c.id == existingId).firstOrNull;
  }

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
            'Il tipo non è modificabile per via dei movimenti collegati. '
            'Puoi comunque modificare nome, colore e icona.';
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
    return widget.db.categories.any(
      (c) =>
          c.name.toLowerCase() == name && c.id != (widget.existing?.id ?? ''),
    );
  }

  void _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inserisci un nome')));
      return;
    }
    if (_isDuplicateName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esiste già una categoria con questo nome'),
        ),
      );
      return;
    }

    if (widget.existing != null) {
      await widget.db.updateCategory(
        widget.existing!.id,
        name,
        _color,
        type: _typeLocked ? null : _type,
        iconKey: _iconKey,
      );
    } else {
      await widget.db.addCategory(name, _type, _color, iconKey: _iconKey);
    }

    if (!mounted) return;
    setState(() {});
    widget.onChanged();
    Navigator.pop(context);
  }

  Future<void> _pickIcon() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) =>
          IconPickerDialog(currentIconKey: _iconKey, isAccount: false),
    );
    if (result != null) {
      setState(() => _iconKey = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewIcon = StreamIconLibrary.getIcon(_iconKey);
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
        final currentExisting = _currentExisting;
        return AlertDialog(
          title: Text(
            currentExisting != null ? 'Modifica categoria' : 'Nuova categoria',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  textInputAction: TextInputAction.done,
                ),
                if (currentExisting == null) ...[
                  const SizedBox(height: 16),
                  SegmentedButton<MovementType>(
                    segments: const [
                      ButtonSegment(
                        value: MovementType.expense,
                        label: Text('Uscita'),
                      ),
                      ButtonSegment(
                        value: MovementType.income,
                        label: Text('Entrata'),
                      ),
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
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: StreamColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _typeLockMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: StreamColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Icona',
                      style: StreamTypography.caption.copyWith(
                        color: StreamColors.textSecondary,
                      ),
                    ),
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
                            Text(
                              StreamIconLibrary.getLabel(_iconKey),
                              style: StreamTypography.caption,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: StreamColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Colore',
                  style: StreamTypography.caption.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ColorPicker(
                  currentColor: _color,
                  onChanged: (c) => setState(() => _color = c),
                ),
                if (currentExisting != null &&
                    _isConvertibleCategory(currentExisting.name)) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('category_convert_to_subcategory_hint'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: StreamColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StreamColors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.merge_type,
                          size: 18,
                          color: StreamColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Questa categoria può essere convertita in sottocategoria.',
                            style: TextStyle(
                              fontSize: 12,
                              color: StreamColors.textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key(
                            'category_convert_to_subcategory_action',
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showConvertDialog(
                              context,
                              widget.db,
                              currentExisting,
                              widget.onChanged,
                            );
                          },
                          child: const Text('Converti'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          key: const Key('category_form_merge_action'),
                          onPressed: () {
                            Navigator.pop(context);
                            _showCategoryMergeDialog(
                              context,
                              widget.db,
                              currentExisting,
                              widget.onChanged,
                            );
                          },
                          child: const Text('Unisci...'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (currentExisting != null) ...[
                  const SizedBox(height: 16),
                  _SubcategorySection(
                    db: widget.db,
                    categoryId: currentExisting.id,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: _save,
              child: Text(currentExisting != null ? 'Salva' : 'Crea'),
            ),
          ],
        );
      },
    );
  }
}

class _SubcategorySection extends StatefulWidget {
  final AppDatabase db;
  final String categoryId;

  const _SubcategorySection({required this.db, required this.categoryId});

  @override
  State<_SubcategorySection> createState() => _SubcategorySectionState();
}

class _SubcategorySectionState extends State<_SubcategorySection> {
  void _addSubcategory() {
    final ctrl = TextEditingController();
    final parentCategory = widget.db.categories
        .where((c) => c.id == widget.categoryId)
        .firstOrNull;
    String iconKey =
        parentCategory?.iconKey ?? StreamIconLibrary.defaultCategoryIcon;
    int color = parentCategory?.color ?? 0xFF42A5F5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuova sottocategoria'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('subcategory_name_field'),
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Nome sottocategoria',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveAndPop(ctrl, iconKey, color),
                ),
                const SizedBox(height: 16),
                _SubcategoryIconColorWidget(
                  iconKey: iconKey,
                  color: color,
                  onIconChanged: (v) => setDialogState(() => iconKey = v),
                  onColorChanged: (v) => setDialogState(() => color = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              key: const Key('subcategory_save_button'),
              onPressed: () => _saveAndPop(ctrl, iconKey, color),
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAndPop(
    TextEditingController ctrl,
    String iconKey,
    int color,
  ) async {
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    await widget.db.createSubcategory(
      widget.categoryId,
      name,
      iconKey: iconKey,
      color: color,
    );
    if (!mounted) return;
    setState(() {});
    Navigator.of(context).pop();
  }

  void _showSubcategoryFormDialog(Subcategory sub) {
    showDialog(
      context: context,
      builder: (ctx) => _SubcategoryFormDialog(
        db: widget.db,
        subcategory: sub,
        onChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
        final fresh = widget.db.getSubcategoriesForCategory(widget.categoryId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sottocategorie (${fresh.length})',
                  style: StreamTypography.caption.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  key: const Key('category_add_subcategory_button'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Aggiungi'),
                  onPressed: _addSubcategory,
                ),
              ],
            ),
            if (fresh.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nessuna sottocategoria',
                  style: StreamTypography.caption.copyWith(
                    color: StreamColors.textMuted,
                  ),
                ),
              )
            else
              ...fresh.map((sub) {
                final parentCat = widget.db.categories.firstWhere(
                  (c) => c.id == widget.categoryId,
                  orElse: () => widget.db.categories.first,
                );
                final subIcon = StreamIconLibrary.getIcon(
                  sub.iconKey ?? parentCat.iconKey,
                );
                final subColor = Color(sub.color ?? parentCat.color);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: subColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(subIcon, size: 14, color: subColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sub.name,
                          style: TextStyle(
                            color: sub.archived ? StreamColors.textMuted : null,
                            decoration: sub.archived
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (!sub.archived)
                        IconButton(
                          key: const Key('subcategory_archive_button'),
                          icon: Icon(
                            Icons.archive_outlined,
                            size: 18,
                            color: StreamColors.textMuted,
                          ),
                          onPressed: () => _archiveSubcategory(sub.id),
                          tooltip: 'Archivia',
                          visualDensity: VisualDensity.compact,
                        ),
                      if (sub.archived)
                        IconButton(
                          key: const Key('subcategory_restore_button'),
                          icon: Icon(
                            Icons.unarchive_outlined,
                            size: 18,
                            color: StreamColors.textMuted,
                          ),
                          onPressed: () => _restoreSubcategory(sub.id),
                          tooltip: 'Ripristina',
                          visualDensity: VisualDensity.compact,
                        ),
                      if (!sub.archived)
                        IconButton(
                          key: const Key('subcategory_merge_action'),
                          icon: Icon(
                            Icons.merge,
                            size: 18,
                            color: StreamColors.textMuted,
                          ),
                          onPressed: () => _showSubcategoryMergeDialog(
                            context,
                            widget.db,
                            sub,
                            () => setState(() {}),
                          ),
                          tooltip: 'Unisci...',
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: StreamColors.textMuted,
                        ),
                        onPressed: () => _showSubcategoryFormDialog(sub),
                        tooltip: 'Modifica',
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        key: const Key('subcategory_delete_button'),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: StreamColors.expense,
                        ),
                        onPressed: () => _confirmDeleteSubcategory(sub),
                        tooltip: 'Elimina',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _archiveSubcategory(String id) async {
    await widget.db.archiveSubcategory(id);
    setState(() {});
  }

  Future<void> _restoreSubcategory(String id) async {
    await widget.db.restoreSubcategory(id);
    setState(() {});
  }

  Future<void> _confirmDeleteSubcategory(Subcategory sub) async {
    final movCount = widget.db.subcategoryMovementCount(sub.id);
    final quickCount = widget.db.subcategoryQuickCount(sub.id);
    final favCount = widget.db.subcategoryFavoriteCount(sub.id);
    final total = movCount + quickCount + favCount;
    final parts = <String>[];
    if (movCount > 0) parts.add('$movCount movimenti');
    if (quickCount > 0) parts.add('$quickCount rapidi');
    if (favCount > 0) parts.add('$favCount preferiti');
    final summary = parts.isEmpty ? '' : ' (${parts.join(', ')})';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare sottocategoria?'),
        content: Text(
          total > 0
              ? 'I movimenti associati$summary verranno spostati nella categoria madre.'
              : 'La sottocategoria "${sub.name}" sarà eliminata definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: StreamColors.expense),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (total > 0) {
      await widget.db.deleteSubcategoryCascade(sub.id);
    } else {
      await widget.db.deleteSubcategory(sub.id);
    }
    setState(() {});
  }
}

class _SubcategoryFormDialog extends StatefulWidget {
  final AppDatabase db;
  final Subcategory subcategory;
  final VoidCallback onChanged;

  const _SubcategoryFormDialog({
    required this.db,
    required this.subcategory,
    required this.onChanged,
  });

  @override
  State<_SubcategoryFormDialog> createState() => _SubcategoryFormDialogState();
}

class _SubcategoryFormDialogState extends State<_SubcategoryFormDialog> {
  late final TextEditingController _nameCtrl;
  late String _iconKey;
  late int _color;

  Subcategory get _sub => widget.subcategory;
  int get _movementCount => widget.db.subcategoryMovementCount(_sub.id);
  int get _quickCount => widget.db.subcategoryQuickCount(_sub.id);
  int get _favoriteCount => widget.db.subcategoryFavoriteCount(_sub.id);
  int get _totalCount => _movementCount + _quickCount + _favoriteCount;

  String _buildMovementSummary() {
    final parts = <String>[];
    if (_movementCount > 0) parts.add('$_movementCount movimenti');
    if (_quickCount > 0) parts.add('$_quickCount rapidi');
    if (_favoriteCount > 0) parts.add('$_favoriteCount preferiti');
    return 'Associato a ${parts.join(', ')}.';
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _sub.name);
    _iconKey = _sub.iconKey ?? StreamIconLibrary.defaultCategoryIcon;
    _color = _sub.color ?? 0xFF42A5F5;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inserisci un nome')));
      return;
    }
    await widget.db.updateSubcategory(
      _sub.id,
      name,
      iconKey: _iconKey,
      color: _color,
    );
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
    Navigator.pop(context);
  }

  Future<void> _confirmDelete({required bool cascade}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare sottocategoria?'),
        content: Text(
          cascade
              ? 'I movimenti associati verranno spostati nella categoria madre.'
              : 'La sottocategoria "${_sub.name}" sarà eliminata definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: StreamColors.expense),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (cascade) {
      await widget.db.deleteSubcategoryCascade(_sub.id);
    } else {
      await widget.db.deleteSubcategory(_sub.id);
    }
    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica sottocategoria'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('subcategory_name_field'),
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
              textInputAction: TextInputAction.done,
            ),
            if (_totalCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: StreamColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildMovementSummary(),
                      style: TextStyle(
                        fontSize: 12,
                        color: StreamColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _SubcategoryIconColorWidget(
              iconKey: _iconKey,
              color: _color,
              onIconChanged: (v) => setState(() => _iconKey = v),
              onColorChanged: (v) => setState(() => _color = v),
            ),
            const SizedBox(height: 16),
            if (_sub.archived) ...[
              FilledButton.tonalIcon(
                key: const Key('subcategory_restore_button'),
                icon: const Icon(Icons.unarchive_outlined, size: 18),
                onPressed: () async {
                  await widget.db.restoreSubcategory(_sub.id);
                  widget.onChanged();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                label: const Text('Ripristina'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('subcategory_delete_button'),
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _confirmDelete(cascade: _totalCount > 0),
                style: TextButton.styleFrom(
                  foregroundColor: StreamColors.expense,
                ),
                label: Text(
                  _totalCount > 0
                      ? 'Elimina (movimenti spostati nella madre)'
                      : 'Elimina',
                ),
              ),
            ] else ...[
              FilledButton.tonalIcon(
                key: const Key('subcategory_archive_button'),
                icon: const Icon(Icons.archive_outlined, size: 18),
                onPressed: () async {
                  await widget.db.archiveSubcategory(_sub.id);
                  widget.onChanged();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                label: const Text('Archivia'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('subcategory_delete_button'),
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _confirmDelete(cascade: _totalCount > 0),
                style: TextButton.styleFrom(
                  foregroundColor: StreamColors.expense,
                ),
                label: Text(
                  _totalCount > 0
                      ? 'Elimina (movimenti spostati nella madre)'
                      : 'Elimina',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salva')),
      ],
    );
  }
}

class _SubcategoryIconColorWidget extends StatelessWidget {
  final String iconKey;
  final int color;
  final ValueChanged<String> onIconChanged;
  final ValueChanged<int> onColorChanged;

  const _SubcategoryIconColorWidget({
    required this.iconKey,
    required this.color,
    required this.onIconChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final previewIcon = StreamIconLibrary.getIcon(iconKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Icona',
              style: StreamTypography.caption.copyWith(
                color: StreamColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (_) => IconPickerDialog(
                    currentIconKey: iconKey,
                    isAccount: false,
                  ),
                );
                if (result != null) onIconChanged(result);
              },
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
                    Text(
                      StreamIconLibrary.getLabel(iconKey),
                      style: StreamTypography.caption,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: StreamColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Colore',
          style: StreamTypography.caption.copyWith(
            color: StreamColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ColorPicker(currentColor: color, onChanged: onColorChanged),
      ],
    );
  }
}

class _CategoryMovementsSheet extends StatefulWidget {
  final AppDatabase db;
  final Category category;
  final TimeFilter? initialFilter;

  const _CategoryMovementsSheet({
    required this.db,
    required this.category,
    this.initialFilter,
  });

  @override
  State<_CategoryMovementsSheet> createState() =>
      _CategoryMovementsSheetState();
}

class _CategoryMovementsSheetState extends State<_CategoryMovementsSheet> {
  late TimeFilter _filter;

  Category get _category {
    return widget.db.categories.firstWhere(
      (c) => c.id == widget.category.id,
      orElse: () => widget.category,
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = widget.initialFilter ?? TimeFilter.month(now.year, now.month);
  }

  List<Movement> get _categoryMovements {
    final category = _category;
    return widget.db.movements
        .where(
          (m) =>
              m.categoryId == category.id &&
              m.type == category.type &&
              !m.isTransfer,
        )
        .toList()
        .filterByTime(_filter);
  }

  double get _periodTotal {
    return _categoryMovements.fold<double>(0.0, (sum, m) => sum + m.amount);
  }

  String get _totalLabel => widget.category.type == MovementType.income
      ? 'Totale entrate'
      : 'Totale spese';

  void _showAddMovement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MovementPicker(
        db: widget.db,
        categoryPreFill: _category.id,
        initialType: _category.type,
      ),
    );
  }

  void _showEditCategory() {
    showDialog(
      context: context,
      builder: (_) => _CategoryFormDialog(
        db: widget.db,
        existing: _category,
        onChanged: () => setState(() {}),
      ),
    );
  }

  Future<void> _toggleArchive() async {
    final category = _category;
    if (category.archived) {
      await widget.db.restoreCategory(category.id);
    } else {
      await widget.db.archiveCategory(category.id);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
        final category = _category;
        final movements = _categoryMovements;
        final hasMovements = movements.isNotEmpty;
        final iconData = StreamIconLibrary.getIcon(category.iconKey);
        final typeLabel = category.type == MovementType.income
            ? 'Entrata'
            : 'Uscita';

        return FractionallySizedBox(
          heightFactor: 1.0,
          child: Padding(
            key: const Key('category_interactive_sheet'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: const Key('category_sheet_header'),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Color(category.color),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(iconData, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Movimenti categoria',
                              style: StreamTypography.captionBold.copyWith(
                                color: StreamColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              category.name,
                              key: const Key('category_movements_name'),
                              style: StreamTypography.h2,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$typeLabel • ${category.archived ? 'Archiviata' : 'Attiva'}',
                              style: StreamTypography.caption.copyWith(
                                color: StreamColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('category_movements_close_button'),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: const Key('category_sheet_period_summary'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      KeyedSubtree(
                        key: const Key('category_movements_total'),
                        child: _StatChip(
                          label: _totalLabel,
                          value: _formatMoney(_periodTotal),
                          key: const Key('category_sheet_total'),
                          labelKey: const Key(
                            'category_sheet_type_total_label',
                          ),
                          valueKey: const Key('category_sheet_type_total'),
                        ),
                      ),
                      KeyedSubtree(
                        key: const Key('category_movements_count'),
                        child: _StatChip(
                          label: 'Movimenti',
                          value: '${movements.length}',
                          key: const Key('category_sheet_movement_count'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SheetActionButton(
                      key: const Key('category_sheet_add_movement_action'),
                      icon: Icons.add,
                      label: 'Movimento',
                      onPressed: _showAddMovement,
                    ),
                    _SheetActionButton(
                      key: const Key('category_sheet_edit_action'),
                      icon: Icons.edit,
                      label: 'Modifica',
                      onPressed: _showEditCategory,
                    ),
                    _SheetActionButton(
                      key: const Key('category_sheet_archive_action'),
                      icon: category.archived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      label: category.archived ? 'Ripristina' : 'Archivia',
                      onPressed: _toggleArchive,
                    ),
                    if (!category.archived &&
                        _isConvertibleCategory(category.name))
                      _SheetActionButton(
                        key: const Key('category_sheet_convert_action'),
                        icon: Icons.merge_type,
                        label: 'Converti',
                        onPressed: () => _showConvertDialog(
                          context,
                          widget.db,
                          category,
                          () => setState(() {}),
                        ),
                      ),
                    if (!category.archived)
                      _SheetActionButton(
                        key: const Key('category_sheet_merge_action'),
                        icon: Icons.merge,
                        label: 'Unisci...',
                        onPressed: () => _showCategoryMergeDialog(
                          context,
                          widget.db,
                          category,
                          () => setState(() {}),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: const Key('category_movements_time_filter'),
                  child: TimeFilterBar(
                    activeFilter: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  key: const Key('category_sheet_movements_list'),
                  child: hasMovements
                      ? GroupedMovementsList(
                          movements: movements,
                          db: widget.db,
                          showNotes: true,
                          filterType: category.type,
                          onEdit: (m) => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                MovementPicker(db: widget.db, prefill: m),
                          ),
                          onDuplicate: (m) async {
                            final date = await showDuplicateDateSheet(context);
                            if (date != null)
                              widget.db.duplicateMovement(m, date: date);
                          },
                          onSaveAsFavorite: (m) =>
                              widget.db.saveMovementAsFavorite(m),
                          onAddQuick: (m) => widget.db.saveMovementAsQuick(m),
                          onDelete: (m) => widget.db.deleteMovement(m.id),
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
        );
      },
    );
  }

  String _formatMoney(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} €';
}

class _SheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SheetActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Key? labelKey;
  final Key? valueKey;

  const _StatChip({
    super.key,
    required this.label,
    required this.value,
    this.labelKey,
    this.valueKey,
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
            key: labelKey,
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            key: valueKey,
            style: StreamTypography.amount.copyWith(
              color: StreamColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

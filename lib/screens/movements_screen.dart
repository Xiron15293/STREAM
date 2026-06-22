import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_theme_extension.dart';
import '../design/stream_theme_palette.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/duplicate_date_selector.dart';
import '../utils/filter_ux_copy.dart';
import '../utils/movement_search.dart';
import 'heatmap_settings_screen.dart';
import '../widgets/movement_picker.dart';
import '../widgets/movement_view_renderer.dart';
import '../widgets/time_filter_bar.dart';

class MovementsScreen extends StatefulWidget {
  final AppDatabase db;
  final String? activeProfileId;
  final DateTime Function()? timeFilterNowProvider;

  const MovementsScreen({
    super.key,
    required this.db,
    this.activeProfileId,
    this.timeFilterNowProvider,
  });

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late TimeFilter _activeFilter;
  String _searchQuery = '';
  DateTime? _selectedDay;
  DateTime? _selectedPeriodDay;
  late DateTime _visibleCalendarMonth;
  DateTime? _lastPickedDate;
  MovementType? _dayFilter;
  late final VoidCallback _showNotesListener;
  Set<String>? _selectedAccountFilterIds;
  Set<String>? _selectedCategoryFilterIds;
  bool _filtersSyncInProgress = false;

  @override
  void initState() {
    super.initState();
    final now = _now();
    _activeFilter = TimeFilter.month(now.year, now.month);
    _selectedDay = now;
    _visibleCalendarMonth = DateTime(now.year, now.month, 1);
    PreferencesService.loadShowNotes();
    PreferencesService.loadHeatmapSettings();
    _showNotesListener = () {
      if (mounted) setState(() {});
    };
    PreferencesService.showNotesNotifier.addListener(_showNotesListener);
    _loadScopedFilters();
  }

  DateTime _now() => widget.timeFilterNowProvider?.call() ?? DateTime.now();

  @override
  void didUpdateWidget(covariant MovementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProfileId != widget.activeProfileId) {
      _loadScopedFilters();
    }
  }

  @override
  void dispose() {
    PreferencesService.showNotesNotifier.removeListener(_showNotesListener);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleShowNotes(bool value) async {
    await PreferencesService.saveShowNotes(value);
  }

  Future<void> _loadScopedFilters() async {
    final profileId = widget.activeProfileId?.trim();
    if (profileId == null || profileId.isEmpty) {
      if (mounted) {
        setState(() {
          _selectedAccountFilterIds = null;
          _selectedCategoryFilterIds = null;
        });
      }
      PreferencesService.movementsAccountFilterIdsNotifier.value = null;
      PreferencesService.movementsCategoryFilterIdsNotifier.value = null;
      return;
    }

    final accountIds = await PreferencesService.loadMovementsAccountFilterIds(
      profileId: profileId,
    );
    final categoryIds = await PreferencesService.loadMovementsCategoryFilterIds(
      profileId: profileId,
    );
    await _applySanitizedFilters(
      profileId: profileId,
      accountIds: accountIds,
      categoryIds: categoryIds,
    );
  }

  Future<void> _applySanitizedFilters({
    required String profileId,
    Set<String>? accountIds,
    Set<String>? categoryIds,
  }) async {
    if (_filtersSyncInProgress) return;
    _filtersSyncInProgress = true;
    final activeAccountIds = widget.db.accounts
        .where((account) => !account.archived)
        .map((account) => account.id)
        .toSet();
    final activeCategoryIds = widget.db.categories
        .where((category) => !category.archived)
        .map((category) => category.id)
        .toSet();

    final sanitizedAccountIds = accountIds == null || accountIds.isEmpty
        ? accountIds
        : accountIds.intersection(activeAccountIds);
    final normalizedAccountIds = sanitizedAccountIds;

    final sanitizedCategoryIds = categoryIds == null || categoryIds.isEmpty
        ? categoryIds
        : categoryIds.intersection(activeCategoryIds);
    final normalizedCategoryIds = sanitizedCategoryIds;

    try {
      if (!_sameIdSet(accountIds, normalizedAccountIds)) {
        await PreferencesService.saveMovementsAccountFilterIds(
          normalizedAccountIds,
          profileId: profileId,
        );
      }

      if (!_sameIdSet(categoryIds, normalizedCategoryIds)) {
        await PreferencesService.saveMovementsCategoryFilterIds(
          normalizedCategoryIds,
          profileId: profileId,
        );
      }

      if (mounted) {
        setState(() {
          _selectedAccountFilterIds = normalizedAccountIds;
          _selectedCategoryFilterIds = normalizedCategoryIds;
        });
      }
    } finally {
      _filtersSyncInProgress = false;
    }
  }

  bool _sameIdSet(Set<String>? a, Set<String>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.isEmpty || b.isEmpty) return a.isEmpty && b.isEmpty;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  List<Movement> _applyMovementScopedFilters(List<Movement> movements) {
    return movements.where((movement) {
      final matchesAccount =
          _selectedAccountFilterIds == null ||
          _selectedAccountFilterIds!.contains(movement.accountId) ||
          (movement.destinationAccountId != null &&
              _selectedAccountFilterIds!.contains(
                movement.destinationAccountId,
              ));

      if (!matchesAccount) return false;

      if (_selectedCategoryFilterIds == null) {
        return true;
      }

      if (movement.isTransfer) {
        return movement.categoryId.isNotEmpty &&
            _selectedCategoryFilterIds!.contains(movement.categoryId);
      }

      return _selectedCategoryFilterIds!.contains(movement.categoryId);
    }).toList();
  }

  String _accountFilterLabel() {
    final activeAccounts = widget.db.accounts
        .where((account) => !account.archived)
        .toList();
    final selected = _selectedAccountFilterIds == null
        ? <String>[]
        : activeAccounts
              .where(
                (account) => _selectedAccountFilterIds!.contains(account.id),
              )
              .map((account) => account.id)
              .toList();
    if (_selectedAccountFilterIds == null ||
        selected.length == activeAccounts.length) {
      return 'Tutti i conti';
    }
    if (_selectedAccountFilterIds!.isEmpty) return 'Nessun conto';
    if (selected.length == 1) {
      final name = activeAccounts
          .firstWhere((account) => account.id == selected.first)
          .name;
      return name.length <= 20 ? name : '1 conto selezionato';
    }
    return '${selected.length} conti selezionati';
  }

  List<Category> _expenseCategories(List<Category> categories) =>
      categories.where((c) => c.type == MovementType.expense).toList();

  List<Category> _incomeCategories(List<Category> categories) =>
      categories.where((c) => c.type == MovementType.income).toList();

  Widget _buildCategoryOption(
    Category category,
    Set<String> workingIds,
    void Function(VoidCallback) setSheetState,
    StreamThemePalette palette,
  ) {
    final isSelected = workingIds.contains(category.id);
    return InkWell(
      key: Key('movements_category_filter_option_${category.id}'),
      onTap: () {
        setSheetState(() {
          if (isSelected) {
            workingIds.remove(category.id);
          } else {
            workingIds.add(category.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: palette.primary,
              size: 22,
            ),
            const SizedBox(width: StreamSpacing.md),
            Expanded(
              child: Text(
                category.name,
                style: StreamTypography.bodyBold,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryFilterLabel() {
    final activeCategories = widget.db.categories
        .where((category) => !category.archived)
        .toList();
    final selected = _selectedCategoryFilterIds == null
        ? <String>[]
        : activeCategories
              .where(
                (category) => _selectedCategoryFilterIds!.contains(category.id),
              )
              .map((category) => category.id)
              .toList();
    if (_selectedCategoryFilterIds == null ||
        selected.length == activeCategories.length) {
      return 'Tutte le categorie';
    }
    if (_selectedCategoryFilterIds!.isEmpty) return 'Nessuna categoria';
    if (selected.length == 1) {
      final name = activeCategories
          .firstWhere((category) => category.id == selected.first)
          .name;
      return name.length <= 20 ? name : '1 categoria selezionata';
    }
    return '${selected.length} categorie selezionate';
  }

  Future<void> _showAccountFilterSheet(BuildContext context) async {
    final profileId = widget.activeProfileId?.trim();
    if (profileId == null || profileId.isEmpty) return;
    final p = context.$palette;
    final activeAccounts = widget.db.accounts
        .where((account) => !account.archived)
        .toList();
    Set<String> workingIds = Set.from(
      _selectedAccountFilterIds ?? activeAccounts.map((account) => account.id),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: StreamSpacing.lg,
                  right: StreamSpacing.lg,
                  top: StreamSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      StreamSpacing.lg,
                ),
                child: Column(
                  key: const Key('movements_account_filter_sheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Conti', style: StreamTypography.h3),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: StreamSpacing.xs),
                    Text(
                      FilterUxCopy.accountToggleHint,
                      style: StreamTypography.caption.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                    const SizedBox(height: StreamSpacing.md),
                    InkWell(
                      key: const Key('movements_account_filter_all_option'),
                      onTap: () {
                        setSheetState(() {
                          if (workingIds.length == activeAccounts.length) {
                            workingIds = <String>{};
                          } else {
                            workingIds = activeAccounts
                                .map((account) => account.id)
                                .toSet();
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              workingIds.length == activeAccounts.length
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: p.primary,
                              size: 22,
                            ),
                            const SizedBox(width: StreamSpacing.md),
                            Text(
                              'Tutti i conti',
                              style: StreamTypography.bodyBold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: activeAccounts.map((account) {
                            final isSelected = workingIds.contains(account.id);
                            return InkWell(
                              key: Key(
                                'movements_account_filter_option_${account.id}',
                              ),
                              onTap: () {
                                setSheetState(() {
                                  if (isSelected) {
                                    workingIds.remove(account.id);
                                  } else {
                                    workingIds.add(account.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: p.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: StreamSpacing.md),
                                    Expanded(
                                      child: Text(
                                        account.name,
                                        style: StreamTypography.bodyBold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: StreamSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('movements_account_filter_cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: FilledButton(
                            key: const Key('movements_account_filter_apply'),
                            onPressed: () async {
                              final finalIds =
                                  workingIds.length == activeAccounts.length
                                  ? null
                                  : workingIds;
                              await PreferencesService.saveMovementsAccountFilterIds(
                                finalIds,
                                profileId: profileId,
                              );
                              await _applySanitizedFilters(
                                profileId: profileId,
                                accountIds: finalIds,
                                categoryIds: _selectedCategoryFilterIds,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Applica'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCategoryFilterSheet(BuildContext context) async {
    final profileId = widget.activeProfileId?.trim();
    if (profileId == null || profileId.isEmpty) return;
    final p = context.$palette;
    final activeCategories = widget.db.categories
        .where((category) => !category.archived)
        .toList();
    final expenseCategories = _expenseCategories(activeCategories);
    final incomeCategories = _incomeCategories(activeCategories);
    Set<String> workingIds = Set.from(
      _selectedCategoryFilterIds ??
          activeCategories.map((category) => category.id),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: StreamSpacing.lg,
                  right: StreamSpacing.lg,
                  top: StreamSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      StreamSpacing.lg,
                ),
                child: Column(
                  key: const Key('movements_category_filter_sheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Categorie', style: StreamTypography.h3),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: StreamSpacing.xs),
                    Text(
                      FilterUxCopy.categoryToggleHint,
                      style: StreamTypography.caption.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                    const SizedBox(height: StreamSpacing.md),
                    InkWell(
                      key: const Key('movements_category_filter_all_option'),
                      onTap: () {
                        setSheetState(() {
                          if (workingIds.length == activeCategories.length) {
                            workingIds = <String>{};
                          } else {
                            workingIds = activeCategories
                                .map((category) => category.id)
                                .toSet();
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              workingIds.length == activeCategories.length
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: p.primary,
                              size: 22,
                            ),
                            const SizedBox(width: StreamSpacing.md),
                            Text(
                              'Tutte le categorie',
                              style: StreamTypography.bodyBold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (expenseCategories.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 4,
                                ),
                                child: Text(
                                  'Uscite',
                                  style: StreamTypography.h3,
                                ),
                              ),
                              ...expenseCategories.map(
                                (c) => _buildCategoryOption(
                                  c,
                                  workingIds,
                                  setSheetState,
                                  p,
                                ),
                              ),
                            ],
                            if (incomeCategories.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 4,
                                ),
                                child: Text(
                                  'Entrate',
                                  style: StreamTypography.h3,
                                ),
                              ),
                              ...incomeCategories.map(
                                (c) => _buildCategoryOption(
                                  c,
                                  workingIds,
                                  setSheetState,
                                  p,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: StreamSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('movements_category_filter_cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: FilledButton(
                            key: const Key('movements_category_filter_apply'),
                            onPressed: () async {
                              final finalIds =
                                  workingIds.length == activeCategories.length
                                  ? null
                                  : workingIds;
                              await PreferencesService.saveMovementsCategoryFilterIds(
                                finalIds,
                                profileId: profileId,
                              );
                              await _applySanitizedFilters(
                                profileId: profileId,
                                accountIds: _selectedAccountFilterIds,
                                categoryIds: finalIds,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Applica'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    final p = context.$palette;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(
            StreamSpacing.lg,
            StreamSpacing.lg,
            StreamSpacing.lg,
            StreamSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Impostazioni lista',
                    style: StreamTypography.h3.copyWith(color: p.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: p.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: StreamSpacing.md),
              ValueListenableBuilder<bool>(
                valueListenable: PreferencesService.showNotesNotifier,
                builder: (context, showNotes, _) => SwitchListTile(
                  title: const Text('Mostra note nei movimenti'),
                  subtitle: const Text(
                    'Visualizza la nota sotto ogni movimento nella lista',
                  ),
                  value: showNotes,
                  onChanged: (value) {
                    setSheetState(() {});
                    _toggleShowNotes(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        title: const Text('Movimenti'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: PreferencesService.showNotesNotifier,
            builder: (context, showNotes, _) => IconButton(
              icon: Icon(
                Icons.tune,
                color: showNotes ? p.primary : p.textMuted,
              ),
              tooltip: 'Impostazioni lista',
              onPressed: () => _showSettings(context),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          final profileId = widget.activeProfileId?.trim();
          if (!_filtersSyncInProgress &&
              profileId != null &&
              profileId.isNotEmpty) {
            final activeAccountIds = widget.db.accounts
                .where((account) => !account.archived)
                .map((account) => account.id)
                .toSet();
            final activeCategoryIds = widget.db.categories
                .where((category) => !category.archived)
                .map((category) => category.id)
                .toSet();
            final accountNeedsSanitize =
                _selectedAccountFilterIds != null &&
                !_selectedAccountFilterIds!.every(activeAccountIds.contains);
            final categoryNeedsSanitize =
                _selectedCategoryFilterIds != null &&
                !_selectedCategoryFilterIds!.every(activeCategoryIds.contains);
            if (accountNeedsSanitize || categoryNeedsSanitize) {
              Future.microtask(
                () => _applySanitizedFilters(
                  profileId: profileId,
                  accountIds: _selectedAccountFilterIds,
                  categoryIds: _selectedCategoryFilterIds,
                ),
              );
            }
          }
          final allMovements = widget.db.movements;
          final rawPeriodFilteredMovements = allMovements.filterByTime(
            _activeFilter,
          );
          final searchFilteredMovements = searchMovements(
            movements: allMovements,
            query: _searchQuery,
            filter: _activeFilter,
            categories: widget.db.categories,
            accounts: widget.db.accounts,
          );
          final scopedSearchFilteredMovements = _applyMovementScopedFilters(
            searchFilteredMovements,
          );
          final hasQuery = _searchQuery.trim().isNotEmpty;

          Widget body;
          if (allMovements.isEmpty) {
            body = _buildEmptyAll(context);
          } else if (_selectedAccountFilterIds != null &&
              _selectedAccountFilterIds!.isEmpty) {
            body = _buildEmptySelection(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: FilterUxCopy.noAccountSelectedTitle,
              subtitle: FilterUxCopy.noAccountSelectedSubtitle,
            );
          } else if (_selectedCategoryFilterIds != null &&
              _selectedCategoryFilterIds!.isEmpty) {
            body = _buildEmptySelection(
              context,
              icon: Icons.category_outlined,
              title: FilterUxCopy.noCategorySelectedTitle,
              subtitle: FilterUxCopy.noCategorySelectedSubtitle,
            );
          } else {
            if (scopedSearchFilteredMovements.isEmpty) {
              body = hasQuery
                  ? _buildEmptySearch(context)
                  : rawPeriodFilteredMovements.isEmpty
                  ? _buildEmptyPeriod(context)
                  : MovementViewRenderer(
                      timeFilter: _activeFilter,
                      movements: scopedSearchFilteredMovements,
                      periodMovements: rawPeriodFilteredMovements,
                      db: widget.db,
                      showNotes:
                          PreferencesService.showNotesNotifier.value ||
                          _searchQuery.trim().isNotEmpty,
                      hasQuery: hasQuery,
                      selectedDay: _selectedDay,
                      selectedPeriodDay: _selectedPeriodDay,
                      onDaySelected: _onHeatmapDayTap,
                      onClearSelectedDay: _clearSelectedPeriodDay,
                      dayFilter: _dayFilter,
                      onDayFilterChanged: (MovementType? type) =>
                          setState(() => _dayFilter = type),
                      onEdit: (movement) =>
                          _showPicker(context, prefill: movement),
                      onDuplicate: (movement) async {
                        final date = await showDuplicateDateSheet(context);
                        if (date != null) {
                          widget.db.duplicateMovement(movement, date: date);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Movimento duplicato'),
                              ),
                            );
                          }
                        }
                      },
                      onSaveAsFavorite: (movement) {
                        widget.db.saveMovementAsFavorite(movement);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Salvato nei preferiti'),
                          ),
                        );
                      },
                      onAddQuick: (movement) {
                        widget.db.saveMovementAsQuick(movement);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Salvato nei rapidi')),
                        );
                      },
                      onDelete: (movement) {
                        widget.db.deleteMovement(movement.id);
                      },
                    );
            } else {
              body = MovementViewRenderer(
                timeFilter: _activeFilter,
                movements: scopedSearchFilteredMovements,
                periodMovements: rawPeriodFilteredMovements,
                db: widget.db,
                showNotes:
                    PreferencesService.showNotesNotifier.value ||
                    _searchQuery.trim().isNotEmpty,
                hasQuery: hasQuery,
                selectedDay: _selectedDay,
                selectedPeriodDay: _selectedPeriodDay,
                onDaySelected: _onHeatmapDayTap,
                onClearSelectedDay: _clearSelectedPeriodDay,
                dayFilter: _dayFilter,
                onDayFilterChanged: (MovementType? type) =>
                    setState(() => _dayFilter = type),
                onEdit: (movement) => _showPicker(context, prefill: movement),
                onDuplicate: (movement) async {
                  final date = await showDuplicateDateSheet(context);
                  if (date != null) {
                    widget.db.duplicateMovement(movement, date: date);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Movimento duplicato')),
                      );
                    }
                  }
                },
                onSaveAsFavorite: (movement) {
                  widget.db.saveMovementAsFavorite(movement);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Salvato nei preferiti')),
                  );
                },
                onAddQuick: (movement) {
                  widget.db.saveMovementAsQuick(movement);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Salvato nei rapidi')),
                  );
                },
                onDelete: (movement) {
                  widget.db.deleteMovement(movement.id);
                },
              );
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StreamSpacing.lg,
                  0,
                  StreamSpacing.lg,
                  0,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Cerca titolo, nota, categoria o conto',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Pulisci ricerca',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                  ),
                ),
              ),
              TimeFilterBar(
                activeFilter: _activeFilter,
                onChanged: _setActiveFilter,
                onDatePicked: _rememberPickedDate,
                nowProvider: widget.timeFilterNowProvider,
              ),
              Padding(
                key: const Key('movements_filters_section'),
                padding: const EdgeInsets.fromLTRB(
                  StreamSpacing.lg,
                  StreamSpacing.sm,
                  StreamSpacing.lg,
                  StreamSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtri',
                      style: StreamTypography.bodyBold.copyWith(
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: StreamSpacing.sm),
                    Wrap(
                      spacing: StreamSpacing.sm,
                      runSpacing: StreamSpacing.sm,
                      children: [
                        ActionChip(
                          key: const Key('movements_account_filter_button'),
                          avatar: const Icon(Icons.account_balance, size: 18),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              _accountFilterLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onPressed: () => _showAccountFilterSheet(context),
                        ),
                        ActionChip(
                          key: const Key('movements_category_filter_button'),
                          avatar: const Icon(Icons.category, size: 18),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              _categoryFilterLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onPressed: () => _showCategoryFilterSheet(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_activeFilter.mode == TimeFilterMode.day)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StreamSpacing.lg,
                    0,
                    StreamSpacing.lg,
                    StreamSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('movements_day_configure_heatmap_button'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HeatmapSettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Configura heatmap'),
                    ),
                  ),
                ),
              Expanded(child: body),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'movements_fab',
        onPressed: () => _showPicker(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void _rememberPickedDate(DateTime date) {
    _lastPickedDate = DateTime(date.year, date.month, date.day);
  }

  void _onHeatmapDayTap(DateTime day) {
    setState(() {
      switch (_activeFilter.mode) {
        case TimeFilterMode.day:
          _selectedDay = day;
          _activeFilter = TimeFilter.day(day);
          _visibleCalendarMonth = DateTime(day.year, day.month, 1);
        case TimeFilterMode.week:
        case TimeFilterMode.month:
        case TimeFilterMode.year:
        case TimeFilterMode.customRange:
          _selectedPeriodDay = day;
      }
    });
  }

  void _clearSelectedPeriodDay() {
    setState(() => _selectedPeriodDay = null);
  }

  void _setActiveFilter(TimeFilter filter) {
    setState(() {
      _selectedPeriodDay = null;
      final pickedDate = _lastPickedDate;
      _lastPickedDate = null;
      _activeFilter = filter;
      final anchor = _anchorDateForFilter(filter, pickedDate: pickedDate);
      _visibleCalendarMonth = DateTime(anchor.year, anchor.month, 1);
      _selectedDay = _clampSelectedDay(anchor, filter);
      _dayFilter = null;
    });
  }

  DateTime _anchorDateForFilter(TimeFilter filter, {DateTime? pickedDate}) {
    if (pickedDate != null && filter.contains(pickedDate)) {
      return DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
    }

    final currentSelected = _selectedDay;
    if (currentSelected != null && filter.contains(currentSelected)) {
      return DateTime(
        currentSelected.year,
        currentSelected.month,
        currentSelected.day,
      );
    }

    if (filter.mode == TimeFilterMode.year &&
        _visibleCalendarMonth.year == filter.startDate.year) {
      return DateTime(
        _visibleCalendarMonth.year,
        _visibleCalendarMonth.month,
        1,
      );
    }

    return DateTime(
      filter.startDate.year,
      filter.startDate.month,
      filter.startDate.day,
    );
  }

  DateTime _clampSelectedDay(DateTime date, TimeFilter filter) {
    switch (filter.mode) {
      case TimeFilterMode.day:
        return DateTime(
          filter.startDate.year,
          filter.startDate.month,
          filter.startDate.day,
        );
      case TimeFilterMode.week:
      case TimeFilterMode.month:
      case TimeFilterMode.year:
      case TimeFilterMode.customRange:
        final day = date.day.clamp(
          1,
          DateTime(date.year, date.month + 1, 0).day,
        );
        final clamped = DateTime(date.year, date.month, day);
        if (filter.contains(clamped)) return clamped;
        return DateTime(
          filter.startDate.year,
          filter.startDate.month,
          filter.startDate.day,
        );
    }
  }

  void _showPicker(BuildContext context, {Movement? prefill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovementPicker(db: widget.db, prefill: prefill),
    );
  }

  Widget _buildEmptyAll(BuildContext context) {
    final p = context.$palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: p.textMuted),
          const SizedBox(height: StreamSpacing.lg),
          const Text('Nessun movimento', style: StreamTypography.h2),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            'Tocca + per aggiungerne uno',
            style: StreamTypography.body.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPeriod(BuildContext context) {
    final p = context.$palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 64, color: p.textMuted),
          const SizedBox(height: StreamSpacing.lg),
          const Text(FilterUxCopy.noMovementsTitle, style: StreamTypography.h2),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            FilterUxCopy.noMovementsSubtitle,
            style: StreamTypography.body.copyWith(color: p.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySelection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final p = context.$palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: p.textMuted),
            const SizedBox(height: StreamSpacing.lg),
            Text(
              title,
              style: StreamTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StreamSpacing.sm),
            Text(
              subtitle,
              style: StreamTypography.body.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch(BuildContext context) {
    final p = context.$palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: p.textMuted),
          const SizedBox(height: StreamSpacing.lg),
          const Text('Nessun risultato', style: StreamTypography.h2),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            'Prova con un termine diverso o cambia periodo',
            style: StreamTypography.body.copyWith(color: p.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

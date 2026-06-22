import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../design/stream_icon_library.dart';
import '../models/beneficiary_profile.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../theme.dart';
import '../util/beneficiary_helpers.dart';
import '../utils/currency_formatter.dart';
import '../widgets/grouped_movements_list.dart';
import '../widgets/stream_kpi_card.dart';

class BeneficiariesScreen extends StatefulWidget {
  final AppDatabase db;
  final bool pickerMode;
  final String? initialQuery;
  final ValueChanged<String>? onBeneficiarySelected;
  final String? activeProfileId;

  const BeneficiariesScreen({
    super.key,
    required this.db,
    this.pickerMode = false,
    this.initialQuery,
    this.onBeneficiarySelected,
    this.activeProfileId,
  });

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  late final TextEditingController _searchCtrl;
  Set<String>? _selectedAccountFilterIds;
  Set<String>? _selectedCategoryFilterIds;
  bool _filtersSyncInProgress = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _searchCtrl.addListener(() => setState(() {}));
    _loadScopedFilters();
  }

  @override
  void didUpdateWidget(covariant BeneficiariesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProfileId != widget.activeProfileId) {
      _loadScopedFilters();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
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

        final p = context.$palette;
        final hasProfileScope = profileId != null && profileId.isNotEmpty;
        final allEntries = _buildEntries();
        final query = BeneficiaryProfile.normalizeKey(_searchCtrl.text);
        final filtered = query.isEmpty
            ? allEntries
            : allEntries.where((entry) {
                return entry.searchKey.contains(query) ||
                    BeneficiaryProfile.normalizeKey(
                      entry.displayName,
                    ).contains(query);
              }).toList();
        final grouped = _groupEntries(filtered);

        final content = SafeArea(
          top: true,
          bottom: true,
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StreamSpacing.lg,
                  StreamSpacing.md,
                  StreamSpacing.lg,
                  0,
                ),
                child: TextField(
                  key: const Key('beneficiaries_search_field'),
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Cerca',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              if (!widget.pickerMode && hasProfileScope) ...[
                Padding(
                  key: const Key('beneficiaries_filters_section'),
                  padding: const EdgeInsets.fromLTRB(
                    StreamSpacing.lg,
                    StreamSpacing.md,
                    StreamSpacing.lg,
                    0,
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
                            key: const Key(
                              'beneficiaries_account_filter_button',
                            ),
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
                            key: const Key(
                              'beneficiaries_category_filter_button',
                            ),
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
                const SizedBox(height: StreamSpacing.md),
              ] else
                const SizedBox(height: StreamSpacing.md),
              Expanded(
                child: filtered.isEmpty
                    ? _BeneficiariesEmptyState(hasQuery: query.isNotEmpty)
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          StreamSpacing.lg,
                          0,
                          StreamSpacing.lg,
                          widget.pickerMode ? 16 : 80,
                        ),
                        itemCount: grouped.length + 1,
                        itemBuilder: (context, index) {
                          if (index == grouped.length) {
                            return const SizedBox(height: StreamSpacing.sm);
                          }
                          final section = grouped[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: StreamSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: StreamSpacing.sm,
                                    left: StreamSpacing.xs,
                                  ),
                                  child: Text(
                                    section.letter,
                                    key: Key(
                                      'beneficiary_section_${section.letter}',
                                    ),
                                    style: StreamTypography.caption.copyWith(
                                      color: p.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                ...section.entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: StreamSpacing.sm,
                                    ),
                                    child: _BeneficiaryCard(
                                      entry: entry,
                                      selectable: widget.pickerMode,
                                      onTap: () => widget.pickerMode
                                          ? widget.onBeneficiarySelected?.call(
                                              entry.displayName,
                                            )
                                          : _showBeneficiaryDetail(
                                              context,
                                              entry,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (widget.pickerMode) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StreamSpacing.lg,
                    0,
                    StreamSpacing.lg,
                    StreamSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('beneficiaries_picker_close'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                      const SizedBox(width: StreamSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          key: const Key('beneficiaries_picker_done'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fatto'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StreamSpacing.lg,
                    0,
                    StreamSpacing.lg,
                    StreamSpacing.lg,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filled(
                      key: const Key('beneficiaries_add_button'),
                      onPressed: () =>
                          showCreateBeneficiaryDialog(context, widget.db),
                      icon: const Icon(Icons.add),
                      tooltip: 'Nuovo beneficiario',
                    ),
                  ),
                ),
            ],
          ),
        );

        if (!widget.pickerMode) {
          return Scaffold(
            backgroundColor: p.canvas,
            appBar: AppBar(title: const Text('Beneficiari')),
            body: content,
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: p.canvas,
            borderRadius: widget.pickerMode
                ? const BorderRadius.vertical(
                    top: Radius.circular(StreamRadius.xl),
                  )
                : BorderRadius.zero,
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (!widget.pickerMode) return const SizedBox.shrink();
    final p = context.$palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StreamSpacing.lg,
        StreamSpacing.md,
        StreamSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Beneficiari',
              style: StreamTypography.h3.copyWith(color: p.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            key: const Key('beneficiaries_picker_close_top'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
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
      PreferencesService.beneficiariesAccountFilterIdsNotifier.value = null;
      PreferencesService.beneficiariesCategoryFilterIdsNotifier.value = null;
      return;
    }

    final accountIds =
        await PreferencesService.loadBeneficiariesAccountFilterIds(
          profileId: profileId,
        );
    final categoryIds =
        await PreferencesService.loadBeneficiariesCategoryFilterIds(
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
        .map((account) => account.id);
    final activeCategoryIds = widget.db.categories
        .where((category) => !category.archived)
        .map((category) => category.id);

    final normalizedAccountIds = PreferencesService.normalizeScopedFilterIds(
      accountIds,
      activeAccountIds,
    );
    final normalizedCategoryIds = PreferencesService.normalizeScopedFilterIds(
      categoryIds,
      activeCategoryIds,
    );

    try {
      if (!_sameIdSet(accountIds, normalizedAccountIds)) {
        await PreferencesService.saveBeneficiariesAccountFilterIds(
          normalizedAccountIds,
          profileId: profileId,
        );
      }

      if (!_sameIdSet(categoryIds, normalizedCategoryIds)) {
        await PreferencesService.saveBeneficiariesCategoryFilterIds(
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

  List<Movement> _filteredMovements() {
    return widget.db.movements.where((movement) {
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

  List<Category> _expenseCategories(List<Category> categories) =>
      categories.where((c) => c.type == MovementType.expense).toList();

  List<Category> _incomeCategories(List<Category> categories) =>
      categories.where((c) => c.type == MovementType.income).toList();

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
                  key: const Key('beneficiaries_account_filter_sheet'),
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
                    const SizedBox(height: StreamSpacing.md),
                    InkWell(
                      key: const Key('beneficiaries_account_filter_all_option'),
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
                    ...activeAccounts.map((account) {
                      final isSelected = workingIds.contains(account.id);
                      return InkWell(
                        key: Key(
                          'beneficiaries_account_filter_option_${account.id}',
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                    }),
                    const SizedBox(height: StreamSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key(
                              'beneficiaries_account_filter_cancel',
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: FilledButton(
                            key: const Key(
                              'beneficiaries_account_filter_apply',
                            ),
                            onPressed: () async {
                              final finalIds =
                                  workingIds.length == activeAccounts.length
                                  ? null
                                  : workingIds;
                              await PreferencesService.saveBeneficiariesAccountFilterIds(
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
            Widget buildCategoryOption(Category category) {
              final isSelected = workingIds.contains(category.id);
              return InkWell(
                key: Key('beneficiaries_category_filter_option_${category.id}'),
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
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: p.primary,
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
                  key: const Key('beneficiaries_category_filter_sheet'),
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
                    const SizedBox(height: StreamSpacing.md),
                    InkWell(
                      key: const Key(
                        'beneficiaries_category_filter_all_option',
                      ),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (expenseCategories.isNotEmpty) ...[
                              const Padding(
                                key: Key(
                                  'beneficiaries_category_filter_expense_section',
                                ),
                                padding: EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  'Uscite',
                                  style: StreamTypography.h3,
                                ),
                              ),
                              ...expenseCategories.map(buildCategoryOption),
                            ],
                            if (incomeCategories.isNotEmpty) ...[
                              const Padding(
                                key: Key(
                                  'beneficiaries_category_filter_income_section',
                                ),
                                padding: EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  'Entrate',
                                  style: StreamTypography.h3,
                                ),
                              ),
                              ...incomeCategories.map(buildCategoryOption),
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
                            key: const Key(
                              'beneficiaries_category_filter_cancel',
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: FilledButton(
                            key: const Key(
                              'beneficiaries_category_filter_apply',
                            ),
                            onPressed: () async {
                              final finalIds =
                                  workingIds.length == activeCategories.length
                                  ? null
                                  : workingIds;
                              await PreferencesService.saveBeneficiariesCategoryFilterIds(
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

  List<_BeneficiaryEntry> _buildEntries() {
    final entries = <String, _BeneficiaryEntry>{};

    for (final profile in widget.db.beneficiaryProfiles) {
      entries[profile.key] = _BeneficiaryEntry.fromProfile(profile);
    }

    for (final movement in _filteredMovements()) {
      final cleanedPayee = widget.db.cleanBeneficiaryName(movement.payee);
      if (cleanedPayee.isEmpty) continue;

      final key = BeneficiaryProfile.normalizeKey(cleanedPayee);
      final profile = widget.db.getBeneficiaryProfile(key);
      final current =
          entries[key] ??
          _BeneficiaryEntry(
            key: key,
            displayName: profile?.displayName ?? cleanedPayee,
            iconKey: profile?.iconKey ?? BeneficiaryProfile.defaultIconKey,
            color: profile?.color ?? StreamColorPalette.defaultColor,
            movementCount: 0,
            totalIncome: 0,
            totalExpense: 0,
            searchKey: key,
          );

      final updated = current.copyWith(
        displayName: profile?.displayName ?? current.displayName,
        iconKey: profile?.iconKey ?? current.iconKey,
        color: profile?.color ?? current.color,
        movementCount: current.movementCount + 1,
        totalIncome:
            current.totalIncome +
            (movement.type == MovementType.income ? movement.amount : 0),
        totalExpense:
            current.totalExpense +
            (movement.type == MovementType.expense ? movement.amount : 0),
      );
      entries[key] = updated;
    }

    final hasScopedFilters =
        _selectedAccountFilterIds != null || _selectedCategoryFilterIds != null;
    final list =
        entries.values
            .where((entry) => !hasScopedFilters || entry.movementCount > 0)
            .toList()
          ..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );
    return list;
  }

  List<_BeneficiarySection> _groupEntries(List<_BeneficiaryEntry> entries) {
    final sections = <String, List<_BeneficiaryEntry>>{};
    for (final entry in entries) {
      final firstChar = entry.displayName.trim().isEmpty
          ? '#'
          : entry.displayName.trim().substring(0, 1).toUpperCase();
      sections.putIfAbsent(firstChar, () => <_BeneficiaryEntry>[]).add(entry);
    }
    final orderedLetters = sections.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return orderedLetters
        .map(
          (letter) => _BeneficiarySection(
            letter: letter,
            entries: sections[letter]!
              ..sort(
                (a, b) => a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                ),
              ),
          ),
        )
        .toList();
  }

  void _showBeneficiaryDetail(BuildContext context, _BeneficiaryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BeneficiaryDetailSheet(
        db: widget.db,
        beneficiaryKey: entry.key,
        selectedAccountIds: _selectedAccountFilterIds,
        selectedCategoryIds: _selectedCategoryFilterIds,
      ),
    );
  }
}

class _BeneficiaryCard extends StatelessWidget {
  final _BeneficiaryEntry entry;
  final VoidCallback onTap;
  final bool selectable;

  const _BeneficiaryCard({
    required this.entry,
    required this.onTap,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final surface = StreamSurfaceTokens.card(p);
    final iconBg = Color(entry.color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('beneficiary_card_${entry.key}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: surface.background,
            borderRadius: BorderRadius.circular(StreamRadius.lg),
            border: Border.all(
              color: surface.border,
              width: surface.borderWidth,
            ),
            boxShadow: surface.shadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(StreamSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(StreamRadius.md),
                  ),
                  child: Icon(
                    StreamIconLibrary.getIcon(entry.iconKey),
                    color: StreamSurfaceTokens.onAccent(iconBg),
                  ),
                ),
                const SizedBox(width: StreamSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.displayName, style: StreamTypography.bodyBold),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.movementCount} movimenti',
                        style: StreamTypography.caption.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: StreamSpacing.xs),
                      Wrap(
                        key: const Key('beneficiaries_hero_kpi'),
                        spacing: StreamSpacing.sm,
                        runSpacing: StreamSpacing.xs,
                        children: [
                          _StatChip(
                            label: 'Entrate',
                            value: _formatEuro(entry.totalIncome),
                            semanticType: StreamKpiSemanticType.income,
                          ),
                          _StatChip(
                            label: 'Uscite',
                            value: _formatEuro(entry.totalExpense),
                            semanticType: StreamKpiSemanticType.expense,
                          ),
                          _StatChip(
                            label: 'Saldo',
                            value: _formatEuro(entry.balance),
                            semanticType: StreamKpiSemanticType.balance,
                            accentColor: entry.balance >= 0
                                ? p.income
                                : p.expense,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: StreamSpacing.sm),
                Icon(
                  selectable ? Icons.check_circle_outline : Icons.chevron_right,
                  color: selectable ? p.primary : p.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatEuro(double value) => formatMovementCurrency(value);
}

class _BeneficiaryDetailSheet extends StatelessWidget {
  final AppDatabase db;
  final String beneficiaryKey;
  final Set<String>? selectedAccountIds;
  final Set<String>? selectedCategoryIds;

  const _BeneficiaryDetailSheet({
    required this.db,
    required this.beneficiaryKey,
    this.selectedAccountIds,
    this.selectedCategoryIds,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        final p = context.$palette;
        return Container(
          key: const Key('beneficiary_detail_sheet'),
          decoration: BoxDecoration(
            color: p.canvas,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(StreamRadius.xl),
            ),
          ),
          child: ListenableBuilder(
            listenable: db,
            builder: (context, _) {
              final entry = _buildDetailEntry();
              final beneficiaryMovements = _matchingMovements;

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: StreamSpacing.sm),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(StreamSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(entry.color),
                            borderRadius: BorderRadius.circular(
                              StreamRadius.sm,
                            ),
                          ),
                          child: Icon(
                            StreamIconLibrary.getIcon(entry.iconKey),
                            color: StreamSurfaceTokens.onAccent(
                              Color(entry.color),
                            ),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.displayName,
                                style: StreamTypography.h3,
                              ),
                              const SizedBox(height: StreamSpacing.xs),
                              Text(
                                '${entry.movementCount} movimenti',
                                style: StreamTypography.caption.copyWith(
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: p.divider),
                  Expanded(
                    child: beneficiaryMovements.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(StreamSpacing.xl),
                              child: Text(
                                'Nessun movimento collegato a questo beneficiario',
                                style: StreamTypography.body.copyWith(
                                  color: p.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : GroupedMovementsList(
                            movements: beneficiaryMovements,
                            db: db,
                            scrollController: scrollController,
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  _BeneficiaryEntry _buildDetailEntry() {
    final profile = db.getBeneficiaryProfile(beneficiaryKey);
    if (profile != null) {
      return _BeneficiaryEntry.fromProfile(profile).copyWith(
        movementCount: _movementCount,
        totalIncome: _totalIncome,
        totalExpense: _totalExpense,
      );
    }

    return _BeneficiaryEntry(
      key: beneficiaryKey,
      displayName: beneficiaryKey,
      iconKey: BeneficiaryProfile.defaultIconKey,
      color: StreamColorPalette.defaultColor,
      movementCount: _movementCount,
      totalIncome: _totalIncome,
      totalExpense: _totalExpense,
      searchKey: beneficiaryKey,
    );
  }

  int get _movementCount => _matchingMovements.length;

  double get _totalIncome => _matchingMovements.fold(
    0.0,
    (sum, movement) =>
        sum + (movement.type == MovementType.income ? movement.amount : 0.0),
  );

  double get _totalExpense => _matchingMovements.fold(
    0.0,
    (sum, movement) =>
        sum + (movement.type == MovementType.expense ? movement.amount : 0.0),
  );

  List<Movement> get _matchingMovements => db.movements.where((movement) {
    final matchesAccount =
        selectedAccountIds == null ||
        selectedAccountIds!.contains(movement.accountId) ||
        (movement.destinationAccountId != null &&
            selectedAccountIds!.contains(movement.destinationAccountId));
    if (!matchesAccount) {
      return false;
    }

    if (selectedCategoryIds != null) {
      if (movement.isTransfer) {
        if (movement.categoryId.isEmpty ||
            !selectedCategoryIds!.contains(movement.categoryId)) {
          return false;
        }
      } else if (!selectedCategoryIds!.contains(movement.categoryId)) {
        return false;
      }
    }

    final cleaned = db.cleanBeneficiaryName(movement.payee);
    if (cleaned.isEmpty) {
      return false;
    }
    return BeneficiaryProfile.normalizeKey(cleaned) == beneficiaryKey;
  }).toList();
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final StreamKpiSemanticType semanticType;
  final Color? accentColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.semanticType,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamKpiCard(
      title: label,
      value: value,
      semanticType: semanticType,
      accentColor: accentColor,
      density: StreamKpiDensity.tight,
      layout: StreamKpiLayout.stacked,
      uppercaseTitle: false,
    );
  }
}

class _BeneficiariesEmptyState extends StatelessWidget {
  final bool hasQuery;

  const _BeneficiariesEmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.xl),
        child: Text(
          hasQuery
              ? 'Nessun beneficiario trovato'
              : 'Nessun beneficiario disponibile',
          style: StreamTypography.body.copyWith(color: p.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BeneficiarySection {
  final String letter;
  final List<_BeneficiaryEntry> entries;

  const _BeneficiarySection({required this.letter, required this.entries});
}

class _BeneficiaryEntry {
  final String key;
  final String displayName;
  final String iconKey;
  final int color;
  final int movementCount;
  final double totalIncome;
  final double totalExpense;
  final String searchKey;

  const _BeneficiaryEntry({
    required this.key,
    required this.displayName,
    required this.iconKey,
    required this.color,
    required this.movementCount,
    required this.totalIncome,
    required this.totalExpense,
    required this.searchKey,
  });

  factory _BeneficiaryEntry.fromProfile(BeneficiaryProfile profile) {
    return _BeneficiaryEntry(
      key: profile.key,
      displayName: profile.displayName,
      iconKey: profile.iconKey,
      color: profile.color,
      movementCount: 0,
      totalIncome: 0,
      totalExpense: 0,
      searchKey:
          '${profile.key} ${BeneficiaryProfile.normalizeKey(profile.displayName)}',
    );
  }

  double get balance => totalIncome - totalExpense;

  _BeneficiaryEntry copyWith({
    String? displayName,
    String? iconKey,
    int? color,
    int? movementCount,
    double? totalIncome,
    double? totalExpense,
  }) {
    return _BeneficiaryEntry(
      key: key,
      displayName: displayName ?? this.displayName,
      iconKey: iconKey ?? this.iconKey,
      color: color ?? this.color,
      movementCount: movementCount ?? this.movementCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      searchKey:
          '$key ${BeneficiaryProfile.normalizeKey(displayName ?? this.displayName)}',
    );
  }
}

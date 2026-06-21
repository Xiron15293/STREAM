import 'package:flutter/material.dart';

import '../data/database.dart';
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

  const BeneficiariesScreen({
    super.key,
    required this.db,
    this.pickerMode = false,
    this.initialQuery,
    this.onBeneficiarySelected,
  });

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _searchCtrl.addListener(() => setState(() {}));
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
        final p = context.$palette;
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

        return Container(
          decoration: BoxDecoration(
            color: p.canvas,
            borderRadius: widget.pickerMode
                ? const BorderRadius.vertical(
                    top: Radius.circular(StreamRadius.xl),
                  )
                : BorderRadius.zero,
          ),
          child: SafeArea(
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
                                            ? widget.onBeneficiarySelected
                                                  ?.call(entry.displayName)
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
          ),
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

  List<_BeneficiaryEntry> _buildEntries() {
    final entries = <String, _BeneficiaryEntry>{};

    for (final profile in widget.db.beneficiaryProfiles) {
      entries[profile.key] = _BeneficiaryEntry.fromProfile(profile);
    }

    for (final movement in widget.db.movements) {
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

    final list = entries.values.toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
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
      builder: (_) =>
          _BeneficiaryDetailSheet(db: widget.db, beneficiaryKey: entry.key),
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

  const _BeneficiaryDetailSheet({
    required this.db,
    required this.beneficiaryKey,
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
              final beneficiaryMovements = db.movements.where((movement) {
                final cleaned = db.cleanBeneficiaryName(movement.payee);
                if (cleaned.isEmpty) {
                  return false;
                }
                return BeneficiaryProfile.normalizeKey(cleaned) ==
                    beneficiaryKey;
              }).toList();

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

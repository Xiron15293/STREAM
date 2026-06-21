import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/analytics_metrics.dart';
import '../utils/currency_formatter.dart';
import '../widgets/charts/chart_empty_state.dart';
import '../widgets/charts/stream_bar_chart.dart';
import '../widgets/charts/stream_chart_card.dart';
import '../widgets/charts/stream_donut_chart.dart';
import '../widgets/charts/stream_horizontal_bar_chart.dart';
import '../widgets/time_filter_bar.dart';

class ChartDefinition {
  final String id;
  final String title;
  final String section;

  const ChartDefinition({
    required this.id,
    required this.title,
    required this.section,
  });
}

const List<ChartDefinition> chartRegistry = [
  ChartDefinition(
    id: 'movements_cashflow',
    title: 'Entrate / Uscite nel tempo',
    section: 'movements',
  ),
  ChartDefinition(
    id: 'movements_daily_count',
    title: 'Movimenti per giorno',
    section: 'movements',
  ),
  ChartDefinition(
    id: 'movements_type_distribution',
    title: 'Distribuzione tipo movimento',
    section: 'movements',
  ),
  ChartDefinition(
    id: 'movements_top_spending_days',
    title: 'Top giorni di spesa',
    section: 'movements',
  ),
  ChartDefinition(
    id: 'movements_weekday_costs',
    title: 'Giorni della settimana più costosi',
    section: 'movements',
  ),
  ChartDefinition(
    id: 'movements_avg_daily_spend',
    title: 'Spesa media giornaliera',
    section: 'movements',
  ),
  ChartDefinition(
    id: 'categories_top',
    title: 'Top spese per categoria',
    section: 'categories',
  ),
  ChartDefinition(
    id: 'categories_composition',
    title: 'Composizione categorie',
    section: 'categories',
  ),
  ChartDefinition(
    id: 'categories_delta_vs_previous',
    title: 'Categorie in crescita / calo',
    section: 'categories',
  ),
  ChartDefinition(
    id: 'accounts_balance',
    title: 'Saldo per conto',
    section: 'accounts',
  ),
  ChartDefinition(
    id: 'accounts_balance_share',
    title: 'Quota saldo per conto',
    section: 'accounts',
  ),
  ChartDefinition(
    id: 'accounts_flows',
    title: 'Flussi per conto',
    section: 'accounts',
  ),
  ChartDefinition(
    id: 'accounts_outflow',
    title: 'Conti più usati per uscite',
    section: 'accounts',
  ),
  ChartDefinition(
    id: 'accounts_inflow',
    title: 'Conti più usati per entrate',
    section: 'accounts',
  ),
  ChartDefinition(
    id: 'accounts_activity',
    title: 'Attività per conto',
    section: 'accounts',
  ),
  ChartDefinition(
    id: 'beneficiaries_top_amount',
    title: 'Top beneficiari per importo',
    section: 'beneficiaries',
  ),
  ChartDefinition(
    id: 'beneficiaries_frequency',
    title: 'Frequenza beneficiari',
    section: 'beneficiaries',
  ),
  ChartDefinition(
    id: 'beneficiaries_average',
    title: 'Valore medio per beneficiario',
    section: 'beneficiaries',
  ),
];

bool _chartIsVisible(String id) => PreferencesService.isChartVisible(id);
List<ChartDefinition> _visibleChartsFor(String section) => chartRegistry
    .where((c) => c.section == section && _chartIsVisible(c.id))
    .toList();

enum _ChartSection { movements, categories, accounts, beneficiaries }

class ChartsScreen extends StatefulWidget {
  final AppDatabase db;
  final String? activeProfileId;

  const ChartsScreen({super.key, required this.db, this.activeProfileId});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  _ChartSection _section = _ChartSection.movements;
  late TimeFilter _filter;
  MovementType _categoryTypeFilter = MovementType.expense;
  Set<String>? _selectedAccountFilterIds;
  Set<String>? _selectedCategoryFilterIds;
  bool _filtersSyncInProgress = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
    _loadScopedFilters();
  }

  @override
  void didUpdateWidget(covariant ChartsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProfileId != widget.activeProfileId) {
      _loadScopedFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Scaffold(
      key: const Key('charts_screen_root'),
      backgroundColor: p.canvas,
      appBar: AppBar(
        title: const Text('Grafici'),
        actions: [
          IconButton(
            key: const Key('charts_settings_button'),
            icon: const Icon(Icons.tune),
            onPressed: () => _showChartSettings(context),
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
            final accountNeedsSanitize = _selectedAccountFilterIds != null &&
                !_selectedAccountFilterIds!.every(activeAccountIds.contains);
            final categoryNeedsSanitize = _selectedCategoryFilterIds != null &&
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

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _buildSectionChip(
                      _ChartSection.movements,
                      Icons.swap_vert,
                      'Movimenti',
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChip(
                      _ChartSection.categories,
                      Icons.category,
                      'Categorie',
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChip(
                      _ChartSection.accounts,
                      Icons.account_balance,
                      'Conti',
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChip(
                      _ChartSection.beneficiaries,
                      Icons.person,
                      'Beneficiari',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: KeyedSubtree(
                  key: const Key('charts_time_filter'),
                  child: TimeFilterBar(
                    activeFilter: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                    customRangeLabel: 'Range',
                  ),
                ),
              ),
              Padding(
                key: const Key('charts_filters_section'),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
                        if (_showsAccountFilterForSection(_section))
                          ActionChip(
                            key: const Key('charts_account_filter_button'),
                            avatar: const Icon(Icons.account_balance, size: 18),
                            label: Text(
                              _accountFilterLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _showAccountFilterSheet(context),
                          ),
                        if (_showsCategoryFilterForSection(_section))
                          ActionChip(
                            key: const Key('charts_category_filter_button'),
                            avatar: const Icon(Icons.category, size: 18),
                            label: Text(
                              _categoryFilterLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _showCategoryFilterSheet(context),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_section == _ChartSection.categories)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<MovementType>(
                      segments: const [
                        ButtonSegment(
                          value: MovementType.expense,
                          label: Text('Uscite'),
                        ),
                        ButtonSegment(
                          value: MovementType.income,
                          label: Text('Entrate'),
                        ),
                      ],
                      selected: {_categoryTypeFilter},
                      onSelectionChanged: (Set<MovementType> v) {
                        setState(() => _categoryTypeFilter = v.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ),
                ),
              Expanded(child: _buildSection()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionChip(_ChartSection value, IconData icon, String label) {
    final selected = _section == value;
    final p = context.$palette;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected
                ? StreamSurfaceTokens.onAccent(p.primary)
                : p.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected
                  ? StreamSurfaceTokens.onAccent(p.primary)
                  : p.textSecondary,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _section = value),
      selectedColor: p.primary,
      backgroundColor: p.surfaceElevated,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSection() {
    if (_showsAccountFilterForSection(_section) &&
        _selectedAccountFilterIds != null &&
        _selectedAccountFilterIds!.isEmpty) {
      return const ChartEmptyState(message: 'Nessun conto selezionato');
    }
    if (_showsCategoryFilterForSection(_section) &&
        _selectedCategoryFilterIds != null &&
        _selectedCategoryFilterIds!.isEmpty) {
      return const ChartEmptyState(message: 'Nessuna categoria selezionata');
    }
    switch (_section) {
      case _ChartSection.movements:
        return _buildMovementsSection();
      case _ChartSection.categories:
        return _buildCategoriesSection();
      case _ChartSection.accounts:
        return _buildAccountsSection();
      case _ChartSection.beneficiaries:
        return _buildBeneficiariesSection();
    }
  }

  static String _fmt(double v) =>
      formatMovementCurrency(v, showPositiveSign: true);
  static String _fmtNoSign(double v) =>
      formatMovementCurrency(v, showPositiveSign: false);

  Widget _noVisibleCharts() {
    return GestureDetector(
      onTap: () => _showChartSettings(context),
      child: const ChartEmptyState(
        message:
            'Nessun grafico attivo in questa sezione.\nTocca per aprire le impostazioni grafici.',
      ),
    );
  }

  Widget _buildMovementsSection() {
    final movements = _applyChartScopedFilters(
      widget.db.movements,
      applyAccountFilter: true,
      applyCategoryFilter: true,
    );
    final filtered = movements.filterByTime(_filter);
    if (_visibleChartsFor('movements').isEmpty) return _noVisibleCharts();
    if (filtered.isEmpty) {
      return const ChartEmptyState(
        message: 'Nessun movimento nel periodo selezionato',
      );
    }

    final cashflow = buildMovementCashflowSeries(movements, _filter);
    final countByDay = buildMovementCountByDay(movements, _filter);
    final typeBreakdown = buildMovementTypeBreakdown(movements, _filter);
    final topDays = buildTopSpendingDays(movements, _filter);
    final weekday = buildWeekdayCostBreakdown(movements, _filter);
    final avgDaily = buildAvgDailySpend(movements, _filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (_chartIsVisible('movements_cashflow') && cashflow.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_movements_cashflow'),
            title: 'Entrate / Uscite nel tempo',
            height: 240,
            child: _LegendRow(
              colors: [context.$palette.income, context.$palette.expense],
              labels: ['Entrate', 'Uscite'],
              child: StreamBarChart(series: cashflow, currencyAxis: true),
            ),
          ),
        if (_chartIsVisible('movements_daily_count') && countByDay.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_movements_daily_count'),
            title: 'Movimenti per giorno',
            height: 200,
            child: StreamBarChart(series: countByDay),
          ),
        if (_chartIsVisible('movements_type_distribution') &&
            typeBreakdown.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_movements_type_distribution'),
            title: 'Distribuzione tipo movimento',
            height: 180,
            child: StreamDonutChart(slices: typeBreakdown),
          ),
        if (_chartIsVisible('movements_top_spending_days') &&
            topDays.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_movements_top_spending_days'),
            title: 'Top giorni di spesa',
            height: _horizontalChartCardHeight(topDays[0].points.length),
            child: StreamHorizontalBarChart(
              bars: topDays[0].points
                  .map(
                    (p) => HorizontalBarData(
                      label: p.label,
                      value: p.value,
                      formattedValue: _fmt(p.value),
                      barColor: p.color,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_chartIsVisible('movements_weekday_costs') && weekday.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_movements_weekday_costs'),
            title: 'Giorni della settimana più costosi',
            height: 200,
            child: StreamDonutChart(slices: weekday),
          ),
        if (_chartIsVisible('movements_avg_daily_spend') && avgDaily > 0)
          StreamChartCard(
            cardKey: const Key('chart_card_movements_avg_daily_spend'),
            title: 'Spesa media giornaliera',
            height: 60,
            child: Center(
              child: Text(
                _fmtNoSign(avgDaily),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.$palette.expense,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final movements = _applyChartScopedFilters(
      widget.db.movements,
      applyAccountFilter: true,
      applyCategoryFilter: false,
    );
    final categories = widget.db.categories;
    final filtered = movements.filterByTime(_filter);
    if (_visibleChartsFor('categories').isEmpty) return _noVisibleCharts();
    if (filtered.isEmpty) {
      return const ChartEmptyState(
        message: 'Nessun movimento nel periodo selezionato',
      );
    }

    final top = buildCategoryTopSeries(
      movements,
      categories,
      _filter,
      _categoryTypeFilter,
    );
    final composition = buildCategoryComposition(
      movements,
      categories,
      _filter,
      _categoryTypeFilter,
    );
    final delta = buildCategoryDeltaVsPreviousPeriod(
      movements,
      categories,
      _filter,
      _categoryTypeFilter,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (_chartIsVisible('categories_top') && top.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_categories_top'),
            title: _categoryTypeFilter == MovementType.income
                ? 'Top entrate per categoria'
                : 'Top spese per categoria',
            height: _horizontalChartCardHeight(top[0].points.length),
            child: StreamHorizontalBarChart(
              bars: top[0].points
                  .map(
                    (p) => HorizontalBarData(
                      label: p.label,
                      value: p.value,
                      formattedValue: _fmt(p.value),
                      barColor: p.color,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_chartIsVisible('categories_composition') && composition.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_categories_composition'),
            title: 'Composizione categorie',
            height: 220,
            child: StreamDonutChart(slices: composition),
          ),
        if (_chartIsVisible('categories_delta_vs_previous') && delta.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_categories_delta_vs_previous'),
            title: 'Categorie in crescita / calo vs periodo precedente',
            height: _horizontalChartCardHeight(
              delta.expand((series) => series.points).length,
              hasLegend: true,
            ),
            child: StreamHorizontalBarChart(
              bars: delta
                  .expand((series) => series.points)
                  .toList()
                  .asMap()
                  .entries
                  .map((e) {
                    final p = e.value;
                    return HorizontalBarData(
                      label: p.label,
                      value: p.value,
                      formattedValue: _fmt(p.value),
                      barColor: p.color,
                    );
                  })
                  .toList(),
              legendLabel1: delta.any((s) => s.label == 'In aumento')
                  ? 'In aumento'
                  : null,
              legendLabel2: delta.any((s) => s.label == 'In calo')
                  ? 'In calo'
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildAccountsSection() {
    final movements = _applyChartScopedFilters(
      widget.db.movements,
      applyAccountFilter: false,
      applyCategoryFilter: true,
    );
    final accounts = widget.db.accounts;
    final active = _getScopedAccounts(accounts, applyAccountFilter: false);
    final filtered = movements.filterByTime(_filter);
    if (_visibleChartsFor('accounts').isEmpty) return _noVisibleCharts();
    if (active.isEmpty) {
      return const ChartEmptyState(message: 'Nessun conto attivo');
    }
    if (filtered.isEmpty) {
      return const ChartEmptyState(
        message: 'Nessun movimento nel periodo selezionato',
      );
    }

    final balances = buildAccountBalanceSeries(active, widget.db);
    final quota = buildQuotaSaldoSeries(active, widget.db);
    final flows = buildAccountFlowSeries(movements, active, _filter);
    final activity = buildAccountActivitySeries(movements, active, _filter);
    final outflow = buildAccountOutflowSeries(movements, active, _filter);
    final inflow = buildAccountInflowSeries(movements, active, _filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (_chartIsVisible('accounts_balance') && balances.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_accounts_balance'),
            title: 'Saldo per conto',
            height: _horizontalChartCardHeight(balances.length),
            child: StreamHorizontalBarChart(
              bars: balances
                  .map(
                    (p) => HorizontalBarData(
                      label: p.label,
                      value: p.value,
                      formattedValue: _fmt(p.value),
                      barColor: p.color,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_chartIsVisible('accounts_balance_share') && quota.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_accounts_balance_share'),
            title: 'Quota saldo per conto',
            height: 220,
            child: StreamDonutChart(slices: quota),
          ),
        if (_chartIsVisible('accounts_flows') && flows.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_accounts_flows'),
            title: 'Flussi per conto',
            height: _horizontalChartCardHeight(flows[0].points.length, hasLegend: true),
            child: StreamHorizontalBarChart(
              bars: flows[0].points.asMap().entries.map((e) {
                final expensePoint = flows.length > 1
                    ? flows[1].points[e.key]
                    : null;
                return HorizontalBarData(
                  label: e.value.label,
                  value: e.value.value,
                  formattedValue: _fmt(e.value.value),
                  barColor: context.$palette.income,
                  secondaryValue: expensePoint?.value ?? 0.0,
                  secondaryFormattedValue: expensePoint != null
                      ? _fmt(expensePoint.value)
                      : null,
                  secondaryColor: context.$palette.expense,
                );
              }).toList(),
              legendLabel1: 'Entrate',
              legendLabel2: 'Uscite',
            ),
          ),
        if (_chartIsVisible('accounts_outflow') && outflow.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_accounts_outflow'),
            title: 'Conti più usati per uscite',
            height: _horizontalChartCardHeight(outflow[0].points.length),
            child: StreamHorizontalBarChart(
              bars: outflow[0].points
                  .map(
                    (p) => HorizontalBarData(
                      label: p.label,
                      value: p.value,
                      formattedValue: _fmt(p.value),
                      barColor: context.$palette.expense,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_chartIsVisible('accounts_inflow') && inflow.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_accounts_inflow'),
            title: 'Conti più usati per entrate',
            height: _horizontalChartCardHeight(inflow[0].points.length),
            child: StreamHorizontalBarChart(
              bars: inflow[0].points
                  .map(
                    (p) => HorizontalBarData(
                      label: p.label,
                      value: p.value,
                      formattedValue: _fmt(p.value),
                      barColor: context.$palette.income,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_chartIsVisible('accounts_activity') && activity.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_accounts_activity'),
            title: 'Attività per conto',
            height: _horizontalChartCardHeight(activity[0].points.length),
            child: StreamHorizontalBarChart(
              bars: activity[0].points
                  .map(
                    (p) => HorizontalBarData(
                      label: p.label,
                      value: p.value,
                      formattedValue: '${p.value.toInt()}',
                      barColor: p.color,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBeneficiariesSection() {
    final movements = _applyChartScopedFilters(
      widget.db.movements,
      applyAccountFilter: true,
      applyCategoryFilter: true,
    );
    final filtered = movements.filterByTime(_filter);
    if (_visibleChartsFor('beneficiaries').isEmpty) return _noVisibleCharts();
    if (filtered.isEmpty) {
      return const ChartEmptyState(
        message: 'Nessun movimento nel periodo selezionato',
      );
    }

    final top = buildBeneficiaryTopSeries(movements, _filter);
    final freq = buildBeneficiaryFrequencySeries(movements, _filter);
    final avg = buildBeneficiaryAverageSeries(movements, _filter);

    final hasData = top.isNotEmpty || freq.isNotEmpty || avg.isNotEmpty;
    if (!hasData) {
      return const ChartEmptyState(
        message: 'Nessun beneficiario nel periodo selezionato',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (_chartIsVisible('beneficiaries_top_amount') && top.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_beneficiaries_top_amount'),
            title: 'Top beneficiari per importo',
            height: 240,
            child: StreamDonutChart(
              slices: top[0].points
                  .map(
                    (p) => DonutSlice(
                      label: p.label,
                      value: p.value,
                      color: p.color,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_chartIsVisible('beneficiaries_frequency') && freq.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_beneficiaries_frequency'),
            title: 'Frequenza beneficiari',
            height: 240,
            child: StreamDonutChart(
              slices: freq[0].points
                  .map(
                    (p) => DonutSlice(
                      label: p.label,
                      value: p.value,
                      color: p.color,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_chartIsVisible('beneficiaries_average') && avg.isNotEmpty)
          StreamChartCard(
            cardKey: const Key('chart_card_beneficiaries_average'),
            title: 'Valore medio per beneficiario',
            height: _horizontalChartCardHeight(avg[0].points.length),
            child: StreamHorizontalBarChart(
              bars: avg[0].points
                  .map(
                    (p) => HorizontalBarData(
                      label: p.label,
                      value: p.value,
                      formattedValue: _fmt(p.value),
                      barColor: p.color,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _showChartSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(StreamRadius.xl),
        ),
      ),
      builder: (ctx) => _ChartVisibilitySheet(
        onChanged: () {
          setState(() {});
          Navigator.pop(ctx);
        },
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
      PreferencesService.chartsAccountFilterIdsNotifier.value = null;
      PreferencesService.chartsCategoryFilterIdsNotifier.value = null;
      return;
    }

    final accountIds = await PreferencesService.loadChartsAccountFilterIds(
      profileId: profileId,
    );
    final categoryIds = await PreferencesService.loadChartsCategoryFilterIds(
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

    final normalizedAccountIds = accountIds == null || accountIds.isEmpty
        ? accountIds
        : accountIds.intersection(activeAccountIds);
    final normalizedCategoryIds = categoryIds == null || categoryIds.isEmpty
        ? categoryIds
        : categoryIds.intersection(activeCategoryIds);

    try {
      if (!_sameIdSet(accountIds, normalizedAccountIds)) {
        await PreferencesService.saveChartsAccountFilterIds(
          normalizedAccountIds,
          profileId: profileId,
        );
      }
      if (!_sameIdSet(categoryIds, normalizedCategoryIds)) {
        await PreferencesService.saveChartsCategoryFilterIds(
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
    return setEquals(a, b);
  }

  List<Movement> _applyChartScopedFilters(
    List<Movement> movements, {
    required bool applyAccountFilter,
    required bool applyCategoryFilter,
  }) {
    return movements.where((movement) {
      final matchesAccount = !applyAccountFilter ||
          _selectedAccountFilterIds == null ||
          _selectedAccountFilterIds!.contains(movement.accountId) ||
          (movement.destinationAccountId != null &&
              _selectedAccountFilterIds!.contains(
                movement.destinationAccountId,
              ));
      if (!matchesAccount) return false;

      if (!applyCategoryFilter || _selectedCategoryFilterIds == null) {
        return true;
      }

      if (movement.isTransfer) {
        return movement.categoryId.isNotEmpty &&
            _selectedCategoryFilterIds!.contains(movement.categoryId);
      }

      return _selectedCategoryFilterIds!.contains(movement.categoryId);
    }).toList();
  }

  List<Account> _getScopedAccounts(
    List<Account> accounts, {
    required bool applyAccountFilter,
  }) {
    final active = accounts.where((account) => !account.archived).toList();
    if (!applyAccountFilter || _selectedAccountFilterIds == null) return active;
    return active
        .where((account) => _selectedAccountFilterIds!.contains(account.id))
        .toList();
  }

  bool _showsAccountFilterForSection(_ChartSection section) {
    switch (section) {
      case _ChartSection.movements:
      case _ChartSection.categories:
      case _ChartSection.beneficiaries:
        return true;
      case _ChartSection.accounts:
        return false;
    }
  }

  bool _showsCategoryFilterForSection(_ChartSection section) {
    switch (section) {
      case _ChartSection.movements:
      case _ChartSection.accounts:
      case _ChartSection.beneficiaries:
        return true;
      case _ChartSection.categories:
        return false;
    }
  }

  double _horizontalChartCardHeight(int itemCount, {bool hasLegend = false}) {
    if (itemCount <= 0) return hasLegend ? 108 : 88;
    const rowHeight = 32.0;
    final rows = itemCount.clamp(1, 10);
    final legendHeight = hasLegend ? 28.0 : 0.0;
    final base = 28.0 + legendHeight + (rows * rowHeight);
    final clamped = base.clamp(140.0, 420.0);
    return clamped.toDouble();
  }

  String _accountFilterLabel() {
    final activeAccounts = widget.db.accounts
        .where((account) => !account.archived)
        .toList();
    final selected = _selectedAccountFilterIds == null
        ? <String>[]
        : activeAccounts
              .where((account) => _selectedAccountFilterIds!.contains(account.id))
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
                  key: const Key('charts_account_filter_sheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtra per conti',
                          style: StreamTypography.h3,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: StreamSpacing.md),
                    InkWell(
                      key: const Key('charts_account_filter_all_option'),
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
                        key: Key('charts_account_filter_option_${account.id}'),
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
                            key: const Key('charts_account_filter_cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: FilledButton(
                            key: const Key('charts_account_filter_apply'),
                            onPressed: () async {
                              final finalIds =
                                  workingIds.length == activeAccounts.length
                                  ? null
                                  : workingIds;
                              await PreferencesService.saveChartsAccountFilterIds(
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
                key: Key('charts_category_filter_option_${category.id}'),
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
                  key: const Key('charts_category_filter_sheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtra per categorie',
                          style: StreamTypography.h3,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: StreamSpacing.md),
                    InkWell(
                      key: const Key('charts_category_filter_all_option'),
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
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  'Uscite',
                                  style: StreamTypography.h3,
                                ),
                              ),
                              ...expenseCategories.map(buildCategoryOption),
                            ],
                            if (incomeCategories.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 4),
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
                            key: const Key('charts_category_filter_cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: FilledButton(
                            key: const Key('charts_category_filter_apply'),
                            onPressed: () async {
                              final finalIds =
                                  workingIds.length == activeCategories.length
                                  ? null
                                  : workingIds;
                              await PreferencesService.saveChartsCategoryFilterIds(
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
}

class _LegendRow extends StatelessWidget {
  final List<Color> colors;
  final List<String> labels;
  final Widget child;

  const _LegendRow({
    required this.colors,
    required this.labels,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cp = context.$chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(colors.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    labels[i],
                    style: TextStyle(fontSize: 11, color: cp.legendTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _ChartVisibilitySheet extends StatefulWidget {
  final VoidCallback onChanged;
  const _ChartVisibilitySheet({required this.onChanged});

  @override
  State<_ChartVisibilitySheet> createState() => _ChartVisibilitySheetState();
}

class _ChartVisibilitySheetState extends State<_ChartVisibilitySheet> {
  late Set<String> _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = Set.from(PreferencesService.hiddenChartIdsNotifier.value);
  }

  static const _sections = [
    ('movements', 'Movimenti'),
    ('categories', 'Categorie'),
    ('accounts', 'Conti'),
    ('beneficiaries', 'Beneficiari'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: p.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Impostazioni grafici', style: StreamTypography.h3),
          const SizedBox(height: 4),
          Text(
            'Mostra o nascondi i singoli grafici.',
            style: StreamTypography.caption.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                key: const Key('chart_visibility_show_all'),
                onPressed: _showAll,
                child: const Text('Mostra tutti'),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const Key('chart_visibility_reset_defaults'),
                onPressed: _resetDefaults,
                child: const Text('Ripristina predefiniti'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections.expand((section) {
                  final charts = chartRegistry
                      .where((c) => c.section == section.$1)
                      .toList();
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        section.$2,
                        style: StreamTypography.captionBold.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                    ...charts.map(
                      (chart) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          chart.title,
                          style: TextStyle(fontSize: 13, color: p.textPrimary),
                        ),
                        value: !_hidden.contains(chart.id),
                        onChanged: (v) => setState(() {
                          if (v) {
                            _hidden.remove(chart.id);
                          } else {
                            _hidden.add(chart.id);
                          }
                          PreferencesService.setChartVisible(chart.id, v);
                          widget.onChanged();
                        }),
                        dense: true,
                      ),
                    ),
                  ];
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAll() {
    setState(() => _hidden.clear());
    PreferencesService.saveHiddenChartIds({});
    widget.onChanged();
  }

  void _resetDefaults() {
    _showAll();
  }
}

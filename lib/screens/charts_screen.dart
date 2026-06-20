import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_theme_extension.dart';
import '../models/category.dart';
import '../models/time_filter.dart';
import '../utils/analytics_metrics.dart';
import '../utils/currency_formatter.dart';
import '../widgets/charts/chart_empty_state.dart';
import '../widgets/charts/stream_bar_chart.dart';
import '../widgets/charts/stream_chart_card.dart';
import '../widgets/charts/stream_donut_chart.dart';
import '../widgets/charts/stream_horizontal_bar_chart.dart';
import '../widgets/time_filter_bar.dart';

enum _ChartSection { movements, categories, accounts, beneficiaries }

class ChartsScreen extends StatefulWidget {
  final AppDatabase db;

  const ChartsScreen({super.key, required this.db});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  _ChartSection _section = _ChartSection.movements;
  late TimeFilter _filter;
  MovementType _categoryTypeFilter = MovementType.expense;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(title: const Text('Grafici')),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
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
            color: selected ? Colors.white : p.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : p.textSecondary,
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

  Widget _buildMovementsSection() {
    final movements = widget.db.movements;
    final filtered = movements.filterByTime(_filter);
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
        if (cashflow.isNotEmpty)
          StreamChartCard(
            title: 'Entrate / Uscite nel tempo',
            height: 240,
            child: _LegendRow(
              colors: [context.$palette.income, context.$palette.expense],
              labels: ['Entrate', 'Uscite'],
              child: StreamBarChart(series: cashflow),
            ),
          ),
        if (countByDay.isNotEmpty)
          StreamChartCard(
            title: 'Movimenti per giorno',
            height: 200,
            child: StreamBarChart(series: countByDay),
          ),
        if (typeBreakdown.isNotEmpty)
          StreamChartCard(
            title: 'Distribuzione tipo movimento',
            height: 180,
            child: StreamDonutChart(slices: typeBreakdown),
          ),
        if (topDays.isNotEmpty)
          StreamChartCard(
            title: 'Top giorni di spesa',
            height: 300,
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
        if (weekday.isNotEmpty)
          StreamChartCard(
            title: 'Giorni della settimana più costosi',
            height: 200,
            child: StreamDonutChart(slices: weekday),
          ),
        if (avgDaily > 0)
          StreamChartCard(
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
    final movements = widget.db.movements;
    final categories = widget.db.categories;
    final filtered = movements.filterByTime(_filter);
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
        if (top.isNotEmpty)
          StreamChartCard(
            title: _categoryTypeFilter == MovementType.income
                ? 'Top entrate per categoria'
                : 'Top spese per categoria',
            height: 300,
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
        if (composition.isNotEmpty)
          StreamChartCard(
            title: 'Composizione categorie',
            height: 220,
            child: StreamDonutChart(slices: composition),
          ),
        if (delta.isNotEmpty)
          StreamChartCard(
            title: 'Categorie in crescita / calo vs periodo precedente',
            height: 280,
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
    final movements = widget.db.movements;
    final accounts = widget.db.accounts;
    final active = accounts.where((a) => !a.archived).toList();
    final filtered = movements.filterByTime(_filter);
    if (active.isEmpty) {
      return const ChartEmptyState(message: 'Nessun conto attivo');
    }
    if (filtered.isEmpty) {
      return const ChartEmptyState(
        message: 'Nessun movimento nel periodo selezionato',
      );
    }

    final balances = buildAccountBalanceSeries(accounts, widget.db);
    final quota = buildQuotaSaldoSeries(accounts, widget.db);
    final flows = buildAccountFlowSeries(movements, accounts, _filter);
    final activity = buildAccountActivitySeries(movements, accounts, _filter);
    final outflow = buildAccountOutflowSeries(movements, accounts, _filter);
    final inflow = buildAccountInflowSeries(movements, accounts, _filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (balances.isNotEmpty)
          StreamChartCard(
            title: 'Saldo per conto',
            height: 300,
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
        if (quota.isNotEmpty)
          StreamChartCard(
            title: 'Quota saldo per conto',
            height: 220,
            child: StreamDonutChart(slices: quota),
          ),
        if (flows.isNotEmpty)
          StreamChartCard(
            title: 'Flussi per conto',
            height: 300,
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
        if (outflow.isNotEmpty)
          StreamChartCard(
            title: 'Conti più usati per uscite',
            height: 280,
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
        if (inflow.isNotEmpty)
          StreamChartCard(
            title: 'Conti più usati per entrate',
            height: 280,
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
        if (activity.isNotEmpty)
          StreamChartCard(
            title: 'Attività per conto',
            height: 280,
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
    final movements = widget.db.movements;
    final filtered = movements.filterByTime(_filter);
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
        if (top.isNotEmpty)
          StreamChartCard(
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
        if (freq.isNotEmpty)
          StreamChartCard(
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
        if (avg.isNotEmpty)
          StreamChartCard(
            title: 'Valore medio per beneficiario',
            height: 300,
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
    final p = context.$palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(colors.length, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < colors.length - 1 ? 16 : 0),
              child: Row(
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
                  Text(
                    labels[i],
                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }
}

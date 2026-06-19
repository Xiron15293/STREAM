import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/category.dart';
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
    return Scaffold(
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
                    _buildSectionChip(_ChartSection.movements, Icons.swap_vert, 'Movimenti'),
                    const SizedBox(width: 8),
                    _buildSectionChip(_ChartSection.categories, Icons.category, 'Categorie'),
                    const SizedBox(width: 8),
                    _buildSectionChip(_ChartSection.accounts, Icons.account_balance, 'Conti'),
                    const SizedBox(width: 8),
                    _buildSectionChip(_ChartSection.beneficiaries, Icons.person, 'Beneficiari'),
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
                        ButtonSegment(value: MovementType.expense, label: Text('Uscite')),
                        ButtonSegment(value: MovementType.income, label: Text('Entrate')),
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
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : StreamColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : StreamColors.textSecondary)),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _section = value),
      selectedColor: StreamColors.primary,
      backgroundColor: StreamColors.surfaceElevated,
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

  static String _fmt(double v) => formatMovementCurrency(v, showPositiveSign: true);
  static String _fmtCount(double v) => '${v.toInt()} ${v.toInt() == 1 ? 'movimento' : 'movimenti'}';

  Widget _buildMovementsSection() {
    final movements = widget.db.movements;
    final filtered = movements.filterByTime(_filter);
    if (filtered.isEmpty) {
      return const ChartEmptyState(message: 'Nessun movimento nel periodo selezionato');
    }

    final cashflow = buildMovementCashflowSeries(movements, _filter);
    final countByDay = buildMovementCountByDay(movements, _filter);
    final typeBreakdown = buildMovementTypeBreakdown(movements, _filter);
    final topDays = buildTopSpendingDays(movements, _filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (cashflow.isNotEmpty)
          StreamChartCard(
            title: 'Entrate / Uscite nel tempo',
            height: 240,
            child: _LegendRow(
              colors: [StreamColors.income, StreamColors.expense],
              labels: ['Entrate', 'Uscite'],
              child: StreamBarChart(series: cashflow),
            ),
          ),
        if (countByDay.isNotEmpty)
          StreamChartCard(
            title: 'Movimenti per giorno',
            child: StreamBarChart(series: countByDay),
          ),
        if (typeBreakdown.isNotEmpty)
          StreamChartCard(
            title: 'Distribuzione tipo movimento',
            height: 160,
            child: StreamDonutChart(slices: typeBreakdown),
          ),
        if (topDays.isNotEmpty)
          StreamChartCard(
            title: 'Top giorni di spesa',
            height: 40 + topDays[0].points.length * 36.0,
            child: StreamHorizontalBarChart(
              bars: topDays[0].points.map((p) => HorizontalBarData(
                label: p.label,
                value: p.value,
                formattedValue: _fmt(p.value),
                barColor: p.color,
              )).toList(),
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
      return const ChartEmptyState(message: 'Nessun movimento nel periodo selezionato');
    }

    final top = buildCategoryTopSeries(movements, categories, _filter, _categoryTypeFilter);
    final composition = buildCategoryComposition(movements, categories, _filter, _categoryTypeFilter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (top.isNotEmpty)
          StreamChartCard(
            title: _categoryTypeFilter == MovementType.income ? 'Top entrate per categoria' : 'Top spese per categoria',
            height: 40 + top[0].points.length * 36.0,
            child: StreamHorizontalBarChart(
              bars: top[0].points.map((p) => HorizontalBarData(
                label: p.label,
                value: p.value,
                formattedValue: _fmt(p.value),
                barColor: p.color,
              )).toList(),
            ),
          ),
        if (composition.isNotEmpty)
          StreamChartCard(
            title: 'Composizione categorie',
            height: 40 + composition.length * 36.0,
            child: StreamHorizontalBarChart(
              bars: composition.map((s) => HorizontalBarData(
                label: s.label,
                value: s.value,
                formattedValue: _fmt(s.value),
                barColor: s.color,
              )).toList(),
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
      return const ChartEmptyState(message: 'Nessun movimento nel periodo selezionato');
    }

    final balances = buildAccountBalanceSeries(accounts, widget.db);
    final flows = buildAccountFlowSeries(movements, accounts, _filter);
    final activity = buildAccountActivitySeries(movements, accounts, _filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (balances.isNotEmpty)
          StreamChartCard(
            title: 'Saldo per conto',
            height: 40 + balances.length * 36.0,
            child: StreamHorizontalBarChart(
              bars: balances.map((p) => HorizontalBarData(
                label: p.label,
                value: p.value,
                formattedValue: _fmt(p.value),
                barColor: p.color,
              )).toList(),
            ),
          ),
        if (flows.isNotEmpty)
          StreamChartCard(
            title: 'Flussi per conto',
            height: 40 + flows[0].points.length * 36.0,
            child: StreamHorizontalBarChart(
              bars: flows[0].points.asMap().entries.map((e) {
                final expensePoint = flows.length > 1 ? flows[1].points[e.key] : null;
                final expenseLabel = expensePoint != null ? _fmt(expensePoint.value) : null;
                return HorizontalBarData(
                  label: e.value.label,
                  value: e.value.value,
                  formattedValue: _fmt(e.value.value),
                  barColor: StreamColors.income,
                  secondaryValue: expensePoint?.value ?? 0.0,
                  secondaryFormattedValue: expenseLabel,
                  secondaryColor: StreamColors.expense,
                );
              }).toList(),
              legendLabel1: 'Entrate',
              legendLabel2: 'Uscite',
            ),
          ),
        if (activity.isNotEmpty)
          StreamChartCard(
            title: 'Attività per conto',
            height: 40 + activity[0].points.length * 36.0,
            child: StreamHorizontalBarChart(
              bars: activity[0].points.map((p) => HorizontalBarData(
                label: p.label,
                value: p.value,
                formattedValue: _fmtCount(p.value),
                barColor: p.color,
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBeneficiariesSection() {
    final movements = widget.db.movements;
    final filtered = movements.filterByTime(_filter);
    if (filtered.isEmpty) {
      return const ChartEmptyState(message: 'Nessun movimento nel periodo selezionato');
    }

    final top = buildBeneficiaryTopSeries(movements, _filter);
    final freq = buildBeneficiaryFrequencySeries(movements, _filter);

    if (top.isEmpty && freq.isEmpty) {
      return const ChartEmptyState(message: 'Nessun beneficiario nel periodo selezionato');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (top.isNotEmpty)
          StreamChartCard(
            title: 'Top beneficiari per importo',
            height: 40 + top[0].points.length * 36.0,
            child: StreamHorizontalBarChart(
              bars: top[0].points.map((p) => HorizontalBarData(
                label: p.label,
                value: p.value,
                formattedValue: _fmt(p.value),
                barColor: p.color,
              )).toList(),
            ),
          ),
        if (freq.isNotEmpty)
          StreamChartCard(
            title: 'Frequenza beneficiari',
            height: 40 + freq[0].points.length * 36.0,
            child: StreamHorizontalBarChart(
              bars: freq[0].points.map((p) => HorizontalBarData(
                label: p.label,
                value: p.value,
                formattedValue: '${p.value.toInt()}',
                barColor: p.color,
              )).toList(),
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

  const _LegendRow({required this.colors, required this.labels, required this.child});

  @override
  Widget build(BuildContext context) {
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
                    decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 4),
                  Text(labels[i], style: TextStyle(fontSize: 11, color: StreamColors.textSecondary)),
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

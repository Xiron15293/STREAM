import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/category.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/analytics_metrics.dart';
import '../widgets/charts/chart_empty_state.dart';
import '../widgets/charts/stream_bar_chart.dart';
import '../widgets/charts/stream_chart_card.dart';
import '../widgets/charts/stream_donut_chart.dart';
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_ChartSection>(
                    segments: const [
                      ButtonSegment(
                        value: _ChartSection.movements,
                        icon: Icon(Icons.swap_vert, size: 16),
                        label: Text('Movimenti', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: _ChartSection.categories,
                        icon: Icon(Icons.category, size: 16),
                        label: Text('Categorie', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: _ChartSection.accounts,
                        icon: Icon(Icons.account_balance, size: 16),
                        label: Text('Conti', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: _ChartSection.beneficiaries,
                        icon: Icon(Icons.person, size: 16),
                        label: Text('Beneficiari', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_section},
                    onSelectionChanged: (Set<_ChartSection> v) {
                      setState(() => _section = v.first);
                    },
                    showSelectedIcon: false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: KeyedSubtree(
                  key: const Key('charts_time_filter'),
                  child: TimeFilterBar(
                    activeFilter: _filter,
                    onChanged: (value) => setState(() => _filter = value),
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
                        ButtonSegment(value: MovementType.expense, label: Text('Uscite', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: MovementType.income, label: Text('Entrate', style: TextStyle(fontSize: 12))),
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
            child: StreamBarChart(series: cashflow, stacked: false),
          ),
        if (countByDay.isNotEmpty)
          StreamChartCard(
            title: 'Movimenti per giorno',
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
            child: StreamBarChart(series: topDays),
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
            child: StreamBarChart(series: top),
          ),
        if (composition.isNotEmpty)
          StreamChartCard(
            title: 'Composizione categorie',
            height: 180,
            child: StreamDonutChart(slices: composition),
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
            child: StreamBarChart(
              series: [
                ChartSeries(
                  label: 'Saldo',
                  points: balances,
                  color: StreamColors.primary,
                ),
              ],
            ),
          ),
        if (flows.isNotEmpty)
          StreamChartCard(
            title: 'Flussi per conto',
            child: StreamBarChart(series: flows),
          ),
        if (activity.isNotEmpty)
          StreamChartCard(
            title: 'Attività per conto',
            child: StreamBarChart(series: activity),
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
            child: StreamBarChart(series: top),
          ),
        if (freq.isNotEmpty)
          StreamChartCard(
            title: 'Frequenza beneficiari',
            child: StreamBarChart(series: freq),
          ),
      ],
    );
  }
}

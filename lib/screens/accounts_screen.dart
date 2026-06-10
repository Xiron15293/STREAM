import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../widgets/grouped_movements_list.dart';
import '../widgets/icon_picker.dart';
import '../widgets/calculator_amount_pad.dart';
import '../widgets/movement_picker.dart';
import '../widgets/time_filter_bar.dart';

class AccountsScreen extends StatefulWidget {
  final AppDatabase db;

  const AccountsScreen({super.key, required this.db});

  static const _typeLabels = {
    AccountType.cash: 'Contante',
    AccountType.bank: 'Banca',
    AccountType.card: 'Carta',
    AccountType.savings: 'Risparmio',
    AccountType.other: 'Altro',
  };

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late TimeFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conti')),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          final db = widget.db;
          final active = db.accounts.where((a) => !a.archived).toList();
          final archived = db.accounts.where((a) => a.archived).toList();
          final periodMovements = db.movements.filterByTime(_filter);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              StreamSpacing.lg,
              StreamSpacing.lg,
              StreamSpacing.lg,
              80,
            ),
            children: [
              KeyedSubtree(
                key: const Key('accounts_time_filter'),
                child: TimeFilterBar(
                  activeFilter: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ),
              const SizedBox(height: StreamSpacing.md),
              ...active.map(
                (a) => _AccountCard(
                  key: Key('account_card_${a.id}'),
                  db: db,
                  account: a,
                  periodMovements: periodMovements,
                  allMovements: db.movements,
                  filter: _filter,
                  onTap: () => _showAccountMovements(context, db, a),
                  onEdit: () => _showAddEditDialog(context, db, account: a),
                  onArchive: () => db.archiveAccount(a.id),
                ),
              ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: StreamSpacing.section),
                const KeyedSubtree(
                  key: Key('accounts_archived_section'),
                  child: _SectionHeader(title: 'Archiviati'),
                ),
                const SizedBox(height: StreamSpacing.md),
                ...archived.map(
                  (a) => _AccountCard(
                    key: Key('account_card_${a.id}'),
                    db: db,
                    account: a,
                    periodMovements: periodMovements,
                    allMovements: db.movements,
                    filter: _filter,
                    onTap: () => _showAccountMovements(context, db, a),
                    onEdit: () => _showAddEditDialog(context, db, account: a),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'accounts_fab',
        onPressed: () => _showAddEditDialog(context, widget.db),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAccountMovements(
    BuildContext context,
    AppDatabase db,
    Account account,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AccountMovementsSheet(
        db: db,
        account: account,
        initialFilter: _filter,
        onEdit: () => _showAddEditDialog(context, db, account: account),
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    AppDatabase db, {
    Account? account,
  }) {
    final nameController = TextEditingController(text: account?.name ?? '');
    final balanceController = TextEditingController(
      text: account?.initialBalance.toString() ?? '0',
    );
    AccountType selectedType = account?.type ?? AccountType.bank;
    int selectedColor = account?.color ?? StreamColorPalette.getDefault();
    String selectedIconKey =
        account?.iconKey ?? StreamIconLibrary.defaultAccountIcon;
    final currentMovementsDelta = account == null
        ? 0.0
        : db.getAccountBalance(account) - account.initialBalance;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(account == null ? 'Nuovo Conto' : 'Modifica Conto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: StreamSpacing.lg),
                DropdownButtonFormField<AccountType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(StreamRadius.md),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: StreamColors.surfaceElevated,
                  ),
                  items: AccountType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(_typeIcon(t), size: 20),
                              const SizedBox(width: 8),
                              Text(AccountsScreen._typeLabels[t]!),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: StreamSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bilancio',
                    style: StreamTypography.caption.copyWith(
                      color: StreamColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: StreamSpacing.sm),
                CalculatorAmountField(
                  fieldKey: const Key('account_initial_balance_field'),
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Saldo iniziale',
                  ),
                  allowNegative: true,
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: StreamSpacing.lg),
                Container(
                  key: const Key('account_current_balance_section'),
                  padding: const EdgeInsets.all(StreamSpacing.md),
                  decoration: BoxDecoration(
                    color: StreamColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(StreamRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo attuale',
                        style: StreamTypography.caption.copyWith(
                          color: StreamColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: StreamSpacing.xs),
                      Builder(
                        builder: (_) {
                          final parsedInitialBalance =
                              double.tryParse(
                                balanceController.text.replaceAll(',', '.'),
                              ) ??
                              0.0;
                          final currentBalance =
                              parsedInitialBalance + currentMovementsDelta;
                          return Text(
                            '${currentBalance >= 0 ? '+' : ''}${currentBalance.toStringAsFixed(2)} €',
                            key: const Key('account_current_balance_value'),
                            style: StreamTypography.amount.copyWith(
                              color: currentBalance >= 0
                                  ? StreamColors.income
                                  : StreamColors.expense,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: StreamSpacing.sm),
                      Text(
                        'Il saldo attuale viene calcolato automaticamente dai movimenti e dal saldo iniziale.',
                        key: const Key('account_balance_info_text'),
                        style: StreamTypography.caption.copyWith(
                          color: StreamColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StreamSpacing.lg),
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
                          context: ctx,
                          builder: (_) => IconPickerDialog(
                            currentIconKey: selectedIconKey,
                            isAccount: true,
                          ),
                        );
                        if (result != null) {
                          setDialogState(() => selectedIconKey = result);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: StreamColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(StreamRadius.md),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              StreamIconLibrary.getAccountIcon(selectedIconKey),
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              StreamIconLibrary.getAccountLabel(
                                selectedIconKey,
                              ),
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
                const SizedBox(height: StreamSpacing.lg),
                Text(
                  'Colore',
                  style: StreamTypography.caption.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                ColorPicker(
                  currentColor: selectedColor,
                  onChanged: (c) => setDialogState(() => selectedColor = c),
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
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final balance =
                    double.tryParse(
                      balanceController.text.replaceAll(',', '.'),
                    ) ??
                    0;
                if (account == null) {
                  db.addAccount(
                    Account(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      type: selectedType,
                      initialBalance: balance,
                      iconKey: selectedIconKey,
                      color: selectedColor,
                      createdAt: DateTime.now(),
                    ),
                  );
                } else {
                  db.updateAccount(
                    account.id,
                    name,
                    selectedType,
                    balance,
                    iconKey: selectedIconKey,
                    color: selectedColor,
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(account == null ? 'Crea' : 'Salva'),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return Icons.money;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.card:
        return Icons.credit_card;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.other:
        return Icons.account_balance_wallet;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: StreamTypography.h3.copyWith(color: StreamColors.textSecondary),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final AppDatabase db;
  final Account account;
  final List<Movement> periodMovements;
  final List<Movement> allMovements;
  final TimeFilter filter;

  const _AccountCard({
    super.key,
    required this.onTap,
    this.onEdit,
    this.onArchive,
    required this.db,
    required this.account,
    required this.periodMovements,
    required this.allMovements,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final accountPeriodMovements = periodMovements
        .where(
          (m) =>
              m.accountId == account.id || m.destinationAccountId == account.id,
        )
        .toList();
    final periodIncome = sumIncome(
      accountPeriodMovements.where(
        (m) => m.isIncome && m.accountId == account.id,
      ),
    );
    final periodExpenses = sumExpenses(
      accountPeriodMovements.where(
        (m) => m.isExpense && m.accountId == account.id,
      ),
    );
    final periodTransfersNet = periodTransferNetForAccount(
      account.id,
      accountPeriodMovements,
    );
    final periodStartBalance = balanceForAccountBefore(
      account.id,
      allMovements,
      filter.startDate,
      initialBalance: account.initialBalance,
    );
    final periodEndBalance = balanceForAccountUntil(
      account.id,
      allMovements,
      filter.endDate,
      initialBalance: account.initialBalance,
    );
    final iconData = StreamIconLibrary.getAccountIcon(account.iconKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StreamRadius.md),
          child: Container(
            padding: const EdgeInsets.all(StreamSpacing.lg),
            decoration: BoxDecoration(
              color: account.archived
                  ? StreamColors.surfaceElevated.withValues(alpha: 0.5)
                  : StreamColors.surface,
              borderRadius: BorderRadius.circular(StreamRadius.md),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: account.archived
                            ? Color(account.color).withValues(alpha: 0.3)
                            : Color(account.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(StreamRadius.md),
                      ),
                      child: Icon(
                        iconData,
                        color: account.archived
                            ? StreamColors.textMuted
                            : Color(account.color),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: StreamSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: account.archived
                                ? StreamTypography.bodyBold.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: StreamColors.textSecondary,
                                  )
                                : StreamTypography.bodyBold,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AccountsScreen._typeLabels[account.type] ?? '',
                            style: StreamTypography.caption.copyWith(
                              color: StreamColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatMoney(periodEndBalance),
                          key: const Key('account_current_balance'),
                          style: StreamTypography.amount.copyWith(
                            color: periodEndBalance >= 0
                                ? StreamColors.income
                                : StreamColors.expense,
                          ),
                        ),
                        Text(
                          _balanceLabel(filter),
                          style: StreamTypography.micro.copyWith(
                            color: StreamColors.textMuted,
                          ),
                        ),
                        if (!account.archived) ...[
                          const SizedBox(height: 2),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') {
                                onEdit?.call();
                              } else if (v == 'archive') {
                                onArchive?.call();
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
                              const PopupMenuItem(
                                value: 'archive',
                                child: Text('Archivia'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.md),
                _AccountPeriodSummary(
                  income: periodIncome,
                  expenses: periodExpenses,
                  transfersNet: periodTransfersNet,
                  startBalance: periodStartBalance,
                  endBalance: periodEndBalance,
                  movementCount: accountPeriodMovements.length,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} €';
  }

  String _balanceLabel(TimeFilter filter) {
    return 'Saldo al ${_formatDate(filter.endDate)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _AccountPeriodSummary extends StatelessWidget {
  final double income;
  final double expenses;
  final double transfersNet;
  final double startBalance;
  final double endBalance;
  final int movementCount;

  const _AccountPeriodSummary({
    required this.income,
    required this.expenses,
    required this.transfersNet,
    required this.startBalance,
    required this.endBalance,
    required this.movementCount,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('account_period_summary'),
      spacing: StreamSpacing.sm,
      runSpacing: StreamSpacing.sm,
      children: [
        _PeriodMetric(
          key: const Key('account_period_income'),
          label: 'Entrate',
          value: _formatMoney(income),
          color: StreamColors.income,
        ),
        _PeriodMetric(
          key: const Key('account_period_expense'),
          label: 'Uscite',
          value: _formatMoney(expenses),
          color: StreamColors.expense,
        ),
        _PeriodMetric(
          key: const Key('account_period_transfer_net'),
          label: 'Trasf.',
          value: _formatMoney(transfersNet),
          color: transfersNet >= 0 ? StreamColors.income : StreamColors.expense,
        ),
        _PeriodMetric(
          key: const Key('account_period_movement_count'),
          label: 'Movimenti',
          value: '$movementCount',
          color: StreamColors.textPrimary,
        ),
        _PeriodMetric(
          key: const Key('account_period_start_balance'),
          label: 'Saldo ini.',
          value: _formatMoney(startBalance),
          color: startBalance >= 0 ? StreamColors.income : StreamColors.expense,
        ),
        _PeriodMetric(
          key: const Key('account_period_end_balance'),
          label: 'Saldo fine',
          value: _formatMoney(endBalance),
          color: endBalance >= 0 ? StreamColors.income : StreamColors.expense,
        ),
      ],
    );
  }

  String _formatMoney(double value) {
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} €';
  }
}

class _PeriodMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PeriodMetric({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(
        horizontal: StreamSpacing.sm,
        vertical: StreamSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: StreamColors.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StreamTypography.captionBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _AccountMovementsSheet extends StatefulWidget {
  final AppDatabase db;
  final Account account;
  final TimeFilter? initialFilter;
  final VoidCallback onEdit;

  const _AccountMovementsSheet({
    required this.db,
    required this.account,
    required this.onEdit,
    this.initialFilter,
  });

  @override
  State<_AccountMovementsSheet> createState() => _AccountMovementsSheetState();
}

class _AccountMovementsSheetState extends State<_AccountMovementsSheet> {
  late TimeFilter _filter;

  Account get _account {
    return widget.db.accounts.firstWhere(
      (a) => a.id == widget.account.id,
      orElse: () => widget.account,
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = widget.initialFilter ?? TimeFilter.month(now.year, now.month);
  }

  List<Movement> get _accountMovements {
    final account = _account;
    return widget.db.movements
        .where(
          (m) =>
              m.accountId == account.id || m.destinationAccountId == account.id,
        )
        .toList()
        .filterByTime(_filter);
  }

  double get _filteredIncome => sumIncome(
    _accountMovements.where((m) => m.isIncome && m.accountId == _account.id),
  );

  double get _filteredExpenses => sumExpenses(
    _accountMovements.where((m) => m.isExpense && m.accountId == _account.id),
  );

  double get _filteredTransfersNet =>
      periodTransferNetForAccount(_account.id, _accountMovements);

  void _showAddMovement({MovementType initialType = MovementType.expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MovementPicker(
        db: widget.db,
        accountPreFill: _account.id,
        initialType: initialType,
      ),
    );
  }

  Future<void> _archiveAccount() async {
    if (_account.archived) return;
    await widget.db.archiveAccount(_account.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
        final account = _account;
        final movements = _accountMovements;
        final periodStartBalance = balanceForAccountBefore(
          account.id,
          widget.db.movements,
          _filter.startDate,
          initialBalance: account.initialBalance,
        );
        final periodEndBalance = balanceForAccountUntil(
          account.id,
          widget.db.movements,
          _filter.endDate,
          initialBalance: account.initialBalance,
        );
        final hasMovements = movements.isNotEmpty;

        return FractionallySizedBox(
          heightFactor: 1.0,
          child: Padding(
            key: const Key('account_interactive_sheet'),
            padding: const EdgeInsets.fromLTRB(
              StreamSpacing.lg,
              StreamSpacing.lg,
              StreamSpacing.lg,
              StreamSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: const Key('account_sheet_header'),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Color(account.color).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          StreamIconLibrary.getAccountIcon(account.iconKey),
                          color: Color(account.color),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: StreamSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Movimenti del conto',
                              style: StreamTypography.captionBold.copyWith(
                                color: StreamColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              account.name,
                              key: const Key('account_movements_name'),
                              style: StreamTypography.h2,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              account.archived ? 'Archiviato' : 'Attivo',
                              style: StreamTypography.caption.copyWith(
                                color: StreamColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('account_movements_close_button'),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                KeyedSubtree(
                  key: const Key('account_sheet_period_summary'),
                  child: Wrap(
                    spacing: StreamSpacing.sm,
                    runSpacing: StreamSpacing.sm,
                    children: [
                      KeyedSubtree(
                        key: const Key('account_movements_current_balance'),
                        child: _StatChip(
                          label: _balanceLabel(_filter),
                          value: _formatMoney(periodEndBalance),
                          key: const Key('account_sheet_balance_as_of'),
                        ),
                      ),
                      _StatChip(
                        label: 'Saldo iniziale',
                        value: _formatMoney(account.initialBalance),
                        key: const Key('account_movements_initial_balance'),
                      ),
                      KeyedSubtree(
                        key: const Key('account_movements_income'),
                        child: _StatChip(
                          label: 'Entrate periodo',
                          value: _formatMoney(_filteredIncome),
                          key: const Key('account_sheet_income'),
                        ),
                      ),
                      KeyedSubtree(
                        key: const Key('account_movements_expenses'),
                        child: _StatChip(
                          label: 'Uscite periodo',
                          value: _formatMoney(_filteredExpenses),
                          key: const Key('account_sheet_expense'),
                        ),
                      ),
                      KeyedSubtree(
                        key: const Key('account_movements_transfers'),
                        child: _StatChip(
                          label: 'Trasferimenti netti',
                          value: _formatMoney(_filteredTransfersNet),
                          key: const Key('account_sheet_transfer_net'),
                        ),
                      ),
                      _StatChip(
                        label: 'Saldo inizio periodo',
                        value: _formatMoney(periodStartBalance),
                        key: const Key('account_movements_start_balance'),
                      ),
                      KeyedSubtree(
                        key: const Key('account_movements_count'),
                        child: _StatChip(
                          label: 'Movimenti',
                          value: '${movements.length}',
                          key: const Key('account_sheet_movement_count'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                Wrap(
                  spacing: StreamSpacing.sm,
                  runSpacing: StreamSpacing.sm,
                  children: [
                    _SheetActionButton(
                      key: const Key('account_sheet_add_movement_action'),
                      icon: Icons.add,
                      label: 'Movimento',
                      onPressed: () => _showAddMovement(),
                    ),
                    _SheetActionButton(
                      key: const Key('account_sheet_transfer_action'),
                      icon: Icons.compare_arrows,
                      label: 'Trasferisci',
                      onPressed: () =>
                          _showAddMovement(initialType: MovementType.transfer),
                    ),
                    _SheetActionButton(
                      key: const Key('account_sheet_edit_action'),
                      icon: Icons.edit,
                      label: 'Modifica',
                      onPressed: widget.onEdit,
                    ),
                    if (!account.archived)
                      _SheetActionButton(
                        key: const Key('account_sheet_archive_action'),
                        icon: Icons.archive_outlined,
                        label: 'Archivia',
                        onPressed: _archiveAccount,
                      ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.md),
                KeyedSubtree(
                  key: const Key('account_movements_time_filter'),
                  child: TimeFilterBar(
                    activeFilter: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                Expanded(
                  key: const Key('account_sheet_movements_list'),
                  child: hasMovements
                      ? GroupedMovementsList(
                          movements: movements,
                          db: widget.db,
                          showNotes: true,
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

  String _formatMoney(double value) {
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} €';
  }

  String _balanceLabel(TimeFilter filter) {
    return 'Saldo al ${_formatDate(filter.endDate)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
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

  const _StatChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: StreamColors.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: StreamSpacing.xs),
          Text(value, style: StreamTypography.bodyBold),
        ],
      ),
    );
  }
}

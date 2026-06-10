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
import '../widgets/time_filter_bar.dart';

class AccountsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conti')),
      body: ListenableBuilder(
        listenable: db,
        builder: (context, _) {
          final active = db.accounts.where((a) => !a.archived).toList();
          final archived = db.accounts.where((a) => a.archived).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              StreamSpacing.lg,
              StreamSpacing.lg,
              StreamSpacing.lg,
              80,
            ),
            children: [
              ...active.map(
                (a) => _AccountCard(
                  key: Key('account_card_${a.id}'),
                  db: db,
                  account: a,
                  onTap: () => _showAccountMovements(context, db, a),
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
                    onTap: () => _showAccountMovements(context, db, a),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'accounts_fab',
        onPressed: () => _showAddEditDialog(context, db),
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
      builder: (_) => _AccountMovementsSheet(db: db, account: account),
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
                              Text(_typeLabels[t]!),
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
  final AppDatabase db;
  final Account account;

  const _AccountCard({
    super.key,
    required this.onTap,
    required this.db,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final balance = db.getAccountBalance(account);
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
            child: Row(
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
                      '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)} €',
                      style: StreamTypography.amount.copyWith(
                        color: balance >= 0
                            ? StreamColors.income
                            : StreamColors.expense,
                      ),
                    ),
                    if (!account.archived) ...[
                      const SizedBox(height: 2),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') {
                            final screen = context
                                .findAncestorWidgetOfExactType<
                                  AccountsScreen
                                >();
                            screen?._showAddEditDialog(
                              context,
                              db,
                              account: account,
                            );
                          } else if (v == 'archive') {
                            db.archiveAccount(account.id);
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
          ),
        ),
      ),
    );
  }
}

class _AccountMovementsSheet extends StatefulWidget {
  final AppDatabase db;
  final Account account;

  const _AccountMovementsSheet({required this.db, required this.account});

  @override
  State<_AccountMovementsSheet> createState() => _AccountMovementsSheetState();
}

class _AccountMovementsSheetState extends State<_AccountMovementsSheet> {
  late TimeFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
  }

  List<Movement> get _accountMovements {
    return widget.db.movements
        .where(
          (m) =>
              m.accountId == widget.account.id ||
              m.destinationAccountId == widget.account.id,
        )
        .toList()
        .filterByTime(_filter);
  }

  double get _filteredIncome => _accountMovements
      .where(
        (m) =>
            m.type == MovementType.income && m.accountId == widget.account.id,
      )
      .fold(0.0, (sum, m) => sum + m.amount);

  double get _filteredExpenses => _accountMovements
      .where(
        (m) =>
            m.type == MovementType.expense && m.accountId == widget.account.id,
      )
      .fold(0.0, (sum, m) => sum + m.amount);

  double get _filteredTransfersNet => _accountMovements
      .where((m) => m.type == MovementType.transfer)
      .fold(0.0, (sum, m) => sum + m.impactForAccount(widget.account.id));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
        final account = widget.account;
        final currentBalance = widget.db.getAccountBalance(account);
        final movements = _accountMovements;
        final hasMovements = movements.isNotEmpty;

        return FractionallySizedBox(
          heightFactor: 0.95,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              StreamSpacing.lg,
              StreamSpacing.lg,
              StreamSpacing.lg,
              StreamSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Movimenti del conto',
                        style: StreamTypography.h2,
                      ),
                    ),
                    IconButton(
                      key: const Key('account_movements_close_button'),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  account.name,
                  key: const Key('account_movements_name'),
                  style: StreamTypography.h3.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                Wrap(
                  spacing: StreamSpacing.sm,
                  runSpacing: StreamSpacing.sm,
                  children: [
                    _StatChip(
                      label: 'Saldo iniziale',
                      value: _formatMoney(account.initialBalance),
                      key: const Key('account_movements_initial_balance'),
                    ),
                    _StatChip(
                      label: 'Entrate filtrate',
                      value: _formatMoney(_filteredIncome),
                      key: const Key('account_movements_income'),
                    ),
                    _StatChip(
                      label: 'Uscite filtrate',
                      value: _formatMoney(_filteredExpenses),
                      key: const Key('account_movements_expenses'),
                    ),
                    _StatChip(
                      label: 'Trasferimenti netti filtrati',
                      value: _formatMoney(_filteredTransfersNet),
                      key: const Key('account_movements_transfers'),
                    ),
                    _StatChip(
                      label: 'Saldo attuale',
                      value: _formatMoney(currentBalance),
                      key: const Key('account_movements_current_balance'),
                    ),
                    _StatChip(
                      label: 'Numero movimenti',
                      value: '${movements.length}',
                      key: const Key('account_movements_count'),
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.md),
                TimeFilterBar(
                  activeFilter: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: StreamSpacing.md),
                Expanded(
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

import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/account.dart';
import '../theme.dart';
import '../widgets/icon_picker.dart';

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
            padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.lg, 80),
            children: [
              ...active.map((a) => _AccountCard(db: db, account: a)),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: StreamSpacing.section),
                const _SectionHeader(title: 'Archiviati'),
                const SizedBox(height: StreamSpacing.md),
                ...archived.map((a) => _AccountCard(db: db, account: a)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, db),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, AppDatabase db, {Account? account}) {
    final nameController = TextEditingController(text: account?.name ?? '');
    final balanceController =
        TextEditingController(text: account?.initialBalance.toString() ?? '0');
    AccountType selectedType = account?.type ?? AccountType.bank;
    int selectedColor = account?.color ?? StreamColorPalette.getDefault();
    String selectedIconKey = account?.iconKey ?? StreamIconLibrary.defaultAccountIcon;

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
                      borderRadius: BorderRadius.all(Radius.circular(StreamRadius.md)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: StreamColors.surfaceElevated,
                  ),
                  items: AccountType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(children: [
                      Icon(_typeIcon(t), size: 20),
                      const SizedBox(width: 8),
                      Text(_typeLabels[t]!),
                    ]),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: StreamSpacing.lg),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(labelText: 'Saldo Iniziale'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: StreamSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Icona', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
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
                              size: 20, color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(StreamIconLibrary.getAccountLabel(selectedIconKey),
                                style: StreamTypography.caption),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 16, color: StreamColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.lg),
                Text('Colore', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
                const SizedBox(height: StreamSpacing.md),
                ColorPicker(
                  currentColor: selectedColor,
                  onChanged: (c) => setDialogState(() => selectedColor = c),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final balance = double.tryParse(balanceController.text.replaceAll(',', '.')) ?? 0;
                if (account == null) {
                  db.addAccount(Account(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                    type: selectedType,
                    initialBalance: balance,
                    iconKey: selectedIconKey,
                    color: selectedColor,
                    createdAt: DateTime.now(),
                  ));
                } else {
                  db.updateAccount(account.id, name, selectedType, balance, iconKey: selectedIconKey, color: selectedColor);
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
      case AccountType.cash: return Icons.money;
      case AccountType.bank: return Icons.account_balance;
      case AccountType.card: return Icons.credit_card;
      case AccountType.savings: return Icons.savings;
      case AccountType.other: return Icons.account_balance_wallet;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: StreamTypography.h3.copyWith(color: StreamColors.textSecondary));
  }
}

class _AccountCard extends StatelessWidget {
  final AppDatabase db;
  final Account account;

  const _AccountCard({required this.db, required this.account});

  @override
  Widget build(BuildContext context) {
    final balance = db.getAccountBalance(account);
    final iconData = StreamIconLibrary.getAccountIcon(account.iconKey);
    return Container(
      margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
      padding: const EdgeInsets.all(StreamSpacing.lg),
      decoration: BoxDecoration(
        color: account.archived ? StreamColors.surfaceElevated.withValues(alpha: 0.5) : StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: account.archived ? Color(account.color).withValues(alpha: 0.3) : Color(account.color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(StreamRadius.md),
            ),
            child: Icon(
              iconData,
              color: account.archived ? StreamColors.textMuted : Color(account.color),
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
                      ? StreamTypography.bodyBold.copyWith(decoration: TextDecoration.lineThrough, color: StreamColors.textSecondary)
                      : StreamTypography.bodyBold,
                ),
                const SizedBox(height: 2),
                Text(
                  AccountsScreen._typeLabels[account.type] ?? '',
                  style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
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
                  color: balance >= 0 ? StreamColors.income : StreamColors.expense,
                ),
              ),
              if (!account.archived) ...[
                const SizedBox(height: 2),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      final screen = context.findAncestorWidgetOfExactType<AccountsScreen>();
                      screen?._showAddEditDialog(context, db, account: account);
                    } else if (v == 'archive') {
                      db.archiveAccount(account.id);
                    }
                  },
                  icon: Icon(Icons.more_horiz, size: 18, color: StreamColors.textMuted),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    const PopupMenuItem(value: 'archive', child: Text('Archivia')),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

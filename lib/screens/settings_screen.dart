import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode, kProfileMode;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../services/backup_service.dart';
import '../theme.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppDatabase db;
  final Future<String> Function(AppDatabase db)? createPreResetBackup;

  const SettingsScreen({
    super.key,
    required this.db,
    this.createPreResetBackup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(StreamSpacing.lg),
        children: [
          Card(
            color: StreamColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(StreamSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backup & Restore', style: StreamTypography.h3),
                  const SizedBox(height: StreamSpacing.sm),
                  Text(
                    'Gestisci esportazione e ripristino dei dati del dispositivo.',
                    style: StreamTypography.body.copyWith(
                      color: StreamColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: StreamSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.backup_outlined,
                      color: StreamColors.primary,
                    ),
                    title: const Text('Backup & Restore'),
                    subtitle: const Text(
                      'Apri la schermata di esportazione e ripristino',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BackupScreen(db: db)),
                      );
                    },
                  ),
                  const Divider(height: StreamSpacing.lg),
                  _placeholderTile(
                    icon: Icons.file_download_outlined,
                    title: 'Import',
                    subtitle: 'Presto disponibile',
                  ),
                  _placeholderTile(
                    icon: Icons.file_upload_outlined,
                    title: 'Export',
                    subtitle: 'Presto disponibile',
                  ),
                  _placeholderTile(
                    icon: Icons.tune_outlined,
                    title: 'Preferenze',
                    subtitle: 'Presto disponibile',
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.info_outline,
                      color: StreamColors.primary,
                    ),
                    title: const Text('Info app'),
                    subtitle: const Text('Versione e dettagli dell\'app'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInfo(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: StreamSpacing.lg),
          Card(
            color: StreamColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(StreamSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aspetto', style: StreamTypography.h3),
                  const SizedBox(height: StreamSpacing.sm),
                  Text(
                    'Personalizza l\'interfaccia dell\'app.',
                    style: StreamTypography.body.copyWith(
                      color: StreamColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: StreamSpacing.md),
                  _CategoryLayoutTile(db: db),
                  const SizedBox(height: StreamSpacing.sm),
                  _MovementsViewModeTile(),
                ],
              ),
            ),
          ),
          const SizedBox(height: StreamSpacing.lg),
          Card(
            color: StreamColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(StreamSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dati', style: StreamTypography.h3),
                  const SizedBox(height: StreamSpacing.sm),
                  Text(
                    'Azioni distruttive e manutenzione dei dati locali.',
                    style: StreamTypography.body.copyWith(
                      color: StreamColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: StreamSpacing.md),
                  KeyedSubtree(
                    key: const Key('settings_reset_data_tile'),
                    child: ListTile(
                      key: const Key('reset_data_tile'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_forever_outlined,
                        color: StreamColors.expense,
                      ),
                      title: const Text('Reset dati app'),
                      subtitle: const Text(
                        'Cancella dati utente e ripristina i default',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _confirmReset(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final typedOk = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ResetDataDialog(),
    );
    if (typedOk != true || !context.mounted) return;

    try {
      await (createPreResetBackup ?? BackupService.createPreResetBackup)(db);
    } catch (e) {
      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Backup pre-reset fallito'),
          content: SingleChildScrollView(
            child: Text(
              'Non è stato possibile creare il backup automatico.\n\n'
              'Puoi continuare comunque, ma perderai la protezione del backup pre-reset.\n\n'
              'Errore: $e',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: StreamColors.expense,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continua'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    try {
      await db.resetAllData();
      await PreferencesService.clearForReset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dati app resettati')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore durante il reset: $e')));
    }
  }

  Future<void> _showInfo(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final env = _environmentLabel();
    final platform = _platformLabel();

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
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
                const Text('Info app', style: StreamTypography.h3),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: StreamSpacing.md),
            _infoRow('Versione', info.version),
            _infoRow('Build', info.buildNumber),
            _infoRow('Ambiente', env),
            _infoRow('Piattaforma', platform),
            _infoRow('Pacchetto', info.packageName),
          ],
        ),
      ),
    );
  }

  String _environmentLabel() {
    if (kReleaseMode) return 'Release';
    if (kProfileMode) return 'Profile';
    return 'Debug';
  }

  String _platformLabel() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    return Platform.operatingSystem;
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StreamSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: StreamTypography.body.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          Text(value, style: StreamTypography.bodyBold),
        ],
      ),
    );
  }

  Widget _placeholderTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: StreamColors.textSecondary),
      title: Text(title),
      subtitle: Text(subtitle),
      enabled: false,
    );
  }
}

class _CategoryLayoutTile extends StatefulWidget {
  final AppDatabase db;

  const _CategoryLayoutTile({required this.db});

  @override
  State<_CategoryLayoutTile> createState() => _CategoryLayoutTileState();
}

class _CategoryLayoutTileState extends State<_CategoryLayoutTile> {
  String _currentLayout = PreferencesService.defaultCategoryLayout;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final layout = await PreferencesService.loadCategoryLayout();
    if (mounted) setState(() => _currentLayout = layout);
  }

  String _layoutLabel(String value) {
    switch (value) {
      case 'groupedList':
        return 'Lista grouped';
      case 'streamCards':
        return 'Card Stream';
      case 'treemap':
        return 'Treemap';
      default:
        return 'Lista pulita';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.grid_view_outlined, color: StreamColors.primary),
      title: const Text('Modello categoria'),
      subtitle: Text(_layoutLabel(_currentLayout)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (_) => _CategoryLayoutDialog(current: _currentLayout),
        );
        if (result != null && result != _currentLayout) {
          await PreferencesService.saveCategoryLayout(result);
          if (mounted) setState(() => _currentLayout = result);
        }
      },
    );
  }
}

class _CategoryLayoutDialog extends StatefulWidget {
  final String current;

  const _CategoryLayoutDialog({required this.current});

  @override
  State<_CategoryLayoutDialog> createState() => _CategoryLayoutDialogState();
}

class _CategoryLayoutDialogState extends State<_CategoryLayoutDialog> {
  late String _selected;

  static const _options = [
    ('cleanList', 'Lista pulita', 'Elenco semplice e minimale'),
    ('groupedList', 'Lista grouped', 'Raggruppata con stile iOS'),
    ('streamCards', 'Card Stream', 'Card dettagliate in stile Stream'),
    ('treemap', 'Treemap', 'Mappa visuale dei totali per categoria'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modello categoria'),
      content: SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: _selected,
          onChanged: (v) {
            if (v != null) {
              setState(() => _selected = v);
              Navigator.of(context).pop(v);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _options.map((option) {
              final value = option.$1;
              final label = option.$2;
              final desc = option.$3;
              return RadioListTile<String>(
                title: Text(label),
                subtitle: Text(
                  desc,
                  style: StreamTypography.caption.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
                value: value,
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}

class _MovementsViewModeTile extends StatefulWidget {
  @override
  State<_MovementsViewModeTile> createState() => _MovementsViewModeTileState();
}

class _MovementsViewModeTileState extends State<_MovementsViewModeTile> {
  MovementsViewMode _currentMode = PreferencesService.defaultMovementsViewMode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await PreferencesService.loadMovementsViewMode();
    if (mounted) setState(() => _currentMode = mode);
  }

  String _modeLabel(MovementsViewMode mode) {
    switch (mode) {
      case MovementsViewMode.listHeatmap:
        return 'Lista + mini heatmap';
      case MovementsViewMode.calendar:
        return 'Calendario mensile';
      case MovementsViewMode.advancedHeatmap:
        return 'Heatmap avanzata';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('movements_view_mode_setting'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.calendar_view_month_outlined,
        color: StreamColors.primary,
      ),
      title: const Text('Modello Movimenti'),
      subtitle: Text(_modeLabel(_currentMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await showDialog<MovementsViewMode>(
          context: context,
          builder: (_) => _MovementsViewModeDialog(current: _currentMode),
        );
        if (result != null && result != _currentMode) {
          await PreferencesService.saveMovementsViewMode(result);
          if (mounted) setState(() => _currentMode = result);
        }
      },
    );
  }
}

class _MovementsViewModeDialog extends StatefulWidget {
  final MovementsViewMode current;

  const _MovementsViewModeDialog({required this.current});

  @override
  State<_MovementsViewModeDialog> createState() =>
      _MovementsViewModeDialogState();
}

class _MovementsViewModeDialogState extends State<_MovementsViewModeDialog> {
  late MovementsViewMode _selected;

  static const _options = [
    (
      MovementsViewMode.listHeatmap,
      'Lista + mini heatmap',
      'Elenco movimenti con barra spese mensile',
    ),
    (
      MovementsViewMode.calendar,
      'Calendario mensile',
      'Calendario heatmap con riepilogo giorno',
    ),
    (
      MovementsViewMode.advancedHeatmap,
      'Heatmap avanzata',
      'Heatmap grande con pannello giorno e filtri',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('movements_view_mode_dialog'),
      title: const Text('Modello Movimenti'),
      content: SingleChildScrollView(
        child: RadioGroup<MovementsViewMode>(
          groupValue: _selected,
          onChanged: (v) {
            if (v != null) {
              setState(() => _selected = v);
              Navigator.of(context).pop(v);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _options.map((option) {
              final value = option.$1;
              final label = option.$2;
              final desc = option.$3;
              return RadioListTile<MovementsViewMode>(
                key: Key('movements_view_mode_${value.name}'),
                title: Text(label),
                subtitle: Text(
                  desc,
                  style: StreamTypography.micro.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
                value: value,
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}

class _ResetDataDialog extends StatefulWidget {
  const _ResetDataDialog();

  @override
  State<_ResetDataDialog> createState() => _ResetDataDialogState();
}

class _ResetDataDialogState extends State<_ResetDataDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isConfirmed => _controller.text.trim().toUpperCase() == 'RESET';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset dati app?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Questa azione cancellerà movimenti, conti, categorie personalizzate, rapidi, preferiti e backup locali. Non può essere annullata.',
            ),
            const SizedBox(height: StreamSpacing.md),
            TextField(
              key: const Key('reset_data_confirm_field'),
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Digita RESET per continuare',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('reset_data_cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          key: const Key('reset_data_confirm_button'),
          style: FilledButton.styleFrom(backgroundColor: StreamColors.expense),
          onPressed: _isConfirmed
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Resetta'),
        ),
      ],
    );
  }
}

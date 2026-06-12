import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode, kProfileMode;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_icon_library.dart';
import '../services/backup_service.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';
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
            key: const Key('heatmap_settings_section'),
            color: StreamColors.surface,
            child: const Padding(
              padding: EdgeInsets.all(StreamSpacing.lg),
              child: _HeatmapSettingsSection(),
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

class _HeatmapSettingsSection extends StatefulWidget {
  const _HeatmapSettingsSection();

  @override
  State<_HeatmapSettingsSection> createState() =>
      _HeatmapSettingsSectionState();
}

class _HeatmapSettingsSectionState extends State<_HeatmapSettingsSection> {
  late HeatmapSettings _settings;
  late List<TextEditingController> _controllers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _settings = PreferencesService.heatmapSettingsNotifier.value;
    _controllers = _controllersFor(_settings);
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await PreferencesService.loadHeatmapSettings();
    if (!mounted) return;
    _applySettings(settings);
  }

  List<TextEditingController> _controllersFor(HeatmapSettings settings) {
    return settings.thresholds
        .map((value) => TextEditingController(text: _formatThreshold(value)))
        .toList();
  }

  void _applySettings(HeatmapSettings settings) {
    for (final controller in _controllers) {
      controller.dispose();
    }
    setState(() {
      _settings = settings;
      _controllers = _controllersFor(settings);
      _error = null;
    });
  }

  Future<void> _saveThresholds() async {
    final values = <double>[];
    for (final controller in _controllers) {
      final value = double.tryParse(controller.text.replaceAll(',', '.'));
      if (value == null) {
        setState(() => _error = 'Inserisci solo numeri validi.');
        return;
      }
      values.add(value);
    }

    if (!HeatmapSettings.validateThresholds(values)) {
      setState(() => _error = 'Le soglie devono essere positive e crescenti.');
      return;
    }

    final next = _settings.copyWith(thresholds: values);
    final saved = await PreferencesService.saveHeatmapSettings(next);
    if (!mounted) return;
    setState(() {
      _settings = saved ? next : _settings;
      _error = saved ? null : 'Configurazione non valida.';
    });
  }

  Future<void> _pickColor(int index) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Colore intensità'),
        content: Wrap(
          spacing: StreamSpacing.sm,
          runSpacing: StreamSpacing.sm,
          children: [
            for (final colorValue in StreamColorPalette.colors)
              InkWell(
                key: Key('heatmap_palette_color_$colorValue'),
                onTap: () => Navigator.of(context).pop(colorValue),
                borderRadius: BorderRadius.circular(StreamRadius.sm),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    borderRadius: BorderRadius.circular(StreamRadius.sm),
                    border: Border.all(
                      color: colorValue == _settings.colors[index]
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.16),
                      width: colorValue == _settings.colors[index] ? 2 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;

    final colors = List<int>.from(_settings.colors);
    colors[index] = selected;
    final next = _settings.copyWith(colors: colors);
    final saved = await PreferencesService.saveHeatmapSettings(next);
    if (!mounted) return;
    if (saved) setState(() => _settings = next);
  }

  Future<void> _restoreDefaults() async {
    await PreferencesService.restoreDefaultHeatmapSettings();
    if (!mounted) return;
    _applySettings(PreferencesService.defaultHeatmapSettings);
  }

  @override
  Widget build(BuildContext context) {
    final bands = _settings.bands;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Heatmap', style: StreamTypography.h3),
        const SizedBox(height: StreamSpacing.sm),
        Text(
          'Colori e intervalli della heatmap Movimenti.',
          style: StreamTypography.body.copyWith(
            color: StreamColors.textSecondary,
          ),
        ),
        const SizedBox(height: StreamSpacing.md),
        _buildPreview(bands),
        const SizedBox(height: StreamSpacing.lg),
        Text('Soglie', style: StreamTypography.captionBold),
        const SizedBox(height: StreamSpacing.sm),
        KeyedSubtree(
          key: const Key('heatmap_thresholds_editor'),
          child: Column(
            children: [
              for (int i = 0; i < _controllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
                  child: TextField(
                    key: Key('heatmap_threshold_field_$i'),
                    controller: _controllers[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Soglia ${i + 1}',
                      suffixText: '€',
                      suffixIcon: IconButton(
                        key: const Key('heatmap_threshold_done_button'),
                        icon: const Icon(Icons.check, size: 18),
                        onPressed: () => FocusScope.of(context).unfocus(),
                        tooltip: 'Chiudi tastiera',
                      ),
                    ),
                    onChanged: (_) => _saveThresholds(),
                  ),
                ),
              if (_error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: StreamTypography.caption.copyWith(
                      color: StreamColors.expense,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: StreamSpacing.lg),
        Text('Colori', style: StreamTypography.captionBold),
        const SizedBox(height: StreamSpacing.sm),
        KeyedSubtree(
          key: const Key('heatmap_color_editor'),
          child: Column(
            children: [
              for (int i = 0; i < bands.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: KeyedSubtree(
                    key: const Key('heatmap_color_item'),
                    child: Container(
                      width: 34,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(_settings.colors[i]),
                        borderRadius: BorderRadius.circular(StreamRadius.sm),
                        border: Border.all(color: StreamColors.divider),
                      ),
                    ),
                  ),
                  title: Text(bands[i].label),
                  trailing: const Icon(Icons.palette_outlined),
                  onTap: () => _pickColor(i),
                ),
            ],
          ),
        ),
        const SizedBox(height: StreamSpacing.md),
        OutlinedButton.icon(
          key: const Key('heatmap_restore_defaults_button'),
          onPressed: _restoreDefaults,
          icon: const Icon(Icons.restore),
          label: const Text('Ripristina default'),
        ),
      ],
    );
  }

  Widget _buildPreview(List<({double max, String label})> bands) {
    return KeyedSubtree(
      key: const Key('heatmap_settings_preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 0; i < bands.length; i++)
                Expanded(
                  child: Container(
                    height: 28,
                    margin: EdgeInsets.only(
                      right: i == bands.length - 1 ? 0 : StreamSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Color(_settings.colors[i]),
                      borderRadius: BorderRadius.circular(StreamRadius.sm),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: StreamSpacing.sm),
          Wrap(
            spacing: StreamSpacing.sm,
            runSpacing: StreamSpacing.xs,
            children: [
              for (final band in bands)
                Text(
                  band.label,
                  style: StreamTypography.micro.copyWith(
                    color: StreamColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatThreshold(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
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
              textInputAction: TextInputAction.done,
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

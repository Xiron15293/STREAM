import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode, kProfileMode;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_kpi_style.dart';
import '../design/stream_theme_extension.dart';
import '../design/stream_theme_palette.dart';
import '../services/backup_service.dart';
import '../theme.dart';
import 'backup_screen.dart';
import 'heatmap_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppDatabase db;
  final Future<String> Function(AppDatabase db)? createPreResetBackup;
  final VoidCallback? onManageProfiles;
  final String? activeProfileId;

  const SettingsScreen({
    super.key,
    required this.db,
    this.createPreResetBackup,
    this.onManageProfiles,
    this.activeProfileId,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.$palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(StreamSpacing.lg),
        children: [
          _SettingsSectionCard(
            key: const Key('settings_backup_section'),
            title: 'Backup & Restore',
            description:
                'Gestisci esportazione e ripristino dei dati del dispositivo.',
            child: Column(
              children: [
                _SettingsTile(
                  key: const Key('settings_backup_restore_tile'),
                  icon: Icons.backup_outlined,
                  iconColor: palette.primary,
                  title: 'Backup & Restore',
                  subtitle: 'Apri la schermata di esportazione e ripristino',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BackupScreen(db: db)),
                    );
                  },
                ),
                _SettingsDivider(palette: palette),
                _placeholderTile(
                  context: context,
                  icon: Icons.file_download_outlined,
                  title: 'Import',
                  subtitle: 'Presto disponibile',
                ),
                _placeholderTile(
                  context: context,
                  icon: Icons.file_upload_outlined,
                  title: 'Export',
                  subtitle: 'Presto disponibile',
                ),
                _placeholderTile(
                  context: context,
                  icon: Icons.tune_outlined,
                  title: 'Preferenze',
                  subtitle: 'Presto disponibile',
                ),
                _SettingsDivider(palette: palette),
                _SettingsTile(
                  key: const Key('settings_info_tile'),
                  icon: Icons.info_outline,
                  iconColor: palette.primary,
                  title: 'Info app',
                  subtitle: 'Versione e dettagli dell\'app',
                  onTap: () => _showInfo(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: StreamSpacing.lg),
          _SettingsSectionCard(
            key: const Key('settings_heatmap_card'),
            title: 'Movimenti',
            description: 'Configura soglie e colori della heatmap Movimenti.',
            child: _SettingsTile(
              key: const Key('settings_heatmap_configure_tile'),
              icon: Icons.grid_view_rounded,
              iconColor: palette.primary,
              title: 'Configura heatmap',
              subtitle: 'Apri impostazioni soglie e colori',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HeatmapSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: StreamSpacing.lg),
          _SettingsSectionCard(
            key: const Key('settings_currency_card'),
            title: 'Valuta',
            description: 'Scegli il simbolo usato per mostrare gli importi.',
            child: ValueListenableBuilder<AppCurrency>(
              valueListenable: PreferencesService.currencyNotifier,
              builder: (context, currency, _) {
                return _SettingsTile(
                  key: const Key('settings_currency_tile'),
                  icon: Icons.payments_outlined,
                  iconColor: palette.primary,
                  title: 'Valuta',
                  subtitle: _currencyLabel(currency),
                  onTap: () => _showCurrencyPicker(context),
                );
              },
            ),
          ),
          const SizedBox(height: StreamSpacing.lg),
          _AppearanceSection(db: db),
          if (onManageProfiles != null) ...[
            const SizedBox(height: StreamSpacing.lg),
            _SettingsSectionCard(
              key: const Key('settings_profile_section'),
              title: 'Profilo',
              description:
                  'Gestisci il profilo attivo e le configurazioni collegate.',
              child: _SettingsTile(
                key: const Key('settings_active_profile_tile'),
                icon: Icons.person_outline,
                iconColor: palette.primary,
                title: 'Principale',
                subtitle: 'Profilo attivo',
                onTap: onManageProfiles,
              ),
            ),
          ],
          const SizedBox(height: StreamSpacing.lg),
          _SettingsSectionCard(
            key: const Key('settings_category_layout_section'),
            title: 'Categorie',
            description:
                'Personalizza il modello visuale della schermata categorie.',
            child: _CategoryLayoutTile(db: db),
          ),
          const SizedBox(height: StreamSpacing.lg),
          _SettingsSectionCard(
            key: const Key('settings_data_section'),
            title: 'Dati',
            description: 'Azioni distruttive e manutenzione dei dati locali.',
            child: KeyedSubtree(
              key: const Key('settings_reset_data_tile'),
              child: _SettingsTile(
                key: const Key('reset_data_tile'),
                icon: Icons.delete_forever_outlined,
                iconColor: palette.expense,
                title: 'Reset dati app',
                subtitle: 'Cancella dati utente e ripristina i default',
                accentColor: palette.expense,
                onTap: () => _confirmReset(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final palette = context.$palette;

    final selected = await showModalBottomSheet<AppCurrency>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        Widget tile(AppCurrency currency) {
          return ListTile(
            key: Key('currency_option_${currency.name}'),
            title: Text(
              _currencyLabel(currency),
              style: StreamTypography.body.copyWith(color: palette.textPrimary),
            ),
            trailing: PreferencesService.currencyNotifier.value == currency
                ? Icon(Icons.check, color: palette.primary)
                : null,
            iconColor: palette.textMuted,
            textColor: palette.textPrimary,
            onTap: () => Navigator.of(sheetContext).pop(currency),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: StreamSpacing.sm),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(StreamRadius.full),
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StreamSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Scegli valuta',
                          style: StreamTypography.h3.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(Icons.close, color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
                tile(AppCurrency.eur),
                tile(AppCurrency.usd),
                tile(AppCurrency.gbp),
                tile(AppCurrency.chf),
                tile(AppCurrency.jpy),
                const SizedBox(height: StreamSpacing.lg),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    await PreferencesService.saveCurrency(selected);
  }

  String _currencyLabel(AppCurrency currency) {
    return switch (currency) {
      AppCurrency.eur => 'EUR €',
      AppCurrency.usd => 'USD \$',
      AppCurrency.gbp => 'GBP £',
      AppCurrency.chf => 'CHF',
      AppCurrency.jpy => 'JPY ¥',
    };
  }

  Future<void> _confirmReset(BuildContext context) async {
    final palette = context.$palette;
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
          title: Text(
            'Backup pre-reset fallito',
            style: StreamTypography.h3.copyWith(color: palette.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Non è stato possibile creare il backup automatico.\n\n'
              'Puoi continuare comunque, ma perderai la protezione del backup pre-reset.\n\n'
              'Errore: $e',
              style: StreamTypography.body.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.expense,
                foregroundColor: Colors.white,
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
      await PreferencesService.clearForReset(
        activeProfileId: activeProfileId,
      );
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
    final palette = context.$palette;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
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
                Text(
                  'Info app',
                  style: StreamTypography.h3.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: palette.textMuted),
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
          Builder(
            builder: (context) {
              final palette = context.$palette;
              return Text(
                label,
                style: StreamTypography.body.copyWith(
                  color: palette.textSecondary,
                ),
              );
            },
          ),
          Builder(
            builder: (context) {
              final palette = context.$palette;
              return Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: StreamTypography.bodyBold.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _placeholderTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final palette = context.$palette;
    return _SettingsTile(
      icon: icon,
      iconColor: palette.textSecondary,
      title: title,
      subtitle: subtitle,
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
    final palette = context.$palette;

    return _SettingsTile(
      key: const Key('settings_category_layout_tile'),
      icon: Icons.grid_view_outlined,
      iconColor: palette.primary,
      title: 'Modello categoria',
      subtitle: _layoutLabel(_currentLayout),
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
    final palette = context.$palette;

    return AlertDialog(
      title: Text(
        'Modello categoria',
        style: StreamTypography.h3.copyWith(color: palette.textPrimary),
      ),
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
                activeColor: palette.primary,
                title: Text(label),
                subtitle: Text(
                  desc,
                  style: StreamTypography.caption.copyWith(
                    color: palette.textSecondary,
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
    final palette = context.$palette;

    return AlertDialog(
      title: Text(
        'Reset dati app?',
        style: StreamTypography.h3.copyWith(color: palette.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Questa azione cancellerà movimenti, conti, categorie personalizzate, rapidi, preferiti e backup locali. Non può essere annullata.',
              style: StreamTypography.body.copyWith(
                color: palette.textSecondary,
              ),
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
          style: FilledButton.styleFrom(
            backgroundColor: palette.expense,
            foregroundColor: Colors.white,
          ),
          onPressed: _isConfirmed
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Resetta'),
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatefulWidget {
  final AppDatabase db;
  const _AppearanceSection({required this.db});

  @override
  State<_AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<_AppearanceSection> {
  String _themeId = PreferencesService.themeIdNotifier.value;
  String _kpiStyle = PreferencesService.kpiStyleNotifier.value;
  String _chartStyle = PreferencesService.chartStyleNotifier.value;

  @override
  void initState() {
    super.initState();
    PreferencesService.themeIdNotifier.addListener(_onThemeChanged);
    PreferencesService.kpiStyleNotifier.addListener(_onKpiChanged);
    PreferencesService.chartStyleNotifier.addListener(_onChartChanged);
  }

  @override
  void dispose() {
    PreferencesService.themeIdNotifier.removeListener(_onThemeChanged);
    PreferencesService.kpiStyleNotifier.removeListener(_onKpiChanged);
    PreferencesService.chartStyleNotifier.removeListener(_onChartChanged);
    super.dispose();
  }

  void _onThemeChanged() =>
      setState(() => _themeId = PreferencesService.themeIdNotifier.value);
  void _onKpiChanged() =>
      setState(() => _kpiStyle = PreferencesService.kpiStyleNotifier.value);
  void _onChartChanged() =>
      setState(() => _chartStyle = PreferencesService.chartStyleNotifier.value);

  void _pickTheme() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(StreamRadius.xl),
        ),
      ),
      builder: (ctx) => _PickerSheet(
        title: 'Tema app',
        items: StreamThemeId.values
            .map((e) => _PickerItem(label: e.label, value: e.name))
            .toList(),
        selected: _themeId,
        onSelected: (v) => PreferencesService.saveThemeId(v),
      ),
    );
  }

  void _pickKpiStyle() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(StreamRadius.xl),
        ),
      ),
      builder: (ctx) => _PickerSheet(
        title: 'Stile KPI',
        items: StreamKpiStyleId.values
            .map((e) => _PickerItem(label: e.label, value: e.name))
            .toList(),
        selected: _kpiStyle,
        onSelected: (v) => PreferencesService.saveKpiStyleId(v),
      ),
    );
  }

  void _pickChartStyle() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(StreamRadius.xl),
        ),
      ),
      builder: (ctx) => _PickerSheet(
        title: 'Stile grafici',
        items: StreamChartStyleId.values
            .map(
              (e) => _PickerItem(
                label: e.label,
                value: e.name,
                tileKey: Key('settings_chart_style_option_${e.name}'),
                description: switch (e) {
                  StreamChartStyleId.automatic =>
                    'Usa lo stile piu coerente col tema',
                  StreamChartStyleId.soft =>
                    'Superfici leggere e colori piu calmi',
                  StreamChartStyleId.technical =>
                    'Griglie e assi piu leggibili',
                  StreamChartStyleId.highContrast =>
                    'Massima leggibilita e separazione visiva',
                  StreamChartStyleId.editorial =>
                    'Look pulito e presentabile',
                },
              ),
            )
            .toList(),
        selected: _chartStyle,
        onSelected: (v) => PreferencesService.saveChartStyleId(v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.$palette;
    final currentTheme = StreamThemeId.values.firstWhere(
      (e) => e.name == _themeId,
      orElse: () => StreamThemeId.streamClassic,
    );
    final currentKpi = StreamKpiStyleId.values.firstWhere(
      (e) => e.name == _kpiStyle,
      orElse: () => StreamKpiStyleId.automatic,
    );
    final currentChart = StreamChartStyleId.values.firstWhere(
      (e) => e.name == _chartStyle,
      orElse: () => StreamChartStyleId.automatic,
    );

    return _SettingsSectionCard(
      key: const Key('settings_chart_style_section'),
      title: 'Aspetto',
      description: 'Personalizza l\'interfaccia dell\'app.',
      child: Column(
        children: [
          _SettingsTile(
            key: const Key('settings_theme_picker_tile'),
            icon: Icons.palette_outlined,
            iconColor: palette.primary,
            title: 'Tema app',
            subtitle: currentTheme.label,
            onTap: _pickTheme,
          ),
          _SettingsDivider(palette: palette),
          _SettingsTile(
            key: const Key('settings_kpi_picker_tile'),
            icon: Icons.dashboard_customize_outlined,
            iconColor: palette.primary,
            title: 'Stile KPI',
            subtitle: currentKpi.label,
            onTap: _pickKpiStyle,
          ),
          _SettingsDivider(palette: palette),
          _SettingsTile(
            key: const Key('settings_chart_picker_tile'),
            icon: Icons.bar_chart_outlined,
            iconColor: palette.primary,
            title: 'Stile grafici',
            subtitle: currentChart.label,
            onTap: _pickChartStyle,
          ),
        ],
      ),
    );
  }
}

class _PickerItem {
  final String label;
  final String value;
  final String? description;
  final Key? tileKey;

  const _PickerItem({
    required this.label,
    required this.value,
    this.description,
    this.tileKey,
  });
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;
  final String selected;
  final ValueChanged<String> onSelected;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.$palette;

    return Container(
      key: Key('picker_sheet_${title.toLowerCase().replaceAll(' ', '_')}'),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(StreamRadius.xl),
        ),
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: StreamTypography.h3.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final isSelected = item.value == selected;
              return Column(
                children: [
                  _SettingsTile(
                    key:
                        item.tileKey ??
                        Key(
                          '${title.toLowerCase().replaceAll(' ', '_')}_${item.value}',
                        ),
                    icon: isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    iconColor: isSelected ? palette.primary : palette.textMuted,
                    title: item.label,
                    titleColor: isSelected
                        ? palette.primary
                        : palette.textPrimary,
                    subtitle: item.description ??
                        (isSelected
                            ? 'Selezionato'
                            : 'Tocca per selezionare'),
                    accentColor: isSelected ? palette.primary : null,
                    trailing: isSelected
                        ? Icon(Icons.check, color: palette.primary)
                        : null,
                    onTap: () {
                      onSelected(item.value);
                      Navigator.pop(context);
                    },
                  ),
                  if (item != items.last) _SettingsDivider(palette: palette),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _SettingsSectionCard({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.$palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        border: Border.all(color: palette.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.brightness == Brightness.dark ? 0.12 : 0.04,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: StreamTypography.h3.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: StreamSpacing.sm),
            Text(
              description,
              style: StreamTypography.body.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: StreamSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accentColor;
  final Color? titleColor;
  final bool enabled;

  const _SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.accentColor,
    this.titleColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.$palette;
    final effectiveAccent = accentColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: effectiveAccent == null
            ? Colors.transparent
            : effectiveAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: effectiveAccent == null
            ? null
            : Border.all(
                color: effectiveAccent.withValues(
                  alpha: palette.brightness == Brightness.dark ? 0.45 : 0.3,
                ),
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: StreamSpacing.sm,
            vertical: StreamSpacing.xs,
          ),
          leading: Icon(icon, color: enabled ? iconColor : palette.textMuted),
          minLeadingWidth: 28,
          title: Text(
            title,
            style: StreamTypography.bodyBold.copyWith(
              color: enabled
                  ? (titleColor ?? palette.textPrimary)
                  : palette.textMuted,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: StreamTypography.caption.copyWith(
              color: enabled ? palette.textSecondary : palette.textMuted,
            ),
          ),
          trailing:
              trailing ?? Icon(Icons.chevron_right, color: palette.textMuted),
          enabled: enabled,
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final StreamThemePalette palette;

  const _SettingsDivider({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Divider(height: 1, thickness: 1, color: palette.divider),
    );
  }
}

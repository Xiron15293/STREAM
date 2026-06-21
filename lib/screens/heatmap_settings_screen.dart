import 'package:flutter/material.dart';
import '../data/preferences_service.dart';
import '../design/stream_icon_library.dart';
import '../design/stream_theme_extension.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';

class HeatmapSettingsScreen extends StatefulWidget {
  const HeatmapSettingsScreen({super.key});

  @override
  State<HeatmapSettingsScreen> createState() => _HeatmapSettingsScreenState();
}

class _HeatmapSettingsScreenState extends State<HeatmapSettingsScreen> {
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
    final p = context.$palette;
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
                          ? p.textPrimary
                          : p.textPrimary.withValues(alpha: 0.16),
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
    final p = context.$palette;
    return Scaffold(
      key: const Key('heatmap_settings_screen'),
      appBar: AppBar(title: const Text('Configura heatmap')),
      body: ListView(
        padding: const EdgeInsets.all(StreamSpacing.lg),
        children: [
          Card(
            key: const Key('heatmap_settings_section'),
            color: p.surface,
            child: Padding(
              padding: const EdgeInsets.all(StreamSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Heatmap', style: StreamTypography.h3),
                  const SizedBox(height: StreamSpacing.sm),
                  Text(
                    'Colori e intervalli della heatmap Movimenti.',
                    style: StreamTypography.body.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: StreamSpacing.xs),
                  Text(
                    'Metrica principale: Totale uscite',
                    key: const Key('heatmap_primary_metric'),
                    style: StreamTypography.caption.copyWith(
                      color: p.textSecondary,
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
                            padding: const EdgeInsets.only(
                              bottom: StreamSpacing.sm,
                            ),
                            child: TextField(
                              key: Key('heatmap_threshold_field_$i'),
                              controller: _controllers[i],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                labelText: 'Soglia ${i + 1}',
                                suffixText: '€',
                                suffixIcon: IconButton(
                                  key: const Key(
                                    'heatmap_threshold_done_button',
                                  ),
                                  icon: const Icon(Icons.check, size: 18),
                                  onPressed: () =>
                                      FocusScope.of(context).unfocus(),
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
                                color: p.expense,
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
                                  borderRadius: BorderRadius.circular(
                                    StreamRadius.sm,
                                  ),
                                  border: Border.all(color: p.divider),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(List<({double max, String label})> bands) {
    final p = context.$palette;
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
                    color: p.textSecondary,
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

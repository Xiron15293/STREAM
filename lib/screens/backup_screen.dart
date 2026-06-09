import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../services/backup_service.dart';
import '../services/one_money_csv_import_service.dart';
import '../theme.dart';

class BackupScreen extends StatefulWidget {
  final AppDatabase db;

  const BackupScreen({super.key, required this.db});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String? _lastBackupDate;
  bool _exporting = false;
  bool _importing = false;
  String? _lastExportPath;
  List<String> _backupFiles = [];
  String? _importError;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
    _loadBackupFiles();
  }

  Future<String> _backupDirPath() async {
    try {
      final dir = Directory(p.join(await getDatabasesPath(), 'backups'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (_) {
      final dir = Directory(p.join(Directory.systemTemp.path, 'stream_backups'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }
  }

  Future<void> _loadLastBackupDate() async {
    final date = await PreferencesService.loadLastBackupDate();
    if (mounted) setState(() => _lastBackupDate = date);
  }

  Future<void> _loadBackupFiles() async {
    final dirPath = await _backupDirPath();
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      if (mounted) setState(() => _backupFiles = []);
      return;
    }
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (mounted) setState(() => _backupFiles = files.map((f) => f.path).toList());
  }

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _lastExportPath = null;
    });

    try {
      final dirPath = await _backupDirPath();
      final json = await BackupService.exportToJson(widget.db);
      final now = DateTime.now();
      final filename =
          'backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}.json';
      final file = File(p.join(dirPath, filename));
      await file.writeAsString(json);

      final dateStr =
          '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await PreferencesService.saveLastBackupDate(dateStr);

      if (mounted) {
        setState(() {
          _lastBackupDate = dateStr;
          _lastExportPath = file.path;
          _exporting = false;
        });
        _loadBackupFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup creato. Puoi esportarlo o conservarlo sul dispositivo.'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Condividi',
              onPressed: () => _shareFile(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _exporting = false);
        _showSnackBar('Errore durante il backup: $e');
      }
    }
  }

  Future<String> createPreRestoreBackup() async {
    final dirPath = await _backupDirPath();
    final json = await BackupService.exportToJson(widget.db);
    final now = DateTime.now();
    final filename =
        'backup_pre_restore_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}.json';
    final file = File(p.join(dirPath, filename));
    await file.writeAsString(json);
    return file.path;
  }

  Future<String> readFile(String path) async {
    return await File(path).readAsString();
  }

  Future<void> deleteFile(String path) async {
    await File(path).delete();
  }

  Future<void> _shareFile(String path) async {
    try {
      final file = XFile(path);
      await SharePlus.instance.share(
        ShareParams(files: [file], subject: 'Backup STREAM'),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Errore durante la condivisione: $e');
      }
    }
  }

  Future<void> _importFromFile(String filePath) async {
    try {
      final json = await readFile(filePath);
      await _import(json);
    } catch (e) {
      _showSnackBar('Errore di lettura file: $e');
    }
  }

  Future<void> _pickBackupFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) {
        _showSnackBar('Impossibile aprire il file selezionato');
        return;
      }

      await _importFromFile(path);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Errore nella selezione del file: $e');
      }
    }
  }

  Future<void> _pickOneMoneyCsvFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) {
        _showSnackBar('Impossibile aprire il file CSV selezionato');
        return;
      }

      final csv = await readFile(path);
      if (!mounted) return;
      setState(() {
        _importing = true;
        _importError = null;
      });

      final report = await OneMoneyCsvImportService.importCsv(widget.db, csv);

      if (!mounted) return;
      setState(() => _importing = false);
      await _showOneMoneyImportReport(report);
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        _showSnackBar('Errore durante l\'import CSV 1Money: $e');
      }
    }
  }

  Future<void> _import(String jsonString) async {
    final validation = BackupService.validate(jsonString);
    if (!validation.isValid) {
      if (mounted) {
        setState(() => _importError = validation.error);
        _showSnackBar(validation.error!);
      }
      return;
    }

    final data = validation.data!;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ripristinare backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('I dati correnti verranno sostituiti.'),
            const SizedBox(height: StreamSpacing.md),
            Text('Conti: ${data.accounts.length}'),
            Text('Categorie: ${data.categories.length}'),
            Text('Movimenti: ${data.movements.length}'),
            Text('Rapidi: ${data.quickMovements.length}'),
            Text('Preferiti: ${data.favoriteMovements.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _importing = true);

    try {
      await createPreRestoreBackup();
      await BackupService.restore(widget.db, data);

      if (mounted) {
        setState(() => _importing = false);
        _showSnackBar('Backup ripristinato con successo');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        _showSnackBar('Errore durante il ripristino: $e');
      }
    }
  }

  Future<void> _showOneMoneyImportReport(OneMoneyCsvImportReport report) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import CSV 1Money completato'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Movimenti letti: ${report.movementsRead}'),
              Text('Importati: ${report.importedMovements}'),
              Text('Saltati duplicati DB: ${report.duplicateDbMovements}'),
              Text('Duplicati interni file: ${report.duplicateWithinFileMovements}'),
              Text('Duplicati interni importati: ${report.duplicateWithinFileImportedMovements}'),
              Text('Saltati duplicati totali: ${report.duplicateMovements}'),
              Text('Conti creati: ${report.accountsCreated}'),
              Text('Categorie create: ${report.categoriesCreated}'),
              Text('Errori: ${report.errorCount}'),
              if (report.errors.isNotEmpty) ...[
                const SizedBox(height: StreamSpacing.md),
                Text(
                  'Dettagli errori',
                  style: StreamTypography.bodyBold.copyWith(color: StreamColors.textSecondary),
                ),
                const SizedBox(height: StreamSpacing.xs),
                ...report.errors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(bottom: StreamSpacing.xs),
                    child: Text(
                      error,
                      style: StreamTypography.caption.copyWith(color: StreamColors.expense),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(StreamSpacing.lg),
            children: [
              Card(
                color: StreamColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(StreamSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.file_upload_outlined, color: StreamColors.primary),
                          const SizedBox(width: StreamSpacing.md),
                          const Text('Esporta backup', style: StreamTypography.h3),
                        ],
                      ),
                      const SizedBox(height: StreamSpacing.sm),
                      Text(
                        'Crea una copia di tutti i tuoi dati in formato JSON.',
                        style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
                      ),
                      if (_lastBackupDate != null) ...[
                        const SizedBox(height: StreamSpacing.sm),
                        Text(
                          'Ultimo backup: $_lastBackupDate',
                          style: StreamTypography.caption.copyWith(color: StreamColors.income),
                        ),
                      ],
                      if (_lastExportPath != null) ...[
                        const SizedBox(height: StreamSpacing.xs),
                        Text(
                          _lastExportPath!,
                          style: StreamTypography.micro.copyWith(color: StreamColors.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: StreamSpacing.md),
                      FilledButton.icon(
                        onPressed: _exporting ? null : _export,
                        icon: _exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download),
                        label: Text(_exporting ? 'Esportazione...' : 'Esporta backup'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: StreamSpacing.md),
              Card(
                color: StreamColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(StreamSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.table_view_outlined, color: StreamColors.primary),
                          const SizedBox(width: StreamSpacing.md),
                          const Text('Importa CSV 1Money', style: StreamTypography.h3),
                        ],
                      ),
                      const SizedBox(height: StreamSpacing.sm),
                      Text(
                        'Importa il CSV esportato da 1Money. Supporta spesa, entrata e trasferimento con creazione automatica di conti e categorie mancanti.',
                        style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
                      ),
                      const SizedBox(height: StreamSpacing.sm),
                      Text(
                        'I duplicati vengono ignorati tramite fingerprint data + tipo + importo + conto + categoria + nota.',
                        style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
                      ),
                      const SizedBox(height: StreamSpacing.md),
                      FilledButton.icon(
                        onPressed: _importing ? null : _pickOneMoneyCsvFile,
                        icon: _importing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(_importing ? 'Importazione...' : 'Seleziona CSV 1Money'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: StreamSpacing.md),
              Card(
                color: StreamColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(StreamSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.file_download_outlined, color: StreamColors.warning),
                          const SizedBox(width: StreamSpacing.md),
                          const Text('Importa backup', style: StreamTypography.h3),
                        ],
                      ),
                      const SizedBox(height: StreamSpacing.sm),
                      Text(
                        'Ripristina i dati da un backup precedente.',
                        style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
                      ),
                      const SizedBox(height: StreamSpacing.sm),
                      Text(
                        'I dati attuali verranno sostituiti.',
                        style: StreamTypography.caption.copyWith(color: StreamColors.expense),
                      ),
                      if (_importError != null) ...[
                        const SizedBox(height: StreamSpacing.sm),
                        Text(
                          _importError!,
                          style: StreamTypography.caption.copyWith(color: StreamColors.expense),
                        ),
                      ],
                      const SizedBox(height: StreamSpacing.md),
                      if (_importing)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        FilledButton.icon(
                          onPressed: _pickBackupFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Seleziona file backup'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_backupFiles.isNotEmpty) ...[
                const SizedBox(height: StreamSpacing.md),
                Card(
                  color: StreamColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(StreamSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: StreamColors.textSecondary),
                            const SizedBox(width: StreamSpacing.md),
                            const Text('Backup salvati', style: StreamTypography.h3),
                          ],
                        ),
                        const SizedBox(height: StreamSpacing.sm),
                        ..._backupFiles.map((path) {
                          final filename = path.split('/').last;
                          return ListTile(
                            dense: true,
                            title: Text(filename, style: StreamTypography.body),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share, size: 20),
                                    tooltip: 'Condividi',
                                    onPressed: () => _shareFile(path),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.restore, size: 20),
                                    tooltip: 'Ripristina',
                                    onPressed: () => _importFromFile(path),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 20, color: StreamColors.expense),
                                    tooltip: 'Elimina',
                                    onPressed: () async {
                                      await deleteFile(path);
                                      _loadBackupFiles();
                                    },
                                  ),
                                ],
                              ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: StreamSpacing.lg),
              Text(
                'Il backup è salvato localmente sul dispositivo in formato JSON. '
                'Non viene inviato a server esterni. Puoi copiare il file per conservarlo '
                'al di fuori dell\'app.',
                style: StreamTypography.caption.copyWith(color: StreamColors.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}

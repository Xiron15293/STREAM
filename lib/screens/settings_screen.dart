import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode, kProfileMode;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/database.dart';
import '../theme.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppDatabase db;

  const SettingsScreen({super.key, required this.db});

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
                  Text(
                    'Backup & Restore',
                    style: StreamTypography.h3,
                  ),
                  const SizedBox(height: StreamSpacing.sm),
                  Text(
                    'Gestisci esportazione e ripristino dei dati del dispositivo.',
                    style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
                  ),
                  const SizedBox(height: StreamSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.backup_outlined, color: StreamColors.primary),
                    title: const Text('Backup & Restore'),
                    subtitle: const Text('Apri la schermata di esportazione e ripristino'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BackupScreen(db: db),
                        ),
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
                    leading: Icon(Icons.info_outline, color: StreamColors.primary),
                    title: const Text('Info app'),
                    subtitle: const Text('Versione e dettagli dell\'app'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInfo(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInfo(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final env = _environmentLabel();
    final platform = _platformLabel();

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.xxl),
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
          Text(label, style: StreamTypography.body.copyWith(color: StreamColors.textSecondary)),
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

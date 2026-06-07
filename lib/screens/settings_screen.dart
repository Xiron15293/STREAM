import 'package:flutter/material.dart';
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
                  _placeholderTile(
                    icon: Icons.info_outline,
                    title: 'Info app',
                    subtitle: 'Versione e dettagli dell’app',
                  ),
                ],
              ),
            ),
          ),
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

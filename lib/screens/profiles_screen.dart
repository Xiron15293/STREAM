import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/profiles_controller.dart';
import '../theme.dart';

class ProfilesScreen extends StatefulWidget {
  final ProfilesController profileService;
  final String? activeProfileId;
  final ValueChanged<Profile>? onProfileSelected;

  const ProfilesScreen({
    super.key,
    required this.profileService,
    this.activeProfileId,
    this.onProfileSelected,
  });

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final profiles = widget.profileService.profiles;
    final activeId = widget.activeProfileId;

    return Scaffold(
      key: const Key('profiles_screen'),
      appBar: AppBar(title: const Text('Profili')),
      body: ListView(
        padding: const EdgeInsets.all(StreamSpacing.lg),
        children: [
          ...profiles.map((profile) => _buildProfileCard(profile, activeId)),
          const SizedBox(height: StreamSpacing.md),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Profile profile, String? activeId) {
    final isActive = profile.id == activeId;
    return Card(
      key: Key('profiles_profile_item_${profile.id}'),
      color: isActive ? StreamColors.surfaceHighlight : StreamColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: profile.isMain
                        ? StreamColors.primary.withValues(alpha: 0.15)
                        : StreamColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(StreamRadius.md),
                  ),
                  child: Icon(
                    profile.isMain ? Icons.star : Icons.person_outline,
                    color: profile.isMain
                        ? StreamColors.primary
                        : StreamColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: StreamSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: StreamTypography.bodyBold),
                      if (isActive)
                        Text(
                          'Attivo',
                          key: Key('profiles_active_badge_${profile.id}'),
                          style: StreamTypography.caption.copyWith(
                            color: StreamColors.income,
                          ),
                        ),
                    ],
                  ),
                ),
                if (profile.isMain) _badge('Principale', StreamColors.primary),
              ],
            ),
            const SizedBox(height: StreamSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isActive)
                  TextButton.icon(
                    key: Key('profiles_switch_${profile.id}'),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Usa'),
                    onPressed: () => _switchToProfile(profile),
                  ),
                if (!profile.isMain)
                  TextButton.icon(
                    key: Key('profiles_rename_${profile.id}'),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: StreamColors.textSecondary,
                    ),
                    label: Text(
                      'Rinomina',
                      style: TextStyle(color: StreamColors.textSecondary),
                    ),
                    onPressed: () => _renameProfile(profile),
                  ),
                if (!profile.isMain)
                  TextButton.icon(
                    key: Key('profiles_delete_${profile.id}'),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: StreamColors.expense,
                    ),
                    label: Text(
                      'Elimina',
                      style: TextStyle(color: StreamColors.expense),
                    ),
                    onPressed: () => _deleteProfile(profile),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StreamSpacing.sm,
        vertical: StreamSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(StreamRadius.full),
      ),
      child: Text(
        label,
        style: StreamTypography.micro.copyWith(color: color),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Card(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        side: BorderSide(color: StreamColors.surfaceElevated, width: 1),
      ),
      child: InkWell(
        key: const Key('profiles_create_profile'),
        onTap: _creating ? null : _createProfile,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(StreamSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: StreamColors.primary, size: 20),
              const SizedBox(width: StreamSpacing.sm),
              Text(
                '+ Nuovo profilo',
                style: StreamTypography.bodyBold.copyWith(
                  color: StreamColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('profile_create_dialog'),
        title: const Text('Nuovo profilo'),
        content: TextField(
          key: const Key('profile_create_name_field'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nome profilo',
            hintText: 'es. Test import',
          ),
          onSubmitted: (value) {
            final text = value.trim();
            if (text.isNotEmpty) Navigator.of(ctx).pop(text);
          },
        ),
        actions: [
          TextButton(
            key: const Key('profile_create_cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            key: const Key('profile_create_confirm'),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(ctx).pop(text);
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    setState(() => _creating = true);
    try {
      final profile = await widget.profileService.createProfile(name);
      if (!mounted) return;

      final shouldSwitch = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Profilo creato'),
          content: Text('Ora vuoi entrare nel profilo "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Resta qui'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Entra'),
            ),
          ],
        ),
      );
      if (!mounted) return;

      if (shouldSwitch == true) {
        await widget.profileService.switchProfile(profile.id);
        widget.onProfileSelected?.call(profile);
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _renameProfile(Profile profile) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina profilo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nome profilo'),
          onSubmitted: (value) {
            final text = value.trim();
            if (text.isNotEmpty) Navigator.of(ctx).pop(text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(ctx).pop(text);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      await widget.profileService.renameProfile(profile.id, name);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare profilo?'),
        content: Text(
          'Tutti i dati del profilo "${profile.name}" verranno eliminati.',
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
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await widget.profileService.deleteProfile(profile.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  Future<void> _switchToProfile(Profile profile) async {
    await widget.profileService.switchProfile(profile.id);
    widget.onProfileSelected?.call(profile);
    if (mounted) Navigator.of(context).pop();
  }
}

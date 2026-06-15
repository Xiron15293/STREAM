import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/profile.dart';
import '../services/profiles_controller.dart';
import '../theme.dart';

class ProfilePickerScreen extends StatefulWidget {
  final ProfilesController profileService;
  final ValueChanged<Profile> onProfileSelected;

  const ProfilePickerScreen({
    super.key,
    required this.profileService,
    required this.onProfileSelected,
  });

  @override
  State<ProfilePickerScreen> createState() => _ProfilePickerScreenState();
}

class _ProfilePickerScreenState extends State<ProfilePickerScreen> {
  bool _creating = false;

  Future<void> _createProfile() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuovo profilo'),
        content: TextField(
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
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
      await widget.profileService.switchProfile(profile.id);
      if (!mounted) return;
      widget.onProfileSelected(profile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = widget.profileService.profiles;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: StreamColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(
                  Icons.account_balance_outlined,
                  size: 48,
                  color: StreamColors.primary,
                ),
                const SizedBox(height: StreamSpacing.md),
                Text(
                  'STREAM',
                  style: StreamTypography.h1.copyWith(
                    color: StreamColors.textPrimary,
                  ),
                ),
                const SizedBox(height: StreamSpacing.xs),
                Text(
                  'Scegli profilo',
                  style: StreamTypography.body.copyWith(
                    color: StreamColors.textSecondary,
                  ),
                ),
                const SizedBox(height: StreamSpacing.xxl),
                Expanded(
                  child: ListView.separated(
                    key: const Key('profile_picker_screen'),
                    itemCount: profiles.length + 2,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: StreamSpacing.md),
                    itemBuilder: (context, index) {
                      if (index < profiles.length) {
                        final profile = profiles[index];
                        return _ProfileCard(
                          key: Key('profile_picker_item_${profile.id}'),
                          profile: profile,
                          onTap: () async {
                            await widget.profileService.switchProfile(profile.id);
                            if (!mounted) return;
                            widget.onProfileSelected(profile);
                          },
                        );
                      }
                      if (index == profiles.length) {
                        return _ActionButton(
                          key: const Key('profile_picker_create_profile'),
                          icon: Icons.add,
                          label: '+ Nuovo profilo',
                          onTap: _creating ? null : _createProfile,
                        );
                      }
                      return const SizedBox(height: StreamSpacing.xxl);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _ProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: StreamColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(StreamSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: Text(profile.name, style: StreamTypography.bodyBold),
              ),
              if (profile.isMain)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StreamSpacing.sm,
                    vertical: StreamSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: StreamColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(StreamRadius.full),
                  ),
                  child: Text(
                    'Principale',
                    style: StreamTypography.micro.copyWith(
                      color: StreamColors.primary,
                    ),
                  ),
                ),
              const SizedBox(width: StreamSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: StreamColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        side: BorderSide(
          color: StreamColors.surfaceElevated,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(StreamSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: StreamColors.primary, size: 20),
              const SizedBox(width: StreamSpacing.sm),
              Text(
                label,
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
}

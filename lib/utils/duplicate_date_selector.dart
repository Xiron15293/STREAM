import 'package:flutter/material.dart';

import '../theme.dart';

Future<DateTime?> showDuplicateDateSheet(BuildContext context) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _DuplicateDateSheet(),
  );
}

class _DuplicateDateSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(StreamRadius.xl),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: StreamColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Duplica movimento',
            style: StreamTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Scegli la data del nuovo movimento',
            style: StreamTypography.caption.copyWith(
              color: StreamColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _DateOption(
            key: const Key('movement_duplicate_today'),
            label: 'Oggi',
            subtitle: '${today.day}/${today.month}/${today.year}',
            icon: Icons.today,
            onTap: () => Navigator.pop(context, today),
          ),
          const SizedBox(height: 8),
          _DateOption(
            key: const Key('movement_duplicate_tomorrow'),
            label: 'Domani',
            subtitle: '${today.add(const Duration(days: 1)).day}/${today.add(const Duration(days: 1)).month}/${today.add(const Duration(days: 1)).year}',
            icon: Icons.today,
            onTap: () => Navigator.pop(context, today.add(const Duration(days: 1))),
          ),
          const SizedBox(height: 8),
          _DateOption(
            key: const Key('movement_duplicate_yesterday'),
            label: 'Ieri',
            subtitle: '${today.subtract(const Duration(days: 1)).day}/${today.subtract(const Duration(days: 1)).month}/${today.subtract(const Duration(days: 1)).year}',
            icon: Icons.today,
            onTap: () => Navigator.pop(context, today.subtract(const Duration(days: 1))),
          ),
          const SizedBox(height: 8),
          _DateOption(
            key: const Key('movement_duplicate_pick_date'),
            label: 'Scegli data',
            subtitle: 'Calendario',
            icon: Icons.calendar_month,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: today,
                firstDate: today.subtract(const Duration(days: 365 * 10)),
                lastDate: today.add(const Duration(days: 365 * 10)),
                helpText: 'Scegli data',
                cancelText: 'Annulla',
                confirmText: 'Conferma',
              );
              if (picked != null && context.mounted) {
                Navigator.pop(context, picked);
              }
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('movement_duplicate_cancel'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
        ],
      ),
      ),
    );
  }
}

class _DateOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DateOption({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(StreamRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: StreamColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: StreamTypography.bodyBold,
                    ),
                    Text(
                      subtitle,
                      style: StreamTypography.caption.copyWith(
                        color: StreamColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

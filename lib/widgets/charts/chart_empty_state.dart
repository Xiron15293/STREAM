import 'package:flutter/material.dart';
import '../../design/stream_theme_extension.dart';
import '../../theme.dart';

class ChartEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const ChartEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.bar_chart,
  });

  @override
  Widget build(BuildContext context) {
    final cp = context.$chart;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: cp.emptyStateIconColor),
            const SizedBox(height: StreamSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: StreamTypography.bodyBold.copyWith(
                color: cp.emptyStateTextColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: StreamSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: StreamTypography.caption.copyWith(
                  color: cp.emptyStateTextColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

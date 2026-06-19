import 'package:flutter/material.dart';
import '../../theme.dart';

class ChartEmptyState extends StatelessWidget {
  final String message;

  const ChartEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 40, color: StreamColors.textMuted),
            const SizedBox(height: StreamSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

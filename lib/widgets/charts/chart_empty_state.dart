import 'package:flutter/material.dart';
import '../../design/stream_theme_extension.dart';
import '../../theme.dart';

class ChartEmptyState extends StatelessWidget {
  final String message;

  const ChartEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cp = context.$chart;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 40, color: cp.emptyStateIconColor),
            const SizedBox(height: StreamSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: StreamTypography.caption.copyWith(
                color: cp.emptyStateTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

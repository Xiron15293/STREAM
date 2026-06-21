import 'package:flutter/material.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import 'expense_heatmap.dart';

class MovementsHeatmapPreviewCard extends StatelessWidget {
  final List<Movement> allMovements;
  final int year;
  final int month;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final VoidCallback? onOpenSettings;

  const MovementsHeatmapPreviewCard({
    super.key,
    required this.allMovements,
    required this.year,
    required this.month,
    this.selectedDay,
    this.onDaySelected,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final surface = StreamSurfaceTokens.card(p, elevated: true);
    final monthLabel = TimeFilter.month(year, month).label;

    return Container(
      key: const Key('movements_list_heatmap_preview_card'),
      margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
      decoration: BoxDecoration(
        color: surface.background,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: Border.all(color: surface.border, width: surface.borderWidth),
        boxShadow: surface.shadows,
      ),
      child: Padding(
        padding: const EdgeInsets.all(StreamSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    monthLabel,
                    style: StreamTypography.captionBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: StreamSpacing.sm),
                Expanded(
                  child: ExpenseHeatmap(
                    key: const Key('movements_list_heatmap_preview_grid'),
                    allMovements: allMovements,
                    year: year,
                    month: month,
                    selectedDay: selectedDay,
                    onDaySelected: onDaySelected,
                    rowCompact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: StreamSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('movements_preview_configure_heatmap_button'),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Configura heatmap'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: StreamSpacing.sm,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onOpenSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

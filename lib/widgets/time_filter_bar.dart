import 'package:flutter/material.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import 'interval_picker_sheet.dart';
import 'time_filter_picker_sheets.dart';

class TimeFilterBar extends StatelessWidget {
  final TimeFilter activeFilter;
  final ValueChanged<TimeFilter> onChanged;
  final ValueChanged<DateTime>? onDatePicked;
  final String? customRangeLabel;
  final DateTime Function()? nowProvider;

  const TimeFilterBar({
    super.key,
    required this.activeFilter,
    required this.onChanged,
    this.onDatePicked,
    this.customRangeLabel,
    this.nowProvider,
  });

  void _onModeChanged(TimeFilterMode mode, BuildContext context) {
    final anchor = activeFilter.endDate;
    switch (mode) {
      case TimeFilterMode.day:
        onChanged(TimeFilter.day(anchor));
        break;
      case TimeFilterMode.week:
        onChanged(TimeFilter.week(anchor));
        break;
      case TimeFilterMode.month:
        onChanged(TimeFilter.month(anchor.year, anchor.month));
        break;
      case TimeFilterMode.year:
        onChanged(TimeFilter.year(anchor.year));
        break;
      case TimeFilterMode.customRange:
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _pickDate(context, forcedMode: TimeFilterMode.customRange),
        );
        break;
    }
  }

  Future<void> _pickDate(
    BuildContext context, {
    TimeFilterMode? forcedMode,
  }) async {
    switch (forcedMode ?? activeFilter.mode) {
      case TimeFilterMode.day:
        final picked = await showTimeFilterDayPicker(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onDatePicked?.call(picked);
          onChanged(TimeFilter.day(picked));
        }
        break;
      case TimeFilterMode.week:
        final picked = await showTimeFilterWeekPicker(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onDatePicked?.call(picked);
          onChanged(TimeFilter.week(picked));
        }
        break;
      case TimeFilterMode.month:
        final picked = await showTimeFilterMonthPicker(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onDatePicked?.call(picked);
          onChanged(TimeFilter.month(picked.year, picked.month));
        }
        break;
      case TimeFilterMode.year:
        final picked = await showTimeFilterYearPicker(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onDatePicked?.call(picked);
          onChanged(TimeFilter.year(picked.year));
        }
        break;
      case TimeFilterMode.customRange:
        final range = await showIntervalPicker(
          context: context,
          initialStart: activeFilter.startDate,
          initialEnd: activeFilter.endDate,
        );
        if (range != null) {
          onChanged(TimeFilter.customRange(range.start, range.end));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final selectedText = StreamSurfaceTokens.onAccent(p.primary);
    final pillSurface = StreamSurfaceTokens.card(p, elevated: true);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<TimeFilterMode>(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return p.primary;
                }
                return p.surfaceElevated;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return selectedText;
                }
                return p.textSecondary;
              }),
              side: WidgetStateProperty.resolveWith((states) {
                return BorderSide(
                  color: states.contains(WidgetState.selected)
                      ? p.primary
                      : p.divider,
                );
              }),
            ),
            segments: [
              const ButtonSegment(
                value: TimeFilterMode.day,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Giorno', maxLines: 1, softWrap: false),
                ),
              ),
              const ButtonSegment(
                value: TimeFilterMode.week,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Sett.', maxLines: 1, softWrap: false),
                ),
              ),
              const ButtonSegment(
                value: TimeFilterMode.month,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Mese', maxLines: 1, softWrap: false),
                ),
              ),
              const ButtonSegment(
                value: TimeFilterMode.year,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Anno', maxLines: 1, softWrap: false),
                ),
              ),
              ButtonSegment(
                value: TimeFilterMode.customRange,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    customRangeLabel ?? 'Intervallo',
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
            selected: {activeFilter.mode},
            onSelectionChanged: (Set<TimeFilterMode> v) {
              _onModeChanged(v.first, context);
            },
            showSelectedIcon: false,
          ),
          const SizedBox(height: StreamSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: p.textSecondary),
                  onPressed: () => onChanged(activeFilter.previous()),
                  tooltip: 'Precedente',
                ),
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pillSurface.background,
                      borderRadius: BorderRadius.circular(StreamRadius.md),
                      border: Border.all(
                        color: pillSurface.border,
                        width: pillSurface.borderWidth,
                      ),
                      boxShadow: pillSurface.shadows,
                    ),
                    child: Text(
                      activeFilter.label,
                      style: StreamTypography.h3.copyWith(color: p.textPrimary),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: p.textSecondary),
                  onPressed: () => onChanged(activeFilter.next()),
                  tooltip: 'Successivo',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

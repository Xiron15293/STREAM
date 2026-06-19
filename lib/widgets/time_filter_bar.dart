import 'package:flutter/material.dart';
import '../models/time_filter.dart';
import '../design/stream_date_picker.dart';
import '../theme.dart';
import 'interval_picker_sheet.dart';

class TimeFilterBar extends StatelessWidget {
  final TimeFilter activeFilter;
  final ValueChanged<TimeFilter> onChanged;
  final ValueChanged<DateTime>? onDatePicked;
  final String? customRangeLabel;

  const TimeFilterBar({
    super.key,
    required this.activeFilter,
    required this.onChanged,
    this.onDatePicked,
    this.customRangeLabel,
  });

  void _onModeChanged(TimeFilterMode mode, BuildContext context) {
    final s = activeFilter.startDate;
    switch (mode) {
      case TimeFilterMode.day:
        onChanged(TimeFilter.day(s));
      case TimeFilterMode.week:
        onChanged(TimeFilter.week(s));
      case TimeFilterMode.month:
        onChanged(TimeFilter.month(s.year, s.month));
      case TimeFilterMode.year:
        onChanged(TimeFilter.year(s.year));
      case TimeFilterMode.customRange:
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _pickDate(context, forcedMode: TimeFilterMode.customRange),
        );
    }
  }

  Future<void> _pickDate(
    BuildContext context, {
    TimeFilterMode? forcedMode,
  }) async {
    switch (forcedMode ?? activeFilter.mode) {
      case TimeFilterMode.day:
        final picked = await StreamDatePicker.show(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onDatePicked?.call(picked);
          onChanged(TimeFilter.day(picked));
        }
      case TimeFilterMode.week:
        final picked = await StreamDatePicker.show(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onDatePicked?.call(picked);
          onChanged(TimeFilter.week(picked));
        }
      case TimeFilterMode.month:
        final picked = await StreamDatePicker.show(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onDatePicked?.call(picked);
          onChanged(TimeFilter.month(picked.year, picked.month));
        }
      case TimeFilterMode.year:
        final picked = await StreamDatePicker.show(
          context: context,
          initialDate: DateTime(activeFilter.startDate.year, 6, 15),
        );
        if (picked != null) {
          onDatePicked?.call(picked);
          onChanged(TimeFilter.year(picked.year));
        }
      case TimeFilterMode.customRange:
        final range = await showIntervalPicker(
          context: context,
          initialStart: activeFilter.startDate,
          initialEnd: activeFilter.endDate,
        );
        if (range != null) {
          onChanged(TimeFilter.customRange(range.start, range.end));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<TimeFilterMode>(
            segments: [
              const ButtonSegment(value: TimeFilterMode.day, label: Text('Giorno')),
              const ButtonSegment(value: TimeFilterMode.week, label: Text('Sett.')),
              const ButtonSegment(value: TimeFilterMode.month, label: Text('Mese')),
              const ButtonSegment(value: TimeFilterMode.year, label: Text('Anno')),
              ButtonSegment(
                value: TimeFilterMode.customRange,
                label: Text(customRangeLabel ?? 'Intervallo'),
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
                  icon: const Icon(Icons.chevron_left),
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
                      color: StreamColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(StreamRadius.md),
                    ),
                    child: Text(activeFilter.label, style: StreamTypography.h3),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
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

import 'package:flutter/material.dart';
import '../models/time_filter.dart';
import '../design/stream_date_picker.dart';
import '../theme.dart';

class TimeFilterBar extends StatelessWidget {
  final TimeFilter activeFilter;
  final ValueChanged<TimeFilter> onChanged;

  const TimeFilterBar({
    super.key,
    required this.activeFilter,
    required this.onChanged,
  });

  void _onModeChanged(TimeFilterMode mode) {
    final s = activeFilter.startDate;
    TimeFilter newFilter;
    switch (mode) {
      case TimeFilterMode.day:
        newFilter = TimeFilter.day(s);
      case TimeFilterMode.month:
        newFilter = TimeFilter.month(s.year, s.month);
      case TimeFilterMode.year:
        newFilter = TimeFilter.year(s.year);
      case TimeFilterMode.customRange:
        newFilter = TimeFilter.month(s.year, s.month);
    }
    onChanged(newFilter);
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    switch (activeFilter.mode) {
      case TimeFilterMode.day:
        final picked = await StreamDatePicker.show(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onChanged(TimeFilter.day(picked));
        }
      case TimeFilterMode.month:
        final picked = await StreamDatePicker.show(
          context: context,
          initialDate: activeFilter.startDate,
        );
        if (picked != null) {
          onChanged(TimeFilter.month(picked.year, picked.month));
        }
      case TimeFilterMode.year:
        final picked = await StreamDatePicker.show(
          context: context,
          initialDate: DateTime(activeFilter.startDate.year, 6, 15),
        );
        if (picked != null) {
          onChanged(TimeFilter.year(picked.year));
        }
      case TimeFilterMode.customRange:
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(now.year + 1, 12, 31),
          initialDateRange: DateTimeRange(
            start: activeFilter.startDate,
            end: activeFilter.endDate.subtract(const Duration(days: 1)),
          ),
        );
        if (range != null) {
          onChanged(TimeFilter.customRange(
            range.start,
            range.end.add(const Duration(days: 1)),
          ));
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
            segments: const [
              ButtonSegment(
                value: TimeFilterMode.day,
                label: Text('Giorno'),
              ),
              ButtonSegment(
                value: TimeFilterMode.month,
                label: Text('Mese'),
              ),
              ButtonSegment(
                value: TimeFilterMode.year,
                label: Text('Anno'),
              ),
              ButtonSegment(
                value: TimeFilterMode.customRange,
                label: Text('Periodo'),
              ),
            ],
            selected: {activeFilter.mode},
            onSelectionChanged: (Set<TimeFilterMode> v) {
              _onModeChanged(v.first);
            },
            showSelectedIcon: false,
          ),
          const SizedBox(height: StreamSpacing.sm),
          Row(
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
                  child: Text(
                    activeFilter.label,
                    style: StreamTypography.h3,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onChanged(activeFilter.next()),
                tooltip: 'Successivo',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

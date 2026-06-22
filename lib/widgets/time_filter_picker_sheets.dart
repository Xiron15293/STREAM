import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../design/stream_date_picker.dart';
import '../design/stream_theme_extension.dart';
import '../models/time_filter.dart';
import '../theme.dart';

Future<DateTime?> showTimeFilterDayPicker({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return StreamDatePicker.show(context: context, initialDate: initialDate);
}

Future<DateTime?> showTimeFilterWeekPicker({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TimeFilterWeekPickerSheet(initialDate: initialDate),
  );
}

Future<DateTime?> showTimeFilterMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TimeFilterMonthYearWheelSheet(initialDate: initialDate),
  );
}

Future<DateTime?> showTimeFilterYearPicker({
  required BuildContext context,
  required DateTime initialDate,
}) {
  final startYear = initialDate.year - 50;
  return _showWheelPickerSheet(
    context: context,
    title: 'Seleziona anno',
    subtitle: 'Rotella dedicata agli anni',
    items: List.generate(101, (index) => '${startYear + index}'),
    initialIndex: 50,
    pickerKey: const Key('time_filter_year_picker'),
    cancelKey: const Key('time_filter_year_picker_cancel'),
    confirmKey: const Key('time_filter_year_picker_confirm'),
  ).then((index) => index == null ? null : DateTime(startYear + index, 1, 1));
}

Future<int?> _showWheelPickerSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<String> items,
  required int initialIndex,
  required Key pickerKey,
  required Key cancelKey,
  required Key confirmKey,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TimeFilterWheelPickerSheet(
      title: title,
      subtitle: subtitle,
      items: items,
      initialIndex: initialIndex,
      pickerKey: pickerKey,
      cancelKey: cancelKey,
      confirmKey: confirmKey,
    ),
  );
}

class _TimeFilterWeekPickerSheet extends StatelessWidget {
  final DateTime initialDate;

  const _TimeFilterWeekPickerSheet({required this.initialDate});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final selectedWeek = TimeFilter.week(initialDate);
    final selectedAnchor = DateTime(
      selectedWeek.startDate.year,
      selectedWeek.startDate.month,
      selectedWeek.startDate.day,
    );
    final weeks = List.generate(53, (index) {
      final offset = index - 26;
      return selectedAnchor.add(Duration(days: offset * 7));
    });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: StreamSpacing.lg,
          right: StreamSpacing.lg,
          top: StreamSpacing.lg,
          bottom: StreamSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(StreamRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(StreamSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seleziona settimana',
                        style: StreamTypography.h3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.xs),
                Text(
                  'Elenco settimane',
                  style: StreamTypography.caption.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                SizedBox(
                  height: 420,
                  child: ListView.separated(
                    key: const Key('time_filter_week_picker'),
                    itemCount: weeks.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, index) {
                      final anchor = weeks[index];
                      final week = TimeFilter.week(anchor);
                      final isSelected =
                          week.startDate == selectedWeek.startDate;
                      return ListTile(
                        key: Key(
                          'time_filter_week_option_${anchor.year}_${anchor.month}_${anchor.day}',
                        ),
                        selected: isSelected,
                        selectedTileColor: p.primary.withValues(alpha: 0.12),
                        title: Text(week.label),
                        subtitle: isSelected
                            ? Text(
                                'Settimana corrente',
                                style: TextStyle(color: p.textSecondary),
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check, color: p.primary)
                            : null,
                        onTap: () => Navigator.of(context).pop(anchor),
                      );
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

class _TimeFilterWheelPickerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> items;
  final int initialIndex;
  final Key pickerKey;
  final Key cancelKey;
  final Key confirmKey;

  const _TimeFilterWheelPickerSheet({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.initialIndex,
    required this.pickerKey,
    required this.cancelKey,
    required this.confirmKey,
  });

  @override
  State<_TimeFilterWheelPickerSheet> createState() =>
      _TimeFilterWheelPickerSheetState();
}

class _TimeFilterWheelPickerSheetState
    extends State<_TimeFilterWheelPickerSheet> {
  late final FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: StreamSpacing.lg,
          right: StreamSpacing.lg,
          top: StreamSpacing.lg,
          bottom: StreamSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(StreamRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(StreamSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.title, style: StreamTypography.h3),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.xs),
                Text(
                  widget.subtitle,
                  style: StreamTypography.caption.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(StreamRadius.lg),
                    border: Border.all(color: p.divider),
                  ),
                  child: CupertinoPicker(
                    key: widget.pickerKey,
                    scrollController: _controller,
                    itemExtent: 36,
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    children: [
                      for (final item in widget.items)
                        Center(
                          child: Text(item, style: StreamTypography.bodyBold),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: widget.cancelKey,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: StreamSpacing.md),
                    Expanded(
                      child: FilledButton(
                        key: widget.confirmKey,
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedIndex),
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeFilterMonthYearWheelSheet extends StatefulWidget {
  final DateTime initialDate;

  const _TimeFilterMonthYearWheelSheet({required this.initialDate});

  @override
  State<_TimeFilterMonthYearWheelSheet> createState() =>
      _TimeFilterMonthYearWheelSheetState();
}

class _TimeFilterMonthYearWheelSheetState
    extends State<_TimeFilterMonthYearWheelSheet> {
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;
  late int _selectedMonth;
  late int _selectedYear;
  static const int _yearRange = 50;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _yearController = FixedExtentScrollController(initialItem: _yearRange);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final startYear = widget.initialDate.year - _yearRange;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: StreamSpacing.lg,
          right: StreamSpacing.lg,
          top: StreamSpacing.lg,
          bottom: StreamSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(StreamRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(StreamSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seleziona mese',
                        style: StreamTypography.h3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.xs),
                Text(
                  'Rotella mese + anno',
                  style: StreamTypography.caption.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(StreamRadius.lg),
                    border: Border.all(color: p.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          key: const Key('time_filter_month_picker_month_wheel'),
                          scrollController: _monthController,
                          itemExtent: 36,
                          onSelectedItemChanged: (index) {
                            setState(() => _selectedMonth = index + 1);
                          },
                          children: List.generate(12, (index) {
                            final label =
                                TimeFilter.month(widget.initialDate.year, index + 1)
                                    .label;
                            return Center(
                              child: Text(
                                _capitalize(label.split(' ').first),
                                style: StreamTypography.bodyBold,
                              ),
                            );
                          }),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: p.divider,
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          key: const Key('time_filter_month_picker_year_wheel'),
                          scrollController: _yearController,
                          itemExtent: 36,
                          onSelectedItemChanged: (index) {
                            setState(() => _selectedYear = startYear + index);
                          },
                          children: List.generate(
                            _yearRange * 2 + 1,
                            (index) => Center(
                              child: Text(
                                '${startYear + index}',
                                style: StreamTypography.bodyBold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('time_filter_month_picker_cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: StreamSpacing.md),
                    Expanded(
                      child: FilledButton(
                        key: const Key('time_filter_month_picker_confirm'),
                        onPressed: () => Navigator.of(context).pop(
                          DateTime(_selectedYear, _selectedMonth, 15),
                        ),
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

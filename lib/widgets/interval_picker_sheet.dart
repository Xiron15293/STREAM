import 'package:flutter/material.dart';
import '../design/stream_date_picker.dart';
import '../theme.dart';

Future<DateTimeRange?> showIntervalPicker({
  required BuildContext context,
  required DateTime initialStart,
  required DateTime initialEnd,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _IntervalPickerSheet(
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}

class _IntervalPickerSheet extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;

  const _IntervalPickerSheet({
    required this.initialStart,
    required this.initialEnd,
  });

  @override
  State<_IntervalPickerSheet> createState() => _IntervalPickerSheetState();
}

class _IntervalPickerSheetState extends State<_IntervalPickerSheet> {
  late DateTime _start;
  late DateTime _end;
  bool _pickingStart = true;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    if (_end.isBefore(_start)) {
      _end = _start;
    }
  }

  bool get _isValid => !_end.isBefore(_start);

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$day/$month/$year';
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await StreamDatePicker.show(
      context: context,
      initialDate: isStart ? _start : _end,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _start = DateTime(picked.year, picked.month, picked.day);
          if (_end.isBefore(_start)) {
            _end = _start;
          }
        } else {
          _end = DateTime(picked.year, picked.month, picked.day);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: StreamColors.canvas,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(StreamRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: StreamSpacing.sm),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: StreamColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                StreamSpacing.lg,
                StreamSpacing.lg,
                StreamSpacing.lg,
                StreamSpacing.md,
              ),
              child: Text(
                'Seleziona intervallo',
                style: StreamTypography.h3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _DateCard(
                      label: 'Da',
                      date: _start,
                      formatted: _formatDate(_start),
                      isActive: _pickingStart,
                      onTap: () {
                        setState(() => _pickingStart = true);
                        _pickDate(true);
                      },
                    ),
                  ),
                  const SizedBox(width: StreamSpacing.md),
                  Expanded(
                    child: _DateCard(
                      label: 'A',
                      date: _end,
                      formatted: _formatDate(_end),
                      isActive: !_pickingStart,
                      onTap: () {
                        setState(() => _pickingStart = false);
                        _pickDate(false);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (!_isValid)
              Padding(
                padding: const EdgeInsets.only(top: StreamSpacing.sm),
                child: Text(
                  'La data fine deve essere uguale o successiva alla data inizio',
                  style: StreamTypography.caption.copyWith(
                    color: StreamColors.expense,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                StreamSpacing.lg,
                StreamSpacing.lg,
                StreamSpacing.lg,
                StreamSpacing.xxl,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StreamColors.textSecondary,
                        side: BorderSide(color: StreamColors.textMuted),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(StreamRadius.md),
                        ),
                      ),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: StreamSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isValid
                          ? () => Navigator.pop(
                                context,
                                DateTimeRange(start: _start, end: _end),
                              )
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(StreamRadius.md),
                        ),
                      ),
                      child: const Text('Applica'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final String formatted;
  final bool isActive;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.date,
    required this.formatted,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(StreamSpacing.md),
        decoration: BoxDecoration(
          color: isActive
              ? StreamColors.primary.withValues(alpha: 0.15)
              : StreamColors.surfaceElevated,
          borderRadius: BorderRadius.circular(StreamRadius.md),
          border: isActive
              ? Border.all(
                  color: StreamColors.primary.withValues(alpha: 0.5),
                )
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: StreamTypography.caption.copyWith(
                color: isActive
                    ? StreamColors.primary
                    : StreamColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: StreamSpacing.xs),
            Text(
              formatted,
              style: StreamTypography.bodyBold,
            ),
          ],
        ),
      ),
    );
  }
}

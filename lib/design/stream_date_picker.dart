import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StreamDatePicker {
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _showCupertino(context, initialDate: initialDate);
    }
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(DateTime.now().year + 1),
    );
  }

  static Future<DateTime?> _showCupertino(
    BuildContext context, {
    required DateTime initialDate,
  }) async {
    DateTime picked = initialDate;
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: CupertinoDatePicker(
                  initialDateTime: initialDate,
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (d) => picked = d,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('stream_date_picker_cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('stream_date_picker_ok'),
                      onPressed: () => Navigator.of(ctx).pop(
                        DateTime(picked.year, picked.month, picked.day),
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
    );
  }

  static String format(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String toDbDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

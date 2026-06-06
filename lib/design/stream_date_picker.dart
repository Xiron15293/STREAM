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
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        padding: const EdgeInsets.only(top: 16),
        child: CupertinoDatePicker(
          initialDateTime: initialDate,
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (d) => picked = d,
        ),
      ),
    );
    return picked;
  }

  static String format(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String toDbDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

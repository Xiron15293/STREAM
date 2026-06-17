import 'package:flutter/material.dart';

import '../data/database.dart';
import '../screens/beneficiaries_screen.dart';

Future<String?> showBeneficiaryPickerSheet(
  BuildContext context,
  AppDatabase db, {
  String? initialQuery,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return BeneficiariesScreen(
        db: db,
        pickerMode: true,
        initialQuery: initialQuery,
        onBeneficiarySelected: (value) {
          Navigator.of(sheetContext).pop(value);
        },
      );
    },
  );
}

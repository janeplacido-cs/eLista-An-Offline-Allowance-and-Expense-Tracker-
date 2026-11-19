import 'package:flutter/material.dart';

Future<DateTime?> showAllowanceEndDatePicker(
  BuildContext context, {
  DateTime? initialDate,
}) async {
  final today = DateUtils.dateOnly(DateTime.now());
  final candidate = initialDate == null
      ? today
      : DateUtils.dateOnly(initialDate);
  final selected = await showDatePicker(
    context: context,
    initialDate: candidate.isBefore(today) ? today : candidate,
    firstDate: today,
    lastDate: DateTime(today.year + 20, 12, 31),
  );
  return selected == null ? null : DateUtils.dateOnly(selected);
}

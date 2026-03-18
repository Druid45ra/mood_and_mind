extension DateOnlyExtension on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  String get localKey => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

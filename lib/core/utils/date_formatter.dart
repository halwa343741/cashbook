import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dayMonthYear = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _dayMonthYearTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMM yyyy', 'id_ID');
  static final DateFormat _timeOnly = DateFormat('HH:mm', 'id_ID');

  static String format(DateTime date) {
    return _dayMonthYear.format(date);
  }

  static String formatIndonesian(DateTime date) {
    return _dayMonthYear.format(date);
  }

  static String formatWithTime(DateTime date) {
    return _dayMonthYearTime.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeOnly.format(date);
  }

  static String formatGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Hari Ini, ${_dayMonthYear.format(date)}';
    } else if (target == today.subtract(const Duration(days: 1))) {
      return 'Kemarin, ${_dayMonthYear.format(date)}';
    }
    return _dayMonthYear.format(date);
  }
}

import 'package:intl/intl.dart';

class DateFormatter {
  static String _resolveLocale(String localeCode) {
    if (localeCode == 'en') return 'en_US';
    if (localeCode == 'es') return 'es_ES';
    if (localeCode == 'zh') return 'zh_CN';
    if (localeCode == 'ar') return 'ar_SA';
    return 'id_ID';
  }

  static String format(DateTime date, [String localeCode = 'id']) {
    final loc = _resolveLocale(localeCode);
    return DateFormat('dd MMM yyyy', loc).format(date);
  }

  static String formatIndonesian(DateTime date) => format(date, 'id');

  static String formatWithTime(DateTime date, [String localeCode = 'id']) {
    final loc = _resolveLocale(localeCode);
    final timePattern = (localeCode == 'en' || localeCode == 'ar')
        ? 'dd MMM yyyy, hh:mm a'
        : 'dd MMM yyyy, HH:mm';
    return DateFormat(timePattern, loc).format(date);
  }

  static String formatMonthYear(DateTime date, [String localeCode = 'id']) {
    final loc = _resolveLocale(localeCode);
    return DateFormat('MMM yyyy', loc).format(date);
  }

  static String formatTime(DateTime date, [String localeCode = 'id']) {
    final loc = _resolveLocale(localeCode);
    final pattern = (localeCode == 'en' || localeCode == 'ar') ? 'hh:mm a' : 'HH:mm';
    return DateFormat(pattern, loc).format(date);
  }

  static String formatGroupHeader(DateTime date, [String localeCode = 'id']) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final formatted = format(date, localeCode);

    if (target == today) {
      if (localeCode == 'en') return 'Today, $formatted';
      if (localeCode == 'es') return 'Hoy, $formatted';
      if (localeCode == 'zh') return '今天, $formatted';
      if (localeCode == 'ar') return 'اليوم، $formatted';
      return 'Hari Ini, $formatted';
    } else if (target == today.subtract(const Duration(days: 1))) {
      if (localeCode == 'en') return 'Yesterday, $formatted';
      if (localeCode == 'es') return 'Ayer, $formatted';
      if (localeCode == 'zh') return '昨天, $formatted';
      if (localeCode == 'ar') return 'أمس، $formatted';
      return 'Kemarin, $formatted';
    }
    return formatted;
  }
}

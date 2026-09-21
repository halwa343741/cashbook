import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    double amount, {
    bool showSign = false,
    bool isExpense = false,
    String localeCode = 'id',
  }) {
    final formatted = formatNumberOnly(amount, localeCode);
    if (showSign) {
      if (isExpense) {
        return '- $formatted';
      } else {
        return '+ $formatted';
      }
    }
    return formatted;
  }

  static String formatRupiah(double amount, [String localeCode = 'id']) =>
      format(amount, localeCode: localeCode);

  static String formatNumberOnly(double amount, [String localeCode = 'id']) {
    String locale;
    switch (localeCode) {
      case 'en':
        locale = 'en_US';
        break;
      case 'es':
        locale = 'es_ES';
        break;
      case 'zh':
        locale = 'zh_CN';
        break;
      case 'ar':
        locale = 'ar_SA';
        break;
      default:
        locale = 'id_ID';
    }
    return NumberFormat('#,###', locale).format(amount.abs());
  }

  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double parseRupiah(String text) => parse(text);

  static String getCurrencySymbol([String localeCode = 'id']) => '';
}

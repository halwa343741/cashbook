import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatterId = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _formatterEn = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$ ',
    decimalDigits: 0,
  );

  static final NumberFormat _formatterEs = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€ ',
    decimalDigits: 0,
  );

  static String format(
    double amount, {
    bool showSign = false,
    bool isExpense = false,
    String localeCode = 'id',
  }) {
    NumberFormat formatter;
    if (localeCode == 'en') {
      formatter = _formatterEn;
    } else if (localeCode == 'es') {
      formatter = _formatterEs;
    } else {
      formatter = _formatterId;
    }

    final formatted = formatter.format(amount.abs());
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
    final locale = localeCode == 'en' ? 'en_US' : (localeCode == 'es' ? 'es_ES' : 'id_ID');
    return NumberFormat('#,###', locale).format(amount.abs());
  }

  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double parseRupiah(String text) => parse(text);
}

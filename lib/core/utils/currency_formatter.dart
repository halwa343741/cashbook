import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberOnly = NumberFormat('#,###', 'id_ID');

  static String format(double amount, {bool showSign = false, bool isExpense = false}) {
    final formatted = _formatter.format(amount.abs());
    if (showSign) {
      if (isExpense) {
        return '- $formatted';
      } else {
        return '+ $formatted';
      }
    }
    return formatted;
  }

  static String formatRupiah(double amount) => format(amount);

  static String formatNumberOnly(double amount) {
    return _numberOnly.format(amount.abs());
  }

  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double parseRupiah(String text) => parse(text);
}

import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _vnd = NumberFormat.currency(
      locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  static String formatVND(num amount) => _vnd.format(amount);
}

import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9', decimalDigits: 2);
  static final _currencyNoDecimals = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9', decimalDigits: 0);
  static final _dayMonth = DateFormat('d MMM');
  static final _dayMonthYear = DateFormat('d MMM yyyy');
  static final _time = DateFormat('h:mm a');

  static String currency(double value) => _currency.format(value);
  static String currencyRounded(double value) => _currencyNoDecimals.format(value);
  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String dayMonthYear(DateTime d) => _dayMonthYear.format(d);
  static String date(DateTime d) => _dayMonthYear.format(d);
  static String time(DateTime d) => _time.format(d);

  static String relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return 'This Week';
    if (diff >= 7 && diff < 31) return 'Earlier This Month';
    if (diff < -1) return 'Upcoming';
    return dayMonthYear(d);
  }
}

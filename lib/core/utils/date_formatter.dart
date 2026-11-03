import 'package:intl/intl.dart';

abstract final class AppDateFormatter {
  static final DateFormat _full = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  static final DateFormat _short = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _month = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _day = DateFormat('EEEE', 'id_ID');
  static final DateFormat _dateOnly = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _fileDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _fileMonth = DateFormat('yyyy-MM');

  static String full(DateTime date) => _full.format(date);
  static String short(DateTime date) => _short.format(date);
  static String month(DateTime date) => _month.format(date);
  static String day(DateTime date) => _day.format(date);
  static String dateOnly(DateTime date) => _dateOnly.format(date);
  static String fileDate(DateTime date) => _fileDate.format(date);
  static String fileMonth(DateTime date) => _fileMonth.format(date);
}

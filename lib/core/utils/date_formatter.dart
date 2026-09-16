import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// e.g. "20 Sep 2026" (or Arabic month names when locale is ar)
  static String medium(DateTime date, {String localeCode = 'en'}) {
    return DateFormat('d MMM y', localeCode).format(date);
  }

  static String short(DateTime date, {String localeCode = 'en'}) {
    return DateFormat('dd/MM/y', localeCode).format(date);
  }

  static int daysUntil(DateTime dueDate) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final dueMidnight = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueMidnight.difference(todayMidnight).inDays;
  }

  static bool isOverdue(DateTime dueDate) => daysUntil(dueDate) < 0;
}

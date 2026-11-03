import 'package:lembur/features/leave/domain/leave_holidays.dart';

abstract final class LeaveCalculator {
  static const annualEntitlement = 12;

  // Use calendar dates in UTC so time zones and daylight saving cannot change a day count.
  static DateTime dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  static bool isWorkday(DateTime value) =>
      value.weekday <= DateTime.friday && !LeaveHolidays.isHoliday(value);

  static int workingDays(DateTime start, DateTime end) {
    var day = dateOnly(start);
    final last = dateOnly(end);
    var count = 0;
    while (!day.isAfter(last)) {
      if (isWorkday(day)) count++;
      day = day.add(const Duration(days: 1));
    }
    return count;
  }

  static DateTime returnDate(DateTime end) {
    var day = dateOnly(end).add(const Duration(days: 1));
    while (!isWorkday(day)) {
      day = day.add(const Duration(days: 1));
    }
    return DateTime(day.year, day.month, day.day);
  }

  static bool overlaps(
    DateTime start,
    DateTime end,
    DateTime otherStart,
    DateTime otherEnd,
  ) {
    final first =
        dateOnly(start).isAfter(dateOnly(otherStart)) ? start : otherStart;
    final last = dateOnly(end).isBefore(dateOnly(otherEnd)) ? end : otherEnd;
    return workingDays(first, last) > 0;
  }

  // Validate calendar coverage before presenting a count or producing a PDF.
  // Unpublished years must not silently fall back to counting weekdays only.
  static String? calendarError(DateTime start, DateTime end) {
    for (var year = start.year; year <= end.year; year++) {
      if (!LeaveHolidays.covers(year)) return _missingCalendar(year);
    }
    final back = returnDate(end);
    if (!LeaveHolidays.covers(back.year)) return _missingCalendar(back.year);
    return null;
  }

  static String _missingCalendar(int year) =>
      'Kalender libur $year belum tersedia. Perbarui aplikasi sebelum membuat surat untuk tanggal ini.';

  static String? validateRange(DateTime start, DateTime end) {
    if (dateOnly(end).isBefore(dateOnly(start))) {
      return 'Tanggal selesai harus sama atau setelah tanggal mulai.';
    }
    if (start.year != end.year) {
      return 'Buat surat terpisah untuk setiap tahun cuti.';
    }
    final missing = calendarError(start, end);
    if (missing != null) return missing;
    if (workingDays(start, end) == 0) {
      return 'Rentang ini hanya akhir pekan, libur nasional, atau cuti bersama. Pilih minimal satu hari kerja.';
    }
    return null;
  }
}

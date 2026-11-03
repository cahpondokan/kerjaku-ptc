import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/features/leave/domain/leave_calculator.dart';
import 'package:lembur/features/leave/domain/leave_holidays.dart';

void main() {
  test(
    'Inclusive weekday count skips both weekend days and time components',
    () {
      expect(
        LeaveCalculator.workingDays(
          DateTime(2026, 10, 23, 23),
          DateTime(2026, 10, 26, 1),
        ),
        2,
      );
      expect(
        LeaveCalculator.workingDays(
          DateTime(2026, 10, 26),
          DateTime(2026, 10, 26),
        ),
        1,
      );
      expect(
        LeaveCalculator.workingDays(
          DateTime(2026, 10, 19),
          DateTime(2026, 10, 30),
        ),
        10,
      );
    },
  );
  test('Return date skips Saturday and Sunday including year rollover', () {
    expect(
      LeaveCalculator.returnDate(DateTime(2026, 10, 23)),
      DateTime(2026, 10, 26),
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2026, 10, 24)),
      DateTime(2026, 10, 26),
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2026, 10, 25)),
      DateTime(2026, 10, 26),
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2026, 10, 26)),
      DateTime(2026, 10, 27),
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2026, 12, 31)),
      DateTime(2027, 1, 4),
    );
  });
  test('Weekend-only, reversed, and cross-year requests cannot be saved', () {
    expect(
      LeaveCalculator.validateRange(
        DateTime(2026, 10, 24),
        DateTime(2026, 10, 25),
      ),
      isNotNull,
    );
    expect(
      LeaveCalculator.validateRange(
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 23),
      ),
      isNotNull,
    );
    expect(
      LeaveCalculator.validateRange(
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
      ),
      isNotNull,
    );
  });
  test('National holidays and collective leave do not consume leave', () {
    expect(
      LeaveCalculator.workingDays(DateTime(2026, 8, 14), DateTime(2026, 8, 18)),
      2,
    );
    expect(
      LeaveCalculator.workingDays(DateTime(2026, 8, 17), DateTime(2026, 8, 17)),
      0,
    );
    expect(
      LeaveCalculator.workingDays(
        DateTime(2026, 12, 23),
        DateTime(2026, 12, 28),
      ),
      2,
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2026, 12, 23)),
      DateTime(2026, 12, 28),
    );
    expect(
      LeaveCalculator.validateRange(
        DateTime(2026, 12, 24),
        DateTime(2026, 12, 27),
      ),
      contains('minimal satu hari kerja'),
    );
  });
  test('Long holiday chains and the 2025 amendment are skipped', () {
    expect(
      LeaveCalculator.workingDays(DateTime(2025, 3, 27), DateTime(2025, 4, 8)),
      2,
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2025, 3, 27)),
      DateTime(2025, 4, 8),
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2025, 8, 15)),
      DateTime(2025, 8, 19),
    );
    expect(
      LeaveCalculator.workingDays(DateTime(2026, 3, 17), DateTime(2026, 3, 25)),
      2,
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2026, 3, 17)),
      DateTime(2026, 3, 25),
    );
    expect(
      LeaveCalculator.workingDays(DateTime(2027, 3, 5), DateTime(2027, 3, 16)),
      2,
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2027, 3, 5)),
      DateTime(2027, 3, 16),
    );
    expect(
      LeaveCalculator.returnDate(DateTime(2027, 1, 4)),
      DateTime(2027, 1, 6),
    );
  });
  test('Unverified years cannot produce silently incorrect letters', () {
    for (final year in [2024, 2028]) {
      expect(
        LeaveCalculator.validateRange(
          DateTime(year, 10, 23),
          DateTime(year, 10, 26),
        ),
        contains('Kalender libur $year belum tersedia'),
      );
    }
    expect(
      LeaveCalculator.validateRange(
        DateTime(2027, 12, 31),
        DateTime(2027, 12, 31),
      ),
      contains('Kalender libur 2028 belum tersedia'),
    );
    expect(
      LeaveCalculator.validateRange(
        DateTime(2026, 12, 31),
        DateTime(2026, 12, 31),
      ),
      isNull,
    );
  });
  test(
    'Bundled dates match official annual totals and normalize date/time',
    () {
      for (final (year, national, collective) in [
        (2025, 17, 11),
        (2026, 17, 8),
        (2027, 18, 8),
      ]) {
        final dates = LeaveHolidays.datesForYear(year);
        expect(dates, hasLength(national + collective));
        expect(dates.toSet(), hasLength(dates.length));
        expect(dates.where(LeaveHolidays.isCollective), hasLength(collective));
        for (final date in dates) {
          expect(LeaveCalculator.workingDays(date, date), 0);
        }
      }
      expect(
        LeaveCalculator.isWorkday(DateTime.utc(2026, 8, 17, 23, 59)),
        isFalse,
      );
      expect(LeaveCalculator.isWorkday(DateTime(2026, 12, 24, 12)), isFalse);
    },
  );
  test('Ranges sharing only holidays do not overlap working leave', () {
    expect(
      LeaveCalculator.overlaps(
        DateTime(2026, 12, 23),
        DateTime(2026, 12, 25),
        DateTime(2026, 12, 24),
        DateTime(2026, 12, 28),
      ),
      isFalse,
    );
  });
  test('Overlap is based on working days, not weekends shared by ranges', () {
    expect(
      LeaveCalculator.overlaps(
        DateTime(2026, 10, 23),
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 24),
        DateTime(2026, 10, 26),
      ),
      isFalse,
    );
    expect(
      LeaveCalculator.overlaps(
        DateTime(2026, 10, 23),
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 27),
      ),
      isTrue,
    );
  });
}

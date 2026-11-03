import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/core/utils/duration_calculator.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';

void main() {
  group('Konversi lembur hari kerja biasa', () {
    test('1 jam menjadi 1,5', () {
      expect(DurationCalculator.convertedHours(1, DayType.regular), 1.5);
    });
    test('2 jam menjadi 3,5', () {
      expect(DurationCalculator.convertedHours(2, DayType.regular), 3.5);
    });
    test('3 jam menjadi 5,5', () {
      expect(DurationCalculator.convertedHours(3, DayType.regular), 5.5);
    });
  });

  group('Konversi lembur hari libur', () {
    test('3 jam menjadi 6', () {
      expect(DurationCalculator.convertedHours(3, DayType.holiday), 6);
    });
    test('8 jam menjadi 16', () {
      expect(DurationCalculator.convertedHours(8, DayType.holiday), 16);
    });
    test('9 jam menjadi 19', () {
      expect(DurationCalculator.convertedHours(9, DayType.holiday), 19);
    });
    test('10 jam menjadi 23', () {
      expect(DurationCalculator.convertedHours(10, DayType.holiday), 23);
    });
  });
}

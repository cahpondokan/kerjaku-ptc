import 'package:flutter/material.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';

abstract final class DurationCalculator {
  static double actualHours(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    var endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60;
    }
    return (endMinutes - startMinutes) / 60;
  }

  static double convertedHours(double actual, DayType dayType) {
    if (actual <= 0) {
      return 0;
    }
    switch (dayType) {
      case DayType.regular:
        final firstHour = actual.clamp(0, 1).toDouble();
        final remaining = (actual - 1).clamp(0, double.infinity).toDouble();
        return firstHour * 1.5 + remaining * 2;
      case DayType.holiday:
        final firstEight = actual.clamp(0, 8).toDouble();
        final ninth = (actual - 8).clamp(0, 1).toDouble();
        final afterNinth = (actual - 9).clamp(0, double.infinity).toDouble();
        return firstEight * 2 + ninth * 3 + afterNinth * 4;
    }
  }

  static String displayHours(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

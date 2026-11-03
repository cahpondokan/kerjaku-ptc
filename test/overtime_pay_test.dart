import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/core/utils/duration_calculator.dart';
import 'package:lembur/core/utils/overtime_pay_calculator.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';
import 'package:lembur/features/overtime/domain/overtime_salary.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Salary selects basic + fixed or 75 percent without rounding cents', () {
    const standard = OvertimeSalary(basic: 4000000, fixed: 1190000);
    expect(standard.basisCents, 519000000);
    expect(standard.usesSeventyFivePercent, isFalse);
    const threshold = OvertimeSalary(
      basic: 2000000,
      fixed: 1000000,
      variable: 1000000,
    );
    expect(threshold.basisCents, 300000000);
    expect(threshold.usesSeventyFivePercent, isFalse);
    const floor = OvertimeSalary(
      basic: 2000000,
      fixed: 1000000,
      variable: 2000001,
    );
    expect(floor.basisCents, 375000075);
    expect(floor.usesSeventyFivePercent, isTrue);
    expect(const OvertimeSalary(basic: 0).isValid, isFalse);
    expect(const OvertimeSalary(basic: -1, fixed: 100).isValid, isFalse);
    expect(const OvertimeSalary(basic: 1000000000).isValid, isFalse);
  });

  test('Ordinary and 5-day holiday rates use exact converted time', () {
    for (final example in [
      (DayType.regular, 0.5, 22500),
      (DayType.regular, 1.0, 45000),
      (DayType.regular, 2.0, 105000),
      (DayType.regular, 3.0, 165000),
      (DayType.regular, 4.0, 225000),
      (DayType.regular, 1 / 60, 750),
      (DayType.regular, 61 / 60, 46000),
      (DayType.holiday, 8.0, 480000),
      (DayType.holiday, 8.5, 525000),
      (DayType.holiday, 9.0, 570000),
      (DayType.holiday, 10.0, 690000),
      (DayType.holiday, 12.0, 930000),
    ]) {
      final converted = DurationCalculator.convertedHours(
        example.$2,
        example.$1,
      );
      expect(
        OvertimePayCalculator.calculate(
          monthlyBasisCents: 519000000,
          convertedHours: converted,
        ),
        example.$3,
        reason: '$example',
      );
    }
  });

  test(
    'Only final rupiah is rounded, including half-rupiah and fractional basis',
    () {
      expect(
        OvertimePayCalculator.calculate(
          monthlyBasisCents: 500000000,
          convertedHours: 5.5,
        ),
        158960,
      );
      expect(
        OvertimePayCalculator.calculate(
          monthlyBasisCents: 17300,
          convertedHours: 1.5,
        ),
        2,
      );
      expect(
        OvertimePayCalculator.calculate(
          monthlyBasisCents: 375000075,
          convertedHours: 5.5,
        ),
        119220,
      );
      for (final invalid in [-1.0, double.nan, double.infinity]) {
        expect(
          () => OvertimePayCalculator.calculate(
            monthlyBasisCents: 519000000,
            convertedHours: invalid,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => OvertimePayCalculator.calculate(
          monthlyBasisCents: 0,
          convertedHours: 5.5,
        ),
        throwsArgumentError,
      );
    },
  );

  test('Currency input rejects malformed grouping, decimals and overflow', () {
    expect(OvertimePayCalculator.parseCents('5.190.000'), 519000000);
    expect(OvertimePayCalculator.parseCents('5190000'), 519000000);
    expect(OvertimePayCalculator.parseCents('5.190.000,25'), 519000025);
    expect(OvertimePayCalculator.parseCents('12,5'), 1250);
    expect(
      OvertimePayCalculator.parseCents('12,5', allowDecimals: false),
      isNull,
    );
    for (final invalid in [
      '',
      '-1',
      '1.23',
      '12,345',
      '1,000,000',
      'NaN',
      '9223372036854775807',
    ]) {
      expect(
        OvertimePayCalculator.parseCents(invalid),
        isNull,
        reason: invalid,
      );
    }
  });

  test(
    'Entry map preserves basis, old rows remain unpriced and unsupported hours are not guessed',
    () {
      final current = sampleEntry().copyWith(monthlyWageBasisCents: 519000000);
      final restored = OvertimeEntry.fromMap(current.toMap());
      expect(restored.estimatedPay, 165000);
      expect(restored.monthlyWageBasisCents, 519000000);
      final legacyMap =
          sampleEntry().toMap()..remove('monthly_wage_basis_cents');
      expect(OvertimeEntry.fromMap(legacyMap).estimatedPay, isNull);
      expect(
        restored
            .copyWith(dayType: DayType.holiday, actualHours: 13)
            .estimatedPay,
        isNull,
      );
      expect(restored.copyWith(actualHours: 0).estimatedPay, isNull);
    },
  );

  test(
    'Salary and privacy persist while saved historical pay remains unchanged',
    () async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.saveSalary(const OvertimeSalary(basic: 5190000));
      final oldEntry = sampleEntry().copyWith(
        monthlyWageBasisCents: settings.salary!.basisCents,
      );
      await settings.saveSalary(const OvertimeSalary(basic: 6920000));
      await settings.setHidePay(true);
      final reopened = SettingsProvider();
      await reopened.load();
      expect(reopened.salary!.basic, 6920000);
      expect(reopened.hidePay, isTrue);
      expect(oldEntry.estimatedPay, 165000);
      expect(reopened.documentsReady, isFalse);
      await expectLater(
        settings.saveSalary(const OvertimeSalary(basic: 0)),
        throwsStateError,
      );
      expect(settings.salary!.basic, 6920000);
    },
  );

  test(
    'Corrupt salary data does not prevent loading a worker profile',
    () async {
      SharedPreferences.setMockInitialValues({
        'overtime_salary_v1': '{broken',
        'profile_name': 'Budi',
      });
      final settings = SettingsProvider();
      await settings.load();
      expect(settings.loaded, isTrue);
      expect(settings.profile.name, 'Budi');
      expect(settings.salary, isNull);
    },
  );
}

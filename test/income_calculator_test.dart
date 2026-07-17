import 'package:facai/models/app_settings.dart';
import 'package:facai/services/income_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncomeCalculator', () {
    final settings = AppSettings(
      salaryMode: SalaryMode.monthly,
      monthlySalary: 22000,
      dailySalary: 1000,
      monthlyWorkdays: 22,
      workStartHour: 9,
      workStartMinute: 0,
      workEndHour: 18,
      workEndMinute: 0,
      regularWorkdays: {DateTime.monday, DateTime.tuesday, DateTime.wednesday},
      todayWorkOverride: true,
    );

    test('converts monthly salary into daily salary', () {
      expect(IncomeCalculator.dailySalary(settings), 1000);
    });

    test("keeps today's income at zero before work starts", () {
      final result = IncomeCalculator.snapshot(
        settings,
        DateTime(2026, 7, 17, 8, 30),
      );

      expect(result.todayIncome, 0);
      expect(result.isWorkingNow, isFalse);
    });

    test('accumulates income by worked seconds during work hours', () {
      final result = IncomeCalculator.snapshot(
        settings,
        DateTime(2026, 7, 17, 13, 30),
      );

      expect(result.todayIncome, closeTo(500, 0.01));
      expect(result.isWorkingNow, isTrue);
    });

    test('stops income at daily salary after work ends', () {
      final result = IncomeCalculator.snapshot(
        settings,
        DateTime(2026, 7, 17, 20, 0),
      );

      expect(result.todayIncome, 1000);
      expect(result.isWorkingNow, isFalse);
    });

    test('does not grow on a non-workday unless overridden', () {
      final restSettings = settings.copyWith(todayWorkOverride: false);
      final result = IncomeCalculator.snapshot(
        restSettings,
        DateTime(2026, 7, 17, 13, 30),
      );

      expect(result.todayIncome, 0);
      expect(result.isWorkday, isFalse);
    });
  });
}

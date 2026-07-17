import '../models/app_settings.dart';

class IncomeSnapshot {
  const IncomeSnapshot({
    required this.todayIncome,
    required this.dailySalary,
    required this.secondsUntilOffWork,
    required this.isWorkingNow,
    required this.isWorkday,
    required this.hasWorkEnded,
  });

  final double todayIncome;
  final double dailySalary;
  final int secondsUntilOffWork;
  final bool isWorkingNow;
  final bool isWorkday;
  final bool hasWorkEnded;

  String get countdownLabel {
    if (!isWorkday) {
      return '今天休息，发财能量蓄力中';
    }
    if (hasWorkEnded) {
      return '今日工资已收满，准备下班暴富';
    }

    final hours = secondsUntilOffWork ~/ 3600;
    final minutes = (secondsUntilOffWork % 3600) ~/ 60;
    final seconds = secondsUntilOffWork % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class IncomeCalculator {
  const IncomeCalculator._();

  static double dailySalary(AppSettings settings) {
    if (settings.salaryMode == SalaryMode.daily) {
      return settings.dailySalary < 0 ? 0 : settings.dailySalary;
    }
    final workdays = settings.monthlyWorkdays <= 0 ? 1 : settings.monthlyWorkdays;
    final salary = settings.monthlySalary < 0 ? 0 : settings.monthlySalary;
    return salary / workdays;
  }

  static double monthlySalary(AppSettings settings) {
    if (settings.salaryMode == SalaryMode.monthly) {
      return settings.monthlySalary < 0 ? 0 : settings.monthlySalary;
    }
    final workdays = settings.monthlyWorkdays <= 0 ? 1 : settings.monthlyWorkdays;
    final salary = settings.dailySalary < 0 ? 0 : settings.dailySalary;
    return salary * workdays;
  }

  static IncomeSnapshot snapshot(AppSettings settings, DateTime now) {
    final isWorkday = settings.isWorkday(now);
    final salary = dailySalary(settings);
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      settings.workStartHour,
      settings.workStartMinute,
    );
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      settings.workEndHour,
      settings.workEndMinute,
    );
    final totalSeconds = end.difference(start).inSeconds;

    if (!isWorkday || totalSeconds <= 0) {
      return IncomeSnapshot(
        todayIncome: 0,
        dailySalary: salary,
        secondsUntilOffWork: 0,
        isWorkingNow: false,
        isWorkday: false,
        hasWorkEnded: false,
      );
    }

    if (now.isBefore(start)) {
      return IncomeSnapshot(
        todayIncome: 0,
        dailySalary: salary,
        secondsUntilOffWork: end.difference(now).inSeconds,
        isWorkingNow: false,
        isWorkday: true,
        hasWorkEnded: false,
      );
    }

    if (!now.isBefore(end)) {
      return IncomeSnapshot(
        todayIncome: salary,
        dailySalary: salary,
        secondsUntilOffWork: 0,
        isWorkingNow: false,
        isWorkday: true,
        hasWorkEnded: true,
      );
    }

    final workedSeconds = now.difference(start).inSeconds;
    return IncomeSnapshot(
      todayIncome: salary * workedSeconds / totalSeconds,
      dailySalary: salary,
      secondsUntilOffWork: end.difference(now).inSeconds,
      isWorkingNow: true,
      isWorkday: true,
      hasWorkEnded: false,
    );
  }
}

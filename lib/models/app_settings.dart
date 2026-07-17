enum SalaryMode {
  monthly,
  daily,
}

class AppSettings {
  const AppSettings({
    required this.salaryMode,
    required this.monthlySalary,
    required this.dailySalary,
    required this.monthlyWorkdays,
    required this.workStartHour,
    required this.workStartMinute,
    required this.workEndHour,
    required this.workEndMinute,
    required this.regularWorkdays,
    this.todayWorkOverride,
    this.moneyRainEnabled = true,
    this.onboardingCompleted = false,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      salaryMode: SalaryMode.monthly,
      monthlySalary: 12000,
      dailySalary: 545.45,
      monthlyWorkdays: 22,
      workStartHour: 9,
      workStartMinute: 0,
      workEndHour: 18,
      workEndMinute: 0,
      regularWorkdays: {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      },
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      salaryMode: SalaryMode.values.firstWhere(
        (mode) => mode.name == json['salaryMode'],
        orElse: () => SalaryMode.monthly,
      ),
      monthlySalary: (json['monthlySalary'] as num?)?.toDouble() ?? 12000,
      dailySalary: (json['dailySalary'] as num?)?.toDouble() ?? 545.45,
      monthlyWorkdays: (json['monthlyWorkdays'] as num?)?.toInt() ?? 22,
      workStartHour: (json['workStartHour'] as num?)?.toInt() ?? 9,
      workStartMinute: (json['workStartMinute'] as num?)?.toInt() ?? 0,
      workEndHour: (json['workEndHour'] as num?)?.toInt() ?? 18,
      workEndMinute: (json['workEndMinute'] as num?)?.toInt() ?? 0,
      regularWorkdays: ((json['regularWorkdays'] as List<dynamic>?) ??
              const [1, 2, 3, 4, 5])
          .map((value) => (value as num).toInt())
          .where((value) => value >= DateTime.monday && value <= DateTime.sunday)
          .toSet(),
      todayWorkOverride: json['todayWorkOverride'] as bool?,
      moneyRainEnabled: json['moneyRainEnabled'] as bool? ?? true,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  final SalaryMode salaryMode;
  final double monthlySalary;
  final double dailySalary;
  final int monthlyWorkdays;
  final int workStartHour;
  final int workStartMinute;
  final int workEndHour;
  final int workEndMinute;
  final Set<int> regularWorkdays;
  final bool? todayWorkOverride;
  final bool moneyRainEnabled;
  final bool onboardingCompleted;

  bool isWorkday(DateTime date) {
    return todayWorkOverride ?? regularWorkdays.contains(date.weekday);
  }

  Map<String, dynamic> toJson() {
    return {
      'salaryMode': salaryMode.name,
      'monthlySalary': monthlySalary,
      'dailySalary': dailySalary,
      'monthlyWorkdays': monthlyWorkdays,
      'workStartHour': workStartHour,
      'workStartMinute': workStartMinute,
      'workEndHour': workEndHour,
      'workEndMinute': workEndMinute,
      'regularWorkdays': regularWorkdays.toList()..sort(),
      'todayWorkOverride': todayWorkOverride,
      'moneyRainEnabled': moneyRainEnabled,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  AppSettings copyWith({
    SalaryMode? salaryMode,
    double? monthlySalary,
    double? dailySalary,
    int? monthlyWorkdays,
    int? workStartHour,
    int? workStartMinute,
    int? workEndHour,
    int? workEndMinute,
    Set<int>? regularWorkdays,
    bool? todayWorkOverride,
    bool clearTodayWorkOverride = false,
    bool? moneyRainEnabled,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
      salaryMode: salaryMode ?? this.salaryMode,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      dailySalary: dailySalary ?? this.dailySalary,
      monthlyWorkdays: monthlyWorkdays ?? this.monthlyWorkdays,
      workStartHour: workStartHour ?? this.workStartHour,
      workStartMinute: workStartMinute ?? this.workStartMinute,
      workEndHour: workEndHour ?? this.workEndHour,
      workEndMinute: workEndMinute ?? this.workEndMinute,
      regularWorkdays: regularWorkdays ?? this.regularWorkdays,
      todayWorkOverride:
          clearTodayWorkOverride ? null : todayWorkOverride ?? this.todayWorkOverride,
      moneyRainEnabled: moneyRainEnabled ?? this.moneyRainEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

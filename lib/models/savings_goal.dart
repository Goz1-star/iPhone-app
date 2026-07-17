class SavingsGoal {
  const SavingsGoal({
    required this.name,
    required this.targetAmount,
    required this.automaticSavedAmount,
    required this.manualAdjustmentAmount,
    this.lastIncomeDateKey,
    this.lastIncomeForDate = 0,
    this.reachedNotificationSent = false,
  });

  factory SavingsGoal.defaults() {
    return const SavingsGoal(
      name: '发财基金',
      targetAmount: 5000,
      automaticSavedAmount: 0,
      manualAdjustmentAmount: 0,
    );
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      name: json['name'] as String? ?? '发财基金',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 5000,
      automaticSavedAmount:
          (json['automaticSavedAmount'] as num?)?.toDouble() ?? 0,
      manualAdjustmentAmount:
          (json['manualAdjustmentAmount'] as num?)?.toDouble() ?? 0,
      lastIncomeDateKey: json['lastIncomeDateKey'] as String?,
      lastIncomeForDate: (json['lastIncomeForDate'] as num?)?.toDouble() ?? 0,
      reachedNotificationSent: json['reachedNotificationSent'] as bool? ?? false,
    );
  }

  final String name;
  final double targetAmount;
  final double automaticSavedAmount;
  final double manualAdjustmentAmount;
  final String? lastIncomeDateKey;
  final double lastIncomeForDate;
  final bool reachedNotificationSent;

  double get savedAmount => automaticSavedAmount + manualAdjustmentAmount;

  double get remainingAmount {
    final remaining = targetAmount - savedAmount;
    return remaining <= 0 ? 0 : remaining;
  }

  double get progress {
    if (targetAmount <= 0) {
      return 1;
    }
    return (savedAmount / targetAmount).clamp(0, 1).toDouble();
  }

  bool get isReached => savedAmount >= targetAmount && targetAmount > 0;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'automaticSavedAmount': automaticSavedAmount,
      'manualAdjustmentAmount': manualAdjustmentAmount,
      'lastIncomeDateKey': lastIncomeDateKey,
      'lastIncomeForDate': lastIncomeForDate,
      'reachedNotificationSent': reachedNotificationSent,
    };
  }

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    double? automaticSavedAmount,
    double? manualAdjustmentAmount,
    String? lastIncomeDateKey,
    double? lastIncomeForDate,
    bool? reachedNotificationSent,
  }) {
    return SavingsGoal(
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      automaticSavedAmount: automaticSavedAmount ?? this.automaticSavedAmount,
      manualAdjustmentAmount: manualAdjustmentAmount ?? this.manualAdjustmentAmount,
      lastIncomeDateKey: lastIncomeDateKey ?? this.lastIncomeDateKey,
      lastIncomeForDate: lastIncomeForDate ?? this.lastIncomeForDate,
      reachedNotificationSent:
          reachedNotificationSent ?? this.reachedNotificationSent,
    );
  }
}

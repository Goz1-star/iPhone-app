import 'package:facai/models/savings_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavingsGoal', () {
    test('combines automatic income and manual adjustment', () {
      const goal = SavingsGoal(
        name: '奶茶自由基金',
        targetAmount: 3000,
        automaticSavedAmount: 1200,
        manualAdjustmentAmount: 300,
      );

      expect(goal.savedAmount, 1500);
      expect(goal.remainingAmount, 1500);
      expect(goal.progress, 0.5);
    });

    test('marks a goal as reached once saved amount covers target', () {
      const goal = SavingsGoal(
        name: '发财基金',
        targetAmount: 1000,
        automaticSavedAmount: 900,
        manualAdjustmentAmount: 100,
      );

      expect(goal.isReached, isTrue);
    });
  });
}

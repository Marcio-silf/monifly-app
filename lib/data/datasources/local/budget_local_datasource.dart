import 'package:hive_flutter/hive_flutter.dart';
import '../../models/budget.dart';

class BudgetLocalDataSource {
  final Box _box = Hive.box('budgets');

  Future<void> cacheBudgets(List<Budget> budgets) async {
    final Map<String, dynamic> data = {};
    for (final b in budgets) {
      data[b.id] = b.toJson();
    }
    await _box.putAll(data);
  }

  List<Budget> getCachedBudgets() {
    return _box.values
        .map((e) => Budget.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<Budget> getCachedBudgetsByMonth(int month) {
    return getCachedBudgets().where((b) => b.month == month).toList();
  }

  Future<void> cacheBudget(Budget budget) async {
    await _box.put(budget.id, budget.toJson());
  }

  Future<void> clearCache() async {
    await _box.clear();
  }
}

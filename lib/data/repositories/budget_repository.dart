import '../models/budget.dart';
import '../datasources/remote/api_service.dart';
import '../datasources/local/budget_local_datasource.dart';

class BudgetRepository {
  final ApiService _api;
  final BudgetLocalDataSource _local;

  BudgetRepository(this._api, this._local);

  Future<List<Budget>> getBudgets(String userId, int month) async {
    try {
      final remote = await _api.getBudgets(userId, month);
      await _local.cacheBudgets(remote);
      return remote;
    } catch (e) {
      return _local.getCachedBudgetsByMonth(month);
    }
  }

  Future<Budget> saveBudget(Budget budget) async {
    final remote = await _api.upsertBudget(budget);
    await _local.cacheBudget(remote);
    return remote;
  }

  /// Update spent amount when a new expense is added
  Future<void> updateSpentAmount(
    String userId,
    String category,
    int month,
    double newAmount,
  ) async {
    final budgets = await getBudgets(userId, month);
    final existing = budgets.where((b) => b.category == category).toList();
    if (existing.isNotEmpty) {
      final updated = existing.first.copyWith(
        spentAmount: existing.first.spentAmount + newAmount,
      );
      await saveBudget(updated);
    }
  }

  double getTotalBudgeted(List<Budget> budgets) =>
      budgets.fold(0, (sum, b) => sum + b.limitAmount);

  double getTotalSpent(List<Budget> budgets) =>
      budgets.fold(0, (sum, b) => sum + b.spentAmount);

  List<Budget> getOverBudgetCategories(List<Budget> budgets) =>
      budgets.where((b) => b.isOverBudget).toList();

  List<Budget> getWarningCategories(List<Budget> budgets) =>
      budgets.where((b) => b.isWarning).toList();
}


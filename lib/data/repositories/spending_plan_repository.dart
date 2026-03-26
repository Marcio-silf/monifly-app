import 'package:monifly/data/models/spending_plan.dart';
import 'package:monifly/data/models/transaction.dart';
import 'package:monifly/data/datasources/remote/api_service.dart';

class SpendingPlanRepository {
  final ApiService _api;

  SpendingPlanRepository(this._api);

  Future<SpendingPlan?> getSpendingPlan(String userId, int month) =>
      _api.getSpendingPlan(userId, month);

  Future<SpendingPlan> saveSpendingPlan(SpendingPlan plan) =>
      _api.saveSpendingPlan(plan);

  /// Generates analytical report for a month
  MonthlyReport calculateAnalysis({
    required int month,
    required SpendingPlan? plan,
    required List<Transaction> transactions,
  }) {
    final actualIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final actualExpenses = transactions
        .where((t) => t.isExpense && t.isPaid)
        .fold(0.0, (sum, t) => sum + t.amount);

    final expenseByCategory = <String, double>{};
    for (var t in transactions) {
      if (t.isExpense && t.isPaid) {
        expenseByCategory[t.category] = (expenseByCategory[t.category] ?? 0) + t.amount;
      }
    }

    final List<CategoryAnalysis> categoryAnalyses = [];
    
    // Use plan details or existing categories from transactions
    final categoriesToAnalyze = <String>{};
    if (plan != null) {
      for (var d in plan.details) {
        categoriesToAnalyze.add(d.category);
      }
    }
    categoriesToAnalyze.addAll(expenseByCategory.keys);

    for (var category in categoriesToAnalyze) {
      final planned = plan?.details
              .firstWhere((d) => d.category == category, 
                orElse: () => PlanDetail(id: '', planId: '', category: category, plannedAmount: 0))
              .plannedAmount ?? 0.0;
      
      final actual = expenseByCategory[category] ?? 0.0;

      categoryAnalyses.add(CategoryAnalysis(
        category: category,
        planned: planned,
        actual: actual,
      ));
    }

    return MonthlyReport(
      month: month,
      plannedIncome: plan?.plannedIncome ?? 0,
      actualIncome: actualIncome,
      plannedExpenses: plan?.totalPlanned ?? 0,
      actualExpenses: actualExpenses,
      categories: categoryAnalyses,
    );
  }
}

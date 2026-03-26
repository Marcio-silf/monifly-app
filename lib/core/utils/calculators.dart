import '../constants/app_constants.dart';

class AppCalculators {
  AppCalculators._();

  /// Calculate balance:
  /// Saldo = Receitas + Resgates - Despesas - Aplicações (apenas pagas/aplicadas)
  static double calculateBalance({
    required double totalIncome,
    required double totalExpense,
    required double totalInvestmentIn,
    required double totalInvestmentOut,
  }) {
    return totalIncome + totalInvestmentOut - totalExpense - totalInvestmentIn;
  }

  /// 20/10/60/10 Strategy calculator
  static Map<String, double> calculateStrategy(double monthlyIncome) {
    return {
      'reserve': monthlyIncome * AppConstants.strategyReserve,
      'investment': monthlyIncome * AppConstants.strategyStudies,
      'essentials': monthlyIncome * AppConstants.strategyExpenses,
      'leisure': monthlyIncome * AppConstants.strategyLeisure,
    };
  }

  /// Calculate financial health score (0-100)
  static double calculateHealthScore({
    required double monthlyIncome,
    required double monthlyExpense,
    required double monthlyInvestment,
    required double budgetAdherence, // 0.0 to 1.0
  }) {
    if (monthlyIncome <= 0) return 0;

    // Savings rate contribution (40 points)
    final savingsRate = (monthlyIncome - monthlyExpense) / monthlyIncome;
    final savingsScore = (savingsRate.clamp(0, 0.3) / 0.3) * 40;

    // Investment rate contribution (30 points)
    final investmentRate = monthlyInvestment / monthlyIncome;
    final investmentScore = (investmentRate.clamp(0, 0.2) / 0.2) * 30;

    // Budget adherence (30 points)
    final budgetScore = budgetAdherence.clamp(0, 1.0) * 30;

    return (savingsScore + investmentScore + budgetScore).clamp(0, 100);
  }

  /// Monthly contribution needed to reach a goal
  static double calculateMonthlyContribution({
    required double targetAmount,
    required double currentAmount,
    required DateTime targetDate,
  }) {
    final remaining = targetAmount - currentAmount;
    if (remaining <= 0) return 0;
    final months = _monthsBetween(DateTime.now(), targetDate);
    if (months <= 0) return remaining;
    return remaining / months;
  }

  /// Goal progress percentage
  static double calculateGoalProgress(
    double currentAmount,
    double targetAmount,
  ) {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  /// Number of months between two dates
  static int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  /// Check if a category spending is excessive (>30% of income)
  static bool isCategoryExcessive({
    required double categorySpent,
    required double monthlyIncome,
    double threshold = AppConstants.categoryAlertThreshold,
  }) {
    if (monthlyIncome <= 0) return false;
    return (categorySpent / monthlyIncome) >= threshold;
  }

  /// Budget adherence: average across categories
  static double calculateBudgetAdherence(List<Map<String, double>> budgets) {
    if (budgets.isEmpty) return 1.0;
    double total = 0;
    for (final b in budgets) {
      final limit = b['limit'] ?? 0;
      final spent = b['spent'] ?? 0;
      if (limit > 0) {
        total += (1 - (spent / limit).clamp(0, 1));
      }
    }
    return total / budgets.length;
  }
}


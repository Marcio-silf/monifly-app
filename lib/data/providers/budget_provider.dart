import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../repositories/budget_repository.dart';
import '../datasources/local/budget_local_datasource.dart';
import 'auth_provider.dart';

final budgetLocalDataSourceProvider = Provider<BudgetLocalDataSource>((ref) => BudgetLocalDataSource());

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(
    ref.read(apiServiceProvider),
    ref.read(budgetLocalDataSourceProvider),
  ),
);

final budgetsProvider = AsyncNotifierProvider<BudgetNotifier, List<Budget>>(
  BudgetNotifier.new,
);

class BudgetNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.read(budgetRepositoryProvider);
    // Use current month as default (YYYYMM)
    final now = DateTime.now();
    final month = now.year * 100 + now.month;
    return repo.getBudgets(user.id, month);
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final repo = ref.read(budgetRepositoryProvider);
    for (final b in budgets) {
      await repo.saveBudget(b);
    }
    ref.invalidateSelf();
  }

  Future<void> refresh(int month) async {
    state = const AsyncLoading();
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    final repo = ref.read(budgetRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getBudgets(user.id, month));
  }
}


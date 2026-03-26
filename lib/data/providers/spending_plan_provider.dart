import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spending_plan.dart';
import '../repositories/spending_plan_repository.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

final spendingPlanRepositoryProvider = Provider<SpendingPlanRepository>(
  (ref) => SpendingPlanRepository(ref.read(apiServiceProvider)),
);

final spendingPlanProvider = AsyncNotifierProvider<SpendingPlanNotifier, SpendingPlan?>(
  SpendingPlanNotifier.new,
);

class SpendingPlanNotifier extends AsyncNotifier<SpendingPlan?> {
  @override
  Future<SpendingPlan?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    final month = ref.watch(selectedMonthProvider);
    final repo = ref.read(spendingPlanRepositoryProvider);
    return repo.getSpendingPlan(user.id, month);
  }

  Future<void> savePlan(SpendingPlan plan) async {
    final repo = ref.read(spendingPlanRepositoryProvider);
    final saved = await repo.saveSpendingPlan(plan);
    state = AsyncData(saved);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncData(null);
      return;
    }
    final month = ref.read(selectedMonthProvider);
    final repo = ref.read(spendingPlanRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getSpendingPlan(user.id, month));
  }
}

final monthlyReportProvider = Provider<MonthlyReport?>((ref) {
  final plan = ref.watch(spendingPlanProvider).valueOrNull;
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.read(spendingPlanRepositoryProvider);
  
  return repo.calculateAnalysis(
    month: month,
    plan: plan,
    transactions: transactions,
  );
});

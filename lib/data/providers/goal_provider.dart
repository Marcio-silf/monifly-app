import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';
import '../datasources/local/goal_local_datasource.dart';
import 'auth_provider.dart';

final goalLocalDataSourceProvider = Provider<GoalLocalDataSource>((ref) => GoalLocalDataSource());

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(
    ref.read(apiServiceProvider),
    ref.read(goalLocalDataSourceProvider),
  ),
);

final goalsProvider = AsyncNotifierProvider<GoalNotifier, List<Goal>>(
  GoalNotifier.new,
);

class GoalNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.read(goalRepositoryProvider);
    return repo.getGoals(user.id);
  }

  Future<void> addGoal(Goal goal) async {
    final repo = ref.read(goalRepositoryProvider);
    final created = await repo.addGoal(goal);
    state = AsyncData([created, ...state.valueOrNull ?? []]);
  }

  Future<void> updateGoal(Goal goal) async {
    final repo = ref.read(goalRepositoryProvider);
    final updated = await repo.updateGoal(goal);
    state = AsyncData(
      state.valueOrNull!.map((g) => g.id == updated.id ? updated : g).toList(),
    );
  }

  Future<void> addAmountToGoal(Goal goal, double amount) async {
    final repo = ref.read(goalRepositoryProvider);
    final updated = await repo.addAmountToGoal(goal, amount);
    state = AsyncData(
      state.valueOrNull!.map((g) => g.id == updated.id ? updated : g).toList(),
    );
  }

  Future<void> deleteGoal(String id) async {
    final repo = ref.read(goalRepositoryProvider);
    await repo.deleteGoal(id);
    state = AsyncData(state.valueOrNull!.where((g) => g.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    final repo = ref.read(goalRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getGoals(user.id));
  }
}

// Active goals
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  final goals = ref.watch(goalsProvider).valueOrNull ?? [];
  return goals.where((g) => g.status == 'active').toList();
});

// Completed goals
final completedGoalsProvider = Provider<List<Goal>>((ref) {
  final goals = ref.watch(goalsProvider).valueOrNull ?? [];
  return goals.where((g) => g.status == 'completed').toList();
});


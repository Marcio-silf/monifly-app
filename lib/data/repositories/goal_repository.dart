import '../models/goal.dart';
import '../datasources/remote/api_service.dart';
import '../datasources/local/goal_local_datasource.dart';

class GoalRepository {
  final ApiService _api;
  final GoalLocalDataSource _local;

  GoalRepository(this._api, this._local);

  Future<List<Goal>> getGoals(String userId) async {
    try {
      final remote = await _api.getGoals(userId);
      await _local.cacheGoals(remote);
      return remote;
    } catch (e) {
      return _local.getCachedGoals();
    }
  }

  Future<Goal> addGoal(Goal goal) async {
    final remote = await _api.insertGoal(goal);
    await _local.cacheGoal(remote);
    return remote;
  }

  Future<Goal> updateGoal(Goal goal) async {
    final remote = await _api.updateGoal(goal);
    await _local.cacheGoal(remote);
    return remote;
  }

  Future<void> deleteGoal(String id) async {
    await _api.deleteGoal(id);
    await _local.deleteCachedGoal(id);
  }

  Future<Goal> addAmountToGoal(Goal goal, double amount) {
    final updatedGoal = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
      status: (goal.currentAmount + amount) >= goal.targetAmount
          ? 'completed'
          : 'active',
    );
    return _api.updateGoal(updatedGoal);
  }

  List<Goal> getActiveGoals(List<Goal> goals) =>
      goals.where((g) => g.status == 'active').toList();

  List<Goal> getCompletedGoals(List<Goal> goals) =>
      goals.where((g) => g.status == 'completed').toList();

  double getTotalTargetAmount(List<Goal> goals) =>
      goals.fold(0, (sum, g) => sum + g.targetAmount);

  double getTotalCurrentAmount(List<Goal> goals) =>
      goals.fold(0, (sum, g) => sum + g.currentAmount);
}


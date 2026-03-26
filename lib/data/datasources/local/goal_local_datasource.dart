import 'package:hive_flutter/hive_flutter.dart';
import '../../models/goal.dart';

class GoalLocalDataSource {
  final Box _box = Hive.box('goals');

  Future<void> cacheGoals(List<Goal> goals) async {
    final Map<String, dynamic> data = {};
    for (final g in goals) {
      data[g.id] = g.toJson();
    }
    await _box.putAll(data);
  }

  List<Goal> getCachedGoals() {
    return _box.values
        .map((e) => Goal.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> cacheGoal(Goal goal) async {
    await _box.put(goal.id, goal.toJson());
  }

  Future<void> deleteCachedGoal(String id) async {
    await _box.delete(id);
  }

  Future<void> clearCache() async {
    await _box.clear();
  }
}

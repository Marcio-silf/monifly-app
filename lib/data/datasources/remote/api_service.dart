import 'package:monifly/data/models/transaction.dart';
import 'package:monifly/data/models/goal.dart';
import 'package:monifly/data/models/budget.dart';
import 'package:monifly/data/models/user_profile.dart';
import 'package:monifly/data/models/spending_plan.dart';
import 'package:monifly/data/datasources/remote/supabase_client.dart';
import 'package:monifly/core/errors/exceptions.dart';

class ApiService {
  final _client = SupabaseConfig.client;

  // ─── Profiles ────────────────────────────────────────────────────────────

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao buscar perfil: $e');
    }
  }

  Future<void> upsertProfile(UserProfile profile) async {
    try {
      await _client.from('profiles').upsert(profile.toJson());
    } catch (e) {
      throw DatabaseException(message: 'Erro ao salvar perfil: $e');
    }
  }

  // ─── Transactions ─────────────────────────────────────────────────────────

  Future<List<Transaction>> getTransactions(String userId, {int? month}) async {
    try {
      var query = _client.from('transactions').select().eq('user_id', userId);
      if (month != null) {
        final year = month ~/ 100;
        final m = month % 100;
        final start = DateTime(year, m, 1);
        final end = DateTime(year, m + 1, 1);
        query = query
            .gte('date', start.toIso8601String())
            .lt('date', end.toIso8601String());
      }
      final data = await query.order('date', ascending: false);
      return (data as List).map((e) => Transaction.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseException(message: 'Erro ao buscar transações: $e');
    }
  }

  Future<Transaction?> getTransaction(String id) async {
    try {
      final data = await _client
          .from('transactions')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return Transaction.fromJson(data);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao buscar transação: $e');
    }
  }

  Future<Transaction> insertTransaction(Transaction transaction) async {
    try {
      final data = await _client
          .from('transactions')
          .insert(transaction.toJson())
          .select()
          .single();
      return Transaction.fromJson(data);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao criar transação: $e');
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final data = await _client
          .from('transactions')
          .update(transaction.toJson())
          .eq('id', transaction.id)
          .select()
          .single();
      return Transaction.fromJson(data);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao atualizar transação: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _client.from('transactions').delete().eq('id', id);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao excluir transação: $e');
    }
  }

  // ─── Goals ────────────────────────────────────────────────────────────────

  Future<List<Goal>> getGoals(String userId) async {
    try {
      final data = await _client
          .from('goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => Goal.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseException(message: 'Erro ao buscar metas: $e');
    }
  }

  Future<Goal> insertGoal(Goal goal) async {
    try {
      final data =
          await _client.from('goals').insert(goal.toJson()).select().single();
      return Goal.fromJson(data);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao criar meta: $e');
    }
  }

  Future<Goal> updateGoal(Goal goal) async {
    try {
      final data = await _client
          .from('goals')
          .update(goal.toJson())
          .eq('id', goal.id)
          .select()
          .single();
      return Goal.fromJson(data);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao atualizar meta: $e');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _client.from('goals').delete().eq('id', id);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao excluir meta: $e');
    }
  }

  // ─── Budgets ──────────────────────────────────────────────────────────────

  Future<List<Budget>> getBudgets(String userId, int month) async {
    try {
      final data = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', month);
      return (data as List).map((e) => Budget.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseException(message: 'Erro ao buscar orçamentos: $e');
    }
  }

  Future<Budget> upsertBudget(Budget budget) async {
    try {
      final data = await _client
          .from('budgets')
          .upsert(budget.toJson(), onConflict: 'user_id, category, month')
          .select()
          .single();
      return Budget.fromJson(data);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao salvar orçamento: $e');
    }
  }

  // ─── Spending Plans ────────────────────────────────────────────────────────

  Future<SpendingPlan?> getSpendingPlan(String userId, int month) async {
    try {
      final data = await _client
          .from('spending_plans')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .maybeSingle();

      if (data == null) return null;

      final planId = data['id'] as String;
      final detailsData = await _client
          .from('plan_details')
          .select()
          .eq('plan_id', planId);

      final details = (detailsData as List)
          .map((e) => PlanDetail.fromJson(e))
          .toList();

      return SpendingPlan.fromJson(data, details);
    } catch (e) {
      throw DatabaseException(message: 'Erro ao buscar planejamento: $e');
    }
  }

  Future<SpendingPlan> saveSpendingPlan(SpendingPlan plan) async {
    try {
      // 1. Upsert plan
      final planData = await _client
          .from('spending_plans')
          .upsert(plan.toJson(), onConflict: 'user_id, month')
          .select()
          .single();

      final savedPlanId = planData['id'] as String;

      // 2. Delete existing details if any (or we could use upsert logic)
      await _client.from('plan_details').delete().eq('plan_id', savedPlanId);

      // 3. Insert new details
      if (plan.details.isNotEmpty) {
        final detailsJson = plan.details.map((d) {
          final map = d.toJson();
          map['plan_id'] = savedPlanId;
          return map;
        }).toList();
        
        await _client.from('plan_details').insert(detailsJson);
      }

      // 4. Return complete plan
      return (await getSpendingPlan(plan.userId, plan.month))!;
    } catch (e) {
      throw DatabaseException(message: 'Erro ao salvar planejamento: $e');
    }
  }
}

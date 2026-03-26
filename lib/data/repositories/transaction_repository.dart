import 'package:monifly/data/models/transaction.dart';
import 'package:monifly/data/models/user_profile.dart';
import 'package:monifly/data/datasources/remote/api_service.dart';
import 'package:monifly/data/datasources/local/transaction_local_datasource.dart';
import 'package:monifly/core/errors/exceptions.dart';
import 'package:monifly/core/constants/app_constants.dart';

class TransactionRepository {
  final ApiService _api;
  final TransactionLocalDataSource _local;

  TransactionRepository(this._api, this._local);

  Future<List<Transaction>> getTransactions(String userId, {int? month}) async {
    try {
      final remoteData = await _api.getTransactions(userId, month: month);
      // Cache the fetched data
      await _local.cacheTransactions(remoteData);
      return remoteData;
    } catch (e) {
      // Fallback to cache if network fails
      if (month != null) {
        return _local.getCachedTransactionsByMonth(month);
      }
      return _local.getCachedTransactions();
    }
  }

  Future<Transaction?> getTransaction(String id) async {
    try {
       final remote = await _api.getTransaction(id);
       if (remote != null) await _local.cacheTransaction(remote);
       return remote;
    } catch (e) {
       // Return from cache if exists
       final cached = _local.getCachedTransactions().where((t) => t.id == id).toList();
       return cached.isNotEmpty ? cached.first : null;
    }
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    // Optimistic cache (optional, but let's at least try the API first)
    final created = await _api.insertTransaction(transaction);
    await _local.cacheTransaction(created);
    return created;
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final updated = await _api.updateTransaction(transaction);
    await _local.cacheTransaction(updated);
    return updated;
  }

  Future<void> deleteTransaction(String id) async {
    await _api.deleteTransaction(id);
    await _local.deleteCachedTransaction(id);
  }

  /// Monthly summary: income, expense, investmentIn, investmentOut
  Map<String, double> calculateMonthlySummary(List<Transaction> transactions) {
    double income = 0, expense = 0, investIn = 0, investOut = 0;
    for (final t in transactions) {
      if (!t.isPaid && !t.isIncome) continue;
      switch (t.type) {
        case AppConstants.typeIncome:
          income += t.amount;
          break;
        case AppConstants.typeExpense:
          if (t.isPaid) expense += t.amount;
          break;
        case AppConstants.typeInvestmentIn:
          investIn += t.amount;
          break;
        case AppConstants.typeInvestmentOut:
          investOut += t.amount;
          break;
      }
    }
    return {
      'income': income,
      'expense': expense,
      'netInvestment': investIn - investOut,
      'investmentIn': investIn,
      'investmentOut': investOut,
      'balance': income + investOut - expense - investIn,
    };
  }

  /// Overall balance: total income + total rescues - total expenses - total investments
  double calculateBalance(List<Transaction> allTransactions) {
    double balance = 0;
    for (final t in allTransactions) {
      if (!t.isPaid && !t.isIncome) continue;
      balance += t.signedAmount;
    }
    return balance;
  }

  /// Group transactions by relative date label
  Map<String, List<Transaction>> groupByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> groups = {};
    for (final t in transactions) {
      final label = _getGroupLabel(t.date);
      groups.putIfAbsent(label, () => []).add(t);
    }
    return groups;
  }

  String _getGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    if (diff <= 7) return 'Esta semana';
    if (d.month == today.month && d.year == today.year) return 'Este mês';
    return 'Anterior';
  }

  /// Get pending bills
  List<Transaction> getPendingBills(List<Transaction> transactions) {
    return transactions
        .where((t) => t.isExpense && (t.isPending || t.isScheduled))
        .toList()
      ..sort((a, b) => (a.dueDate ?? a.date).compareTo(b.dueDate ?? b.date));
  }

  /// Get expense by category
  Map<String, double> getExpenseByCategory(List<Transaction> transactions) {
    final Map<String, double> map = {};
    for (final t in transactions) {
      if (t.isExpense && t.isPaid) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }
}


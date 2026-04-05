import 'package:monifly/data/models/transaction.dart';
import 'package:monifly/data/datasources/remote/api_service.dart';
import 'package:monifly/data/datasources/local/transaction_local_datasource.dart';
import 'package:monifly/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

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

  Future<List<Transaction>> addTransactions(List<Transaction> transactions) async {
    final created = await _api.insertTransactions(transactions);
    await _local.cacheTransactions(created);
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

  Future<void> replicateRecurringTransactions(String userId) async {
    try {
      final allTransactions = await getTransactions(userId);
      final now = DateTime.now();
      final currentMonthInt = now.year * 100 + now.month;

      // Filter transactions that are recurring
      final recurringTemplates = allTransactions.where((t) => t.isRecurring).toList();
      
      final List<Transaction> newTransactions = [];

      for (final template in recurringTemplates) {
        // Iterate from start month to current month
        int year = template.date.year;
        int month = template.date.month;
        
        while (true) {
          // Increment month
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
          
          final targetMonthInt = year * 100 + month;
          if (targetMonthInt > currentMonthInt) break;

          // Check if this template already has a replica in this target month
          final alreadyReplicated = allTransactions.any((t) =>
              t.userId == userId &&
              t.description == template.description &&
              t.amount == template.amount &&
              t.type == template.type &&
              t.category == template.category &&
              t.date.year == year &&
              t.date.month == month);

          if (!alreadyReplicated) {
            final newDate = DateTime(year, month, template.date.day);
            // Adjust if day doesn't exist in that month (e.g. 31st)
            final actualDate = newDate.month == month ? newDate : DateTime(year, month + 1, 0);
            
            newTransactions.add(Transaction(
              id: const Uuid().v4(),
              userId: userId,
              type: template.type,
              description: template.description,
              amount: template.amount,
              date: actualDate,
              category: template.category,
              paymentStatus: template.type == AppConstants.typeIncome ? AppConstants.statusPaid : AppConstants.statusPending,
              paymentMethod: template.paymentMethod,
              notes: template.notes,
              isRecurring: true,
              recurringFrequency: template.recurringFrequency,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }
        }
      }

      if (newTransactions.isNotEmpty) {
        await addTransactions(newTransactions);
      }
    } catch (e) {
      print('Error replicating recurring transactions: $e');
    }
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


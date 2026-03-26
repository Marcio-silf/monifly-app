import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction.dart';

class TransactionLocalDataSource {
  final Box _box = Hive.box('transactions');

  /// Save a list of transactions to Hive, keyed by ID.
  Future<void> cacheTransactions(List<Transaction> transactions) async {
    final Map<String, dynamic> data = {};
    for (final t in transactions) {
      data[t.id] = t.toJson();
    }
    await _box.putAll(data);
  }

  /// Get all cached transactions.
  List<Transaction> getCachedTransactions() {
    return _box.values
        .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Get cached transactions for a specific month (YYYYMM).
  List<Transaction> getCachedTransactionsByMonth(int month) {
    final year = month ~/ 100;
    final m = month % 100;
    
    return getCachedTransactions().where((t) {
      return t.date.year == year && t.date.month == m;
    }).toList();
  }

  /// Reset/Clear cache.
  Future<void> clearCache() async {
    await _box.clear();
  }

  /// Cache a single transaction.
  Future<void> cacheTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction.toJson());
  }

  /// Delete from cache.
  Future<void> deleteCachedTransaction(String id) async {
    await _box.delete(id);
  }
}

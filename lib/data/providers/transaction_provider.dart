import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import 'auth_provider.dart';
import '../../core/utils/date_formatter.dart';

final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSource();
});

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(
    ref.read(apiServiceProvider),
    ref.read(transactionLocalDataSourceProvider),
  ),
);

// Selected month filter (YYYYMM)
final selectedMonthProvider = StateProvider<int>((ref) {
  return DateFormatter.toMonthInt(DateTime.now());
});

// Transactions for the selected month
final transactionsProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
  TransactionNotifier.new,
);

// All transactions for the user (for overall balance)
final allTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final repo = ref.read(transactionRepositoryProvider);
  // Fetching without month returns all
  return repo.getTransactions(user.id);
});

// Overall balance calculated from all transactions
final overallBalanceProvider = Provider<double>((ref) {
  final all = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final repo = ref.read(transactionRepositoryProvider);
  return repo.calculateBalance(all);
});

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    
    final repo = ref.read(transactionRepositoryProvider);
    
    // Check and replicate recurring transactions first
    await repo.replicateRecurringTransactions(user.id);
    
    final month = ref.watch(selectedMonthProvider);
    return repo.getTransactions(user.id, month: month);
  }

  Future<void> addTransaction(Transaction transaction) async {
    final repo = ref.read(transactionRepositoryProvider);
    final created = await repo.addTransaction(transaction);
    state = AsyncData([created, ...state.valueOrNull ?? []]);
  }

  Future<void> addTransactions(List<Transaction> transactions) async {
    final repo = ref.read(transactionRepositoryProvider);
    final createdList = await repo.addTransactions(transactions);
    state = AsyncData([...createdList, ...state.valueOrNull ?? []]);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final repo = ref.read(transactionRepositoryProvider);
    final updated = await repo.updateTransaction(transaction);
    state = AsyncData(
      state.valueOrNull!.map((t) => t.id == updated.id ? updated : t).toList(),
    );
  }

  Future<void> updateTransactionStatus(String id, String newStatus) async {
    final transactions = state.valueOrNull;
    if (transactions == null) return;
    final index = transactions.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final updatedTransaction = transactions[index].copyWith(paymentStatus: newStatus);
    final repo = ref.read(transactionRepositoryProvider);
    await repo.updateTransaction(updatedTransaction);

    state = AsyncData(
      transactions.map((t) => t.id == id ? updatedTransaction : t).toList(),
    );
  }

  Future<void> deleteTransaction(String id) async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.deleteTransaction(id);
    state = AsyncData(state.valueOrNull!.where((t) => t.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    final month = ref.read(selectedMonthProvider);
    final repo = ref.read(transactionRepositoryProvider);
    state = await AsyncValue.guard(
      () => repo.getTransactions(user.id, month: month),
    );
  }
}

// Derived: monthly summary
final monthlySummaryProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final repo = ref.read(transactionRepositoryProvider);
  return repo.calculateMonthlySummary(transactions);
});

// Derived: pending bills
final pendingBillsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final repo = ref.read(transactionRepositoryProvider);
  return repo.getPendingBills(transactions);
});

// Derived: expense by category
final expenseByCategoryProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final repo = ref.read(transactionRepositoryProvider);
  return repo.getExpenseByCategory(transactions);
});

// Derived: transactions by payment method
final transactionsByPaymentMethodProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final Map<String, double> map = {};
  for (final t in transactions) {
    if (t.isExpense && t.isPaid) {
      final method = t.paymentMethod ?? 'Não especificado';
      map[method] = (map[method] ?? 0) + t.amount;
    }
  }
  return map;
});


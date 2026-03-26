import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../widgets/cards/transaction_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/month_picker.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filterType = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const Map<String, String> _filterLabels = {
    'all': AppStrings.all,
    AppConstants.typeIncome: 'Receitas',
    AppConstants.typeExpense: 'Despesas',
    AppConstants.typeInvestmentIn: 'Investimentos',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transactions),
        actions: [
          MonthPicker(
            selectedMonth: ref.watch(selectedMonthProvider),
            isCompact: true,
            onChanged: (val) => ref.read(selectedMonthProvider.notifier).state = val,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.routeAddTransaction),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscar movimentação... ✈️',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filterLabels.entries.map((e) {
                final isSelected = _filterType == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterType = e.key),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Transaction list
          Expanded(
            child: transactionsAsync.when(
              loading: () => const MoniflyLoader(),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () {
                  ref.read(transactionsProvider.notifier).refresh();
                },
              ),
              data: (data) {
                var filtered = data;
                if (_filterType != 'all') {
                  filtered = filtered
                      .where(
                        (t) => _filterType == AppConstants.typeInvestmentIn
                            ? (t.type == AppConstants.typeInvestmentIn ||
                                  t.type == AppConstants.typeInvestmentOut)
                            : t.type == _filterType,
                      )
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (t) => t.description.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'Nenhuma movimentação',
                    message: 'Adicione sua primeira transação tocando no +',
                  );
                }

                final groups = ref.read(transactionRepositoryProvider).groupByDate(filtered);
                final groupKeys = groups.keys.toList();

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(transactionsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groupKeys.length,
                    itemBuilder: (ctx, index) {
                      final key = groupKeys[index];
                      final items = groups[key]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              key,
                              style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ),
                          ...items.map(
                            (t) => TransactionCard(
                              transaction: t,
                              onTap: () => Navigator.pushNamed(
                                ctx,
                                AppConstants.routeTransactionDetail,
                                arguments: {'id': t.id},
                              ),
                              onDelete: () => ref
                                  .read(transactionsProvider.notifier)
                                  .deleteTransaction(t.id),
                              onEdit: () => Navigator.pushNamed(
                                ctx,
                                AppConstants.routeAddTransaction,
                                arguments: {'id': t.id},
                              ),
                              onStatusChange: (status) => ref
                                  .read(transactionsProvider.notifier)
                                  .updateTransactionStatus(t.id, status),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



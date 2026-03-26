import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/budget.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'package:monifly/core/utils/date_formatter.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/premium/upgrade_modal.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(String key) {
    _controllers.putIfAbsent(key, () => TextEditingController());
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final expenseByCategory = ref.watch(expenseByCategoryProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final totalExpenses = summary['expense'] ?? 0;

    final topCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.budget)),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (savedBudgets) {
          // Sync controllers with saved budgets
          for (final b in savedBudgets) {
            final controller = _c(b.category);
            if (controller.text.isEmpty) {
              controller.text = b.limitAmount.toStringAsFixed(0);
            }
          }

          return Column(
            children: [
              // Total spent vs budgeted header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Gasto este Mês',
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(totalExpenses),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Set budgets by category
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Orçamento por Categoria',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final user = ref.read(currentUserProvider);
                        if (user == null) return;
                        final month = DateFormatter.toMonthInt(DateTime.now());
                        final budgets = <Budget>[];

                        for (final entry in _controllers.entries) {
                          final amount = double.tryParse(entry.value.text) ?? 0;
                          if (amount > 0) {
                            budgets.add(
                              Budget(
                                id: '', // Will be handled by upsert or auto-gen
                                userId: user.id,
                                category: entry.key,
                                month: month,
                                limitAmount: amount,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            );
                          }
                        }

                        if (budgets.isNotEmpty) {
                          // Verificar limite Free: o usuário free só pode ter 1 orçamento salvo por mês
                          final subscription = ref.read(subscriptionProvider);
                          if (!subscription.isPremium && budgets.length > 1) {
                            UpgradeModal.show(
                              context,
                              title: 'Limite de Orçamentos!',
                              message: 'No plano Grátis você pode definir um limite para apenas 1 categoria.\nAssine o Monifly Premium para gerenciar todas as suas categorias.',
                            );
                            return;
                          }

                          try {
                            await ref
                                .read(budgetsProvider.notifier)
                                .saveBudgets(budgets);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Orçamentos salvos!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao salvar: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: topCategories.isEmpty
                    ? const Center(
                        child: Text(
                          'Adicione despesas para\nver o orçamento por categoria',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: topCategories.length,
                        itemBuilder: (ctx, i) {
                          final entry = topCategories[i];
                          final spent = entry.value;
                          final budgetController = _c(entry.key);
                          final budgetStr = budgetController.text;
                          final budgetAmount = double.tryParse(budgetStr) ?? 0;
                          final pct = budgetAmount > 0
                              ? (spent / budgetAmount).clamp(0.0, 1.0)
                              : 0.0;
                          final isOver =
                              budgetAmount > 0 && spent > budgetAmount;

                          final allCats = AppConstants.expenseCategories;
                          final match =
                              allCats.where((c) => c['key'] == entry.key);
                          final icon = match.isNotEmpty
                              ? match.first['icon'] as String
                              : '💸';
                          final catLabel = match.isNotEmpty
                              ? match.first['label'] as String
                              : entry.key;
                          final barColor =
                              isOver ? AppColors.expense : AppColors.primary;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).brightness == Brightness.dark
                                  ? AppColors.cardDark
                                  : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(16),
                              border: isOver
                                  ? Border.all(
                                      color: AppColors.expense.withValues(alpha: 0.3),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      icon,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        catLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isOver)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(
                                          '⚠️',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        controller: budgetController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: 'Limite',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          prefixText: 'R\$ ',
                                          isDense: true,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Gasto: ${CurrencyFormatter.format(spent)}',
                                      style: TextStyle(
                                        color: barColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (budgetAmount > 0)
                                      Text(
                                        '${(pct * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: barColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                if (budgetAmount > 0) ...[
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: barColor.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      barColor,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../data/providers/auth_provider.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final summary = ref.watch(monthlySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.investments)),
      body: Column(
        children: [
          // Summary header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.investment, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InvStat(
                  label: 'Aplicado',
                  amount: summary['investmentIn'] ?? 0,
                  icon: Icons.trending_up_rounded,
                ),
                Container(width: 1, height: 48, color: Colors.white24),
                _InvStat(
                  label: 'Resgatado',
                  amount: summary['investmentOut'] ?? 0,
                  icon: Icons.trending_down_rounded,
                  color: Colors.white70,
                ),
                Container(width: 1, height: 48, color: Colors.white24),
                _InvStat(
                  label: 'Líquido',
                  amount:
                      (summary['investmentIn'] ?? 0) -
                      (summary['investmentOut'] ?? 0),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Movimentações de Investimento',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (transactions) {
                final investments = transactions
                    .where(
                      (t) =>
                          t.type == 'investment_in' ||
                          t.type == 'investment_out',
                    )
                    .toList();
                if (investments.isEmpty) {
                  return const Center(
                    child: Text('Nenhum investimento registrado\n📈'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: investments.length,
                  itemBuilder: (ctx, i) {
                    final t = investments[i];
                    final isIn = t.type == 'investment_in';
                    final color = isIn ? AppColors.income : AppColors.expense;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).brightness == Brightness.dark
                            ? AppColors.cardDark
                            : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isIn ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 28,
                            color: color,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.description.isEmpty
                                      ? (isIn ? 'Aplicação' : 'Resgate')
                                      : t.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  t.category,
                                  style: TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            (isIn ? '+' : '-') +
                                CurrencyFormatter.format(t.amount),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InvStat extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _InvStat({
    required this.label,
    required this.amount,
    required this.icon,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatCompact(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}


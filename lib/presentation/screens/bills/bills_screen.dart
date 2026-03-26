import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/providers/transaction_provider.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingBills = ref.watch(pendingBillsProvider);
    final allTransactions = ref.watch(transactionsProvider).valueOrNull ?? [];

    // All bills (pending + paid this month)
    final allBills = allTransactions.where((t) => t.isExpense).toList()
      ..sort((a, b) => (a.dueDate ?? a.date).compareTo(b.dueDate ?? b.date));

    final totalPending = pendingBills.fold<double>(0, (s, t) => s + t.amount);
    final totalPaid = allBills
        .where((t) => t.isPaid)
        .fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.bills)),
      body: Column(
        children: [
          // Summary row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'A pagar',
                    amount: totalPending,
                    color: AppColors.expense,
                    icon: '⏰',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Pago',
                    amount: totalPaid,
                    color: AppColors.income,
                    icon: '✅',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: allBills.isEmpty
                ? const Center(child: Text('Nenhuma conta este mês'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allBills.length,
                    itemBuilder: (ctx, i) {
                      final t = allBills[i];
                      return _BillTile(t);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  final dynamic transaction;
  const _BillTile(this.transaction);

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isPaid = t.isPaid;
    final color = isPaid ? AppColors.income : AppColors.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_rounded : Icons.schedule_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description.isEmpty ? 'Conta' : t.description,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  t.dueDate != null
                      ? 'Vence: ${DateFormatter.formatShort(t.dueDate!)}'
                      : DateFormatter.formatShort(t.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(t.amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                isPaid ? 'Pago' : 'Pendente',
                style: TextStyle(color: color, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


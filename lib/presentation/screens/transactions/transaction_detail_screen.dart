import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/transaction.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          transactionsAsync.when(
            data: (txns) {
              final t = txns.where((x) => x.id == transactionId).toList();
              if (t.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppConstants.routeAddTransaction,
                  arguments: {'id': transactionId},
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (txns) {
          final list = txns.where((x) => x.id == transactionId).toList();
          if (list.isEmpty) {
            return const Center(child: Text('Transação não encontrada'));
          }
          final t = list.first;
          final color = t.isIncome || t.isInvestmentOut
              ? AppColors.income
              : t.isExpense
                  ? AppColors.expense
                  : AppColors.investment;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Amount header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getTypeIcon(t.type),
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (t.isIncome || t.isInvestmentOut ? '+' : '-') +
                            CurrencyFormatter.format(t.amount),
                        style: TextStyle(
                          color: color,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.description.isEmpty
                            ? _getTypeName(t.type)
                            : t.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Details list
                _DetailRow(
                  label: 'Data',
                  value: DateFormatter.formatFull(t.date),
                ),
                _DetailRow(label: 'Categoria', value: t.category),
                _DetailRow(
                  label: 'Status',
                  value: _getStatusLabel(t.paymentStatus),
                ),
                if (t.paymentMethod != null)
                  _DetailRow(label: 'Pagamento', value: t.paymentMethod!),
                if (t.dueDate != null)
                  _DetailRow(
                    label: 'Vencimento',
                    value: DateFormatter.formatFull(t.dueDate!),
                  ),
                if (t.isRecurring)
                  _DetailRow(
                    label: 'Recorrência',
                    value: _translateFrequency(t.recurringFrequency),
                  ),
                if (t.notes != null && t.notes!.isNotEmpty)
                  _DetailRow(label: 'Notas', value: t.notes!),
                const SizedBox(height: 32),
                // Delete button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir transação?'),
                          content: const Text(
                            'Esta ação não pode ser desfeita.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await ref
                            .read(transactionsProvider.notifier)
                            .deleteTransaction(transactionId);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir transação'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _translateFrequency(String? frequency) {
    if (frequency == null) return 'Sim';
    switch (frequency.toLowerCase()) {
      case 'monthly':
        return 'Mensalmente';
      case 'weekly':
        return 'Semanalmente';
      case 'daily':
        return 'Diariamente';
      case 'yearly':
        return 'Anualmente';
      default:
        return frequency;
    }
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case AppConstants.typeIncome:
        return '💰';
      case AppConstants.typeExpense:
        return '💸';
      case AppConstants.typeInvestmentIn:
        return '📈';
      default:
        return '📉';
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case AppConstants.typeIncome:
        return 'Receita';
      case AppConstants.typeExpense:
        return 'Despesa';
      case AppConstants.typeInvestmentIn:
        return 'Aplicação';
      default:
        return 'Resgate';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case AppConstants.statusPaid:
        return 'Pago ✅';
      case AppConstants.statusPending:
        return 'Pendente ⏳';
      case AppConstants.statusScheduled:
        return 'Agendado 📅';
      default:
        return status;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

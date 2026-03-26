import 'package:flutter/material.dart';
import 'package:monifly/data/models/transaction.dart';
import 'package:monifly/core/constants/colors.dart';
import 'package:monifly/core/constants/app_constants.dart';
import 'package:monifly/core/utils/currency_formatter.dart';
import 'package:monifly/core/utils/date_formatter.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Function(String)? onStatusChange;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(transaction.id),
      background: _buildSwipeBackground(
        Colors.blue,
        Icons.edit_rounded,
        Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        Colors.red,
        Icons.delete_rounded,
        Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
          return false;
        } else {
          return await _confirmDelete(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showStatusPicker(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(transaction.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _getCategoryIcon(transaction.category, transaction.type),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Description and category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description.isEmpty
                          ? _getTypeName(transaction.type)
                          : transaction.description,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getCategoryLabel(transaction.category),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (transaction.isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pending.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Pendente',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.pending,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatSignedAmount(transaction),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _getTypeColor(transaction.type),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatShort(transaction.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Alterar Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              _buildStatusOption(
                ctx,
                'Pago',
                Icons.check_circle_rounded,
                AppColors.income,
                AppConstants.statusPaid,
              ),
              _buildStatusOption(
                ctx,
                'Pendente',
                Icons.schedule_rounded,
                AppColors.pending,
                AppConstants.statusPending,
              ),
              _buildStatusOption(
                ctx,
                'Agendado',
                Icons.event_outlined,
                AppColors.secondary,
                AppConstants.statusScheduled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String status,
  ) {
    final isSelected = transaction.paymentStatus == status;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? color : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: color, size: 20)
          : null,
      onTap: () {
        onStatusChange?.call(status);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSwipeBackground(
    Color color,
    IconData icon,
    Alignment alignment,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: color),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir transação'),
        content: const Text('Tem certeza que deseja excluir esta transação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case AppConstants.typeIncome:
        return AppColors.income;
      case AppConstants.typeExpense:
        return AppColors.expense;
      case AppConstants.typeInvestmentIn:
        return AppColors.investment;
      case AppConstants.typeInvestmentOut:
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  String _formatSignedAmount(Transaction t) {
    final formatted = CurrencyFormatter.format(t.amount);
    if (t.isIncome || t.isInvestmentOut) return '+$formatted';
    return '-$formatted';
  }

  String _getCategoryIcon(String category, String type) {
    final allCategories = [
      ...AppConstants.expenseCategories,
      ...AppConstants.incomeCategories,
      ...AppConstants.investmentCategories,
    ];
    final match = allCategories.where((c) => c['key'] == category);
    if (match.isNotEmpty) return match.first['icon'] as String;
    if (type == AppConstants.typeIncome) return '💰';
    if (type == AppConstants.typeExpense) return '💸';
    if (type == AppConstants.typeInvestmentIn) return '📈';
    return '📉';
  }

  String _getCategoryLabel(String category) {
    final allCategories = [
      ...AppConstants.expenseCategories,
      ...AppConstants.incomeCategories,
      ...AppConstants.investmentCategories,
    ];
    final match = allCategories.where((c) => c['key'] == category);
    if (match.isNotEmpty) return match.first['label'] as String;
    return category;
  }

  String _getTypeName(String type) {
    switch (type) {
      case AppConstants.typeIncome:
        return 'Receita';
      case AppConstants.typeExpense:
        return 'Despesa';
      case AppConstants.typeInvestmentIn:
        return 'Aplicação';
      case AppConstants.typeInvestmentOut:
        return 'Resgate';
      default:
        return 'Transação';
    }
  }
}

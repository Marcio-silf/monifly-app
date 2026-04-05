import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/transaction.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../data/services/import_service.dart';

class ImportItem {
  Transaction transaction;
  bool selected;
  final bool isDuplicate;
  final bool isOriginalInflow;

  ImportItem({
    required this.transaction,
    this.selected = true,
    this.isDuplicate = false,
  }) : isOriginalInflow = transaction.isIncome || transaction.isInvestmentOut;
}

class ImportPreviewScreen extends ConsumerStatefulWidget {
  final List<Transaction> importedTransactions;
  const ImportPreviewScreen({super.key, required this.importedTransactions});

  @override
  ConsumerState<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  late List<ImportItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(transactionsProvider).valueOrNull ?? [];
    _items = widget.importedTransactions.map((t) {
      final duplicate = ImportService.isPossibleDuplicate(t, existing);
      return ImportItem(
        transaction: t,
        isDuplicate: duplicate,
        selected: !duplicate, // Unselect duplicates by default
      );
    }).toList();
  }

  Future<void> _saveAll() async {
    final selectedTransactions = _items
        .where((i) => i.selected)
        .map((i) => i.transaction)
        .toList();

    if (selectedTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma transação selecionada')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(transactionsProvider.notifier).addTransactions(selectedTransactions);
      if (mounted) {
        Navigator.pop(context); // Close preview
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedTransactions.length} transações importadas com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCategoryPicker(int index) {
    final item = _items[index];
    final categories = item.transaction.isIncome 
        ? [...AppConstants.incomeCategories, ...AppConstants.investmentCategories]
        : (item.transaction.isInvestmentIn || item.transaction.isInvestmentOut)
            ? AppConstants.investmentCategories
            : AppConstants.expenseCategories;


    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escolha uma Categoria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  final isSelected = item.transaction.category == cat['key'];
                  return ListTile(
                    leading: Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                    title: Text(cat['label']),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () {
                      final catKey = cat['key'];
                      final isInvestmentCat = AppConstants.investmentCategories.any((c) => c['key'] == catKey);
                      
                      Transaction updatedTransaction = item.transaction.copyWith(category: catKey);

                      // Automatically adjust the type if it's an investment category
                      if (isInvestmentCat) {
                        updatedTransaction = updatedTransaction.copyWith(
                          type: item.isOriginalInflow 
                              ? AppConstants.typeInvestmentOut 
                              : AppConstants.typeInvestmentIn,
                        );
                      } else {
                        // Restore to regular Income/Expense if switching back from investment
                        updatedTransaction = updatedTransaction.copyWith(
                          type: item.isOriginalInflow 
                              ? AppConstants.typeIncome 
                              : AppConstants.typeExpense,
                        );
                      }

                      setState(() {
                        item.transaction = updatedTransaction;
                      });
                      Navigator.pop(context);
                    },

                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(Transaction t) {
    final allCategories = [
      ...AppConstants.incomeCategories,
      ...AppConstants.expenseCategories,
      ...AppConstants.investmentCategories,
    ];
    
    final cat = allCategories.firstWhere(
      (c) => c['key'] == t.category, 
      orElse: () => {'label': t.category, 'icon': '❓'},
    );
    return cat['label'];
  }

  String _getCategoryIcon(Transaction t) {
    final allCategories = [
      ...AppConstants.incomeCategories,
      ...AppConstants.expenseCategories,
      ...AppConstants.investmentCategories,
    ];
            
    final cat = allCategories.firstWhere(
      (c) => c['key'] == t.category, 
      orElse: () => {'label': t.category, 'icon': '❓'},
    );
    return cat['icon'];
  }



  @override
  Widget build(BuildContext context) {
    final selectedCount = _items.where((i) => i.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar Importação'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$selectedCount/${_items.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confira as transações abaixo. Itens marcados com ⚠️ podem ser duplicados.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return CheckboxListTile(
                  value: item.selected,
                  onChanged: (val) => setState(() => item.selected = val ?? false),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.transaction.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isDuplicate)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Tooltip(
                            message: 'Possível duplicata encontrada no banco',
                            child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text(
                          '${item.transaction.date.day}/${item.transaction.date.month}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => _showCategoryPicker(index),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_getCategoryIcon(item.transaction), style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  _getCategoryLabel(item.transaction).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10, 
                                    color: AppColors.primary, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(item.transaction.isIncome || item.transaction.isInvestmentOut) ? '+' : '-'} R\$ ${item.transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: (item.transaction.isIncome || item.transaction.isInvestmentOut) ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),
                  ),
                );

              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Importar $selectedCount Transações'),
          ),
        ),
      ),
    );
  }
}

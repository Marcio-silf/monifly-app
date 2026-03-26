import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/wishlist_provider.dart';
import '../../../data/models/wishlist_item.dart';
import '../../../data/providers/auth_provider.dart';

class Rule30DaysScreen extends ConsumerStatefulWidget {
  const Rule30DaysScreen({super.key});

  @override
  ConsumerState<Rule30DaysScreen> createState() => _Rule30DaysScreenState();
}

class _Rule30DaysScreenState extends ConsumerState<Rule30DaysScreen> {
  void _showAddDialog() {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    String category = 'compras';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Desejo 🤔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'O que você quer comprar?'),
            ),
            const SizedBox(height: 12),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Qual o valor?',
                  prefixText: 'R\$ ',
                ),
                onChanged: (v) {
                  String digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) {
                    valueController.value = const TextEditingValue(
                      text: '0,00',
                      selection: TextSelection.collapsed(offset: 4),
                    );
                    return;
                  }
                  double value = double.parse(digits) / 100;
                  final formatted = CurrencyFormatter.formatNoSymbol(value);
                  valueController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                },
              ),
            ],
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valStr = valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (nameController.text.isEmpty || valStr.isEmpty) return;
              
              final user = ref.read(currentUserProvider);
              if (user != null) {
                ref.read(wishlistProvider.notifier).addWish(
                      user.id,
                      nameController.text,
                      double.parse(valStr) / 100,
                      category,
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Registrar Desejo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(wishlistProvider);
    final stats = ref.watch(wishlistProvider.notifier).calculateStats();

    final observing = items.where((i) => i.status == 'observing').toList();
    observing.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

    return Scaffold(
      appBar: AppBar(title: const Text('Regra dos 30 Dias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Desejo'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(context, stats),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Em Observação', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('${stats['observingCount']} itens', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          if (observing.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_empty_rounded, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Nenhum desejo em observação.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _showAddDialog, child: const Text('Adicionar o primeiro')),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final item = observing[index];
                    return _buildWishCard(context, item);
                  },
                  childCount: observing.length,
                ),
              ),
            ),
            
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.income.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.savings_rounded, color: AppColors.income),
              const SizedBox(width: 8),
              const Expanded(child: Text('Dinheiro Salvo', style: TextStyle(fontWeight: FontWeight.w600))),
              Text(
                CurrencyFormatter.format(stats['saved']),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.income),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatMini(label: 'Total Desejado', value: CurrencyFormatter.format(stats['totalDesired'])),
              _StatMini(label: 'Gasto Real', value: CurrencyFormatter.format(stats['spent'])),
              _StatMini(label: 'Taxa Sucesso', value: '${(stats['successRate'] as double).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWishCard(BuildContext context, WishlistItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = 1.0 - (item.daysRemaining / 30).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(CurrencyFormatter.format(item.value), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                onPressed: () {
                  ref.read(wishlistProvider.notifier).deleteWish(item.id);
                },
                tooltip: 'Excluir definitivamente (não conta como economia)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (item.canBuy)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.income.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Período de reflexão concluído! Você ainda quer comprar?', style: TextStyle(color: AppColors.income, fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(wishlistProvider.notifier).finalizeWish(item.id, false),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.income, side: const BorderSide(color: AppColors.income)),
                          child: const Text('Desisti (Economizar)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ref.read(wishlistProvider.notifier).finalizeWish(item.id, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                          child: const Text('Comprar Mesmo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Faltam ${item.daysRemaining} dias', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13)),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => ref.read(wishlistProvider.notifier).finalizeWish(item.id, false),
                    style: TextButton.styleFrom(foregroundColor: AppColors.income),
                    child: const Text('Desistir da compra (Economizar)'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  const _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

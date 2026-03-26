import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/strategy_service.dart';
import '../../../data/providers/transaction_provider.dart';

class Budget503020Screen extends ConsumerStatefulWidget {
  const Budget503020Screen({super.key});

  @override
  ConsumerState<Budget503020Screen> createState() => _Budget503020ScreenState();
}

class _Budget503020ScreenState extends ConsumerState<Budget503020Screen> {
  final _salaryController = TextEditingController();
  double _salary = 0;
  Map<String, dynamic>? _analysis;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  void _calculate() {
    final text = _salaryController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return;
    
    final salary = double.parse(text) / 100;
    if (salary <= 0) return;

    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
    
    setState(() {
      _salary = salary;
      _analysis = StrategyService.analyze503020(salary, transactions);
    });
  }

  void _handleValueChange(String value) {
    if (value.isEmpty) return;
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      _salaryController.text = '';
      return;
    }
    final val = double.parse(clean) / 100;
    final formatted = CurrencyFormatter.formatNoSymbol(val);
    _salaryController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamento 50-30-20')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExplanation(context),
            const SizedBox(height: 24),
            
            Text('Qual a sua Renda Mensal Líquida?', 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                hintText: 'Ex: 5.000,00',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_rounded),
                  color: AppColors.primary,
                  onPressed: _calculate,
                ),
              ),
              onChanged: _handleValueChange,
              onSubmitted: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Analisar Orçamento'),
              ),
            ),
            const SizedBox(height: 32),

            if (_analysis != null) _buildAnalysis(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('A Regra de Ouro', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Divida sua renda líquida mensal em 3 partes: 50% para necessidades básicas, 30% para desejos pessoais e 20% para o seu futuro.',
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysis(BuildContext context) {
    final targets = _analysis!['targets'] as Map<String, double>;
    final spent = _analysis!['spent'] as Map<String, dynamic>;
    final recommendations = _analysis!['recommendations'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seu Raio-X Financeiro', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        
        _buildComparisonCard(
          context,
          title: 'Necessidades Essenciais',
          percentage: '50%',
          meta: targets['needs']!,
          gasto: spent['needs']!,
          color: AppColors.expense,
          icon: Icons.home_rounded,
        ),
        
        _buildComparisonCard(
          context,
          title: 'Desejos & Lazer',
          percentage: '30%',
          meta: targets['wants']!,
          gasto: spent['wants']!,
          color: AppColors.accent,
          icon: Icons.shopping_bag_rounded,
        ),
        
        _buildComparisonCard(
          context,
          title: 'Poupança & Investimento',
          percentage: '20%',
          meta: targets['savings']!,
          gasto: spent['savings']!,
          color: AppColors.income,
          icon: Icons.savings_rounded,
        ),

        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Diagnóstico Monifly', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...recommendations.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(r, style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildComparisonCard(BuildContext context, {
    required String title,
    required String percentage,
    required double meta,
    required double gasto,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diff = gasto - meta;
    final statusColor = diff > 0 ? AppColors.expense : AppColors.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Meta Ideal: $percentage', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              ])),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Limite (Orçamento)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(CurrencyFormatter.format(meta), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Gasto no Mês', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(CurrencyFormatter.format(gasto), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: meta > 0 ? (gasto / meta).clamp(0.0, 1.0) : 0,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          if (diff > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.expense),
                  const SizedBox(width: 4),
                  Text('${CurrencyFormatter.format(diff)} acima da meta', style: TextStyle(fontSize: 11, color: AppColors.expense, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

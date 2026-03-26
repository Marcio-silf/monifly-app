import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/calculator_service.dart';

class CompoundInterestScreen extends StatefulWidget {
  const CompoundInterestScreen({super.key});

  @override
  State<CompoundInterestScreen> createState() => _CompoundInterestScreenState();
}

class _CompoundInterestScreenState extends State<CompoundInterestScreen> {
  final _initialController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _rateController = TextEditingController();
  final _yearsController = TextEditingController();

  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _initialController.dispose();
    _monthlyController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final initialStr = _initialController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final monthlyStr = _monthlyController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final rateStr = _rateController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final yearsStr = _yearsController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (initialStr.isEmpty || monthlyStr.isEmpty || rateStr.isEmpty || yearsStr.isEmpty) return;

    final initial = double.parse(initialStr) / 100;
    final monthly = double.parse(monthlyStr) / 100;
    final rate = double.parse(rateStr);
    final years = int.parse(yearsStr);

    setState(() {
      _result = CalculatorService.calculateCompoundInterest(
        initialAmount: initial,
        monthlyContribution: monthly,
        yearlyInterestRate: rate,
        years: years,
      );
    });
  }

  void _formatCurrency(TextEditingController controller, String value) {
    if (value.isEmpty) return;
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      controller.text = '';
      return;
    }
    final val = double.parse(clean) / 100;
    final formatted = CurrencyFormatter.formatNoSymbol(val);
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juros Compostos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInput(
                    label: 'Valor Inicial',
                    controller: _initialController,
                    prefix: 'R\$ ',
                    hintText: 'Ex: 10.000,00',
                    onChanged: (v) => _formatCurrency(_initialController, v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInput(
                    label: 'Aporte Mensal',
                    controller: _monthlyController,
                    prefix: 'R\$ ',
                    hintText: 'Ex: 500,00',
                    onChanged: (v) => _formatCurrency(_monthlyController, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInput(
                    label: 'Taxa Anual',
                    controller: _rateController,
                    hintText: 'Ex: 12,0',
                    suffix: '%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInput(
                    label: 'Período',
                    controller: _yearsController,
                    hintText: 'Ex: 10',
                    suffix: 'anos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calcular Rendimentos'),
              ),
            ),
            const SizedBox(height: 32),

            if (_result != null) _buildResults(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? suffix,
    String? hintText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: prefix,
            suffixText: suffix,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Projeção Financeira', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.income.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.income.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text('Montante Final Exato', style: TextStyle(color: AppColors.income, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(_result!['finalAmount']),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.income),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(label: 'Total Investido', value: CurrencyFormatter.format(_result!['totalInvested']), color: isDark ? Colors.white : Colors.black),
                  const SizedBox(width: 16),
                  _StatItem(label: 'Total em Juros', value: '+ ${CurrencyFormatter.format(_result!['totalInterest'])}', color: AppColors.income),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        Text('O poder dos juros compostos: de todo o valor acumulado, ${(_result!['interestPercentage'] as double).toStringAsFixed(1)}% vieram apenas dos rendimentos! Seu dinheiro multiplicou um total de ${(_result!['multiplier'] as double).toStringAsFixed(2)} vezes.', 
          style: const TextStyle(height: 1.5, fontStyle: FontStyle.italic)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

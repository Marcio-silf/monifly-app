import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/calculator_service.dart';

class CostPerUseScreen extends StatefulWidget {
  const CostPerUseScreen({super.key});

  @override
  State<CostPerUseScreen> createState() => _CostPerUseScreenState();
}

class _CostPerUseScreenState extends State<CostPerUseScreen> {
  final _priceController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _monthsController = TextEditingController();
  final _resaleController = TextEditingController();

  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _priceController.dispose();
    _frequencyController.dispose();
    _monthsController.dispose();
    _resaleController.dispose();
    super.dispose();
  }

  void _calculate() {
    final curReg = RegExp(r'[^0-9]');
    final priceStr = _priceController.text.replaceAll(curReg, '');
    final freqStr = _frequencyController.text.replaceAll(curReg, '');
    final monthsStr = _monthsController.text.replaceAll(curReg, '');
    final resaleStr = _resaleController.text.replaceAll(curReg, '');

    if (priceStr.isEmpty || freqStr.isEmpty || monthsStr.isEmpty) return;

    setState(() {
      _result = CalculatorService.calculateCostPerUse(
        price: double.parse(priceStr) / 100,
        frequencyPerMonth: int.parse(freqStr),
        intendedMonths: int.parse(monthsStr),
        resaleValue: resaleStr.isNotEmpty ? double.parse(resaleStr) / 100 : 0,
        extraCosts: 0,
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
      appBar: AppBar(title: const Text('Custo por Uso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInput(
              label: 'Preço Total do Produto',
              controller: _priceController,
              prefix: 'R\$ ',
              hintText: 'Ex: 3.500,00',
              onChanged: (v) => _formatCurrency(_priceController, v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInput(
                    label: 'Vezes usado por Mês',
                    controller: _frequencyController,
                    hintText: 'Ex: 10',
                    suffix: 'vezes',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInput(
                    label: 'Meses de Uso (útil)',
                    controller: _monthsController,
                    hintText: 'Ex: 24',
                    suffix: 'meses',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInput(
              label: 'Valor de Revenda (Opcional)',
              controller: _resaleController,
              prefix: 'R\$ ',
              hintText: 'Ex: 1.000,00',
              onChanged: (v) => _formatCurrency(_resaleController, v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calcular Rentabilidade'),
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
    final cpu = _result!['costPerUse'] as double;
    final rating = _result!['rating'] as String;
    
    Color ratingColor;
    switch (rating) {
      case 'Excelente': ratingColor = AppColors.income; break;
      case 'Moderado': ratingColor = Colors.blue; break;
      case 'Elevado': ratingColor = Colors.orange; break;
      default: ratingColor = AppColors.expense;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('O Custo Real de Cada Uso', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.format(cpu),
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: ratingColor),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: ratingColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Classificação: $rating', style: TextStyle(color: ratingColor, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatColumn(label: 'Usos Totais', value: '${_result!['totalUses']}x'),
            _StatColumn(label: 'Custo Efetivo', value: CurrencyFormatter.format(_result!['totalCost'])),
            _StatColumn(label: 'Custo Mensal', value: CurrencyFormatter.format(_result!['costPerMonth'])),
          ],
        ),
        const SizedBox(height: 32),

        const Divider(),
        const SizedBox(height: 16),
        const Text('💡 Dica: Compare este valor de Custo por Uso com o preço de um "Aluguel" (ex: Uber vs Carro Próprio, ou Aluguel de Vestido vs Compra). Se o aluguel for mais barato que o seu custo por uso, financeiramente vale mais a pena não comprar.', style: TextStyle(height: 1.5, color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

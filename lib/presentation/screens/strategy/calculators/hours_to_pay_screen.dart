import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/calculator_service.dart';

class HoursToPayScreen extends StatefulWidget {
  const HoursToPayScreen({super.key});

  @override
  State<HoursToPayScreen> createState() => _HoursToPayScreenState();
}

class _HoursToPayScreenState extends State<HoursToPayScreen> {
  final _priceController = TextEditingController();
  final _salaryController = TextEditingController();
  bool _discountTaxes = true;

  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _priceController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _calculate() {
    final curReg = RegExp(r'[^0-9]');
    final priceStr = _priceController.text.replaceAll(curReg, '');
    final salaryStr = _salaryController.text.replaceAll(curReg, '');

    if (priceStr.isEmpty || salaryStr.isEmpty) return;

    setState(() {
      _result = CalculatorService.calculateHoursToPay(
        productPrice: double.parse(priceStr) / 100,
        monthlySalary: double.parse(salaryStr) / 100,
        considerDiscounts: _discountTaxes,
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
      appBar: AppBar(title: const Text('Horas Trabalhadas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Descubra o preço real de uma compra convertendo o valor em horas da sua vida.', 
              style: TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 24),

            _buildInput(
              label: 'Preço do Produto',
              controller: _priceController,
              prefix: 'R\$ ',
              hintText: 'Ex: 1.500,00',
              onChanged: (v) => _formatCurrency(_priceController, v),
            ),
            const SizedBox(height: 16),
            _buildInput(
              label: 'Qual o seu Salário Líquido Mensal?',
              controller: _salaryController,
              prefix: 'R\$ ',
              hintText: 'Ex: 4.000,00',
              onChanged: (v) => _formatCurrency(_salaryController, v),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Descontar finais de semana e feriados', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Mais realista, foca só nos dias úteis médios', style: TextStyle(fontSize: 12)),
              value: _discountTaxes,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _discountTaxes = val);
                if (_result != null) _calculate();
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Transformar em Horas'),
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
    final hours = _result!['hoursEquivalent'] as double;
    final reflection = _result!['reflection'] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.expense.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: AppColors.expense.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('Isto vai te custar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hours.toStringAsFixed(1),
                style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: AppColors.expense, height: 1),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0, left: 8.0),
                child: Text('horas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('≈ $reflection', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Essa compra equivale a abrir mão de:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EquivItem(count: _result!['coffees'], icon: Icons.local_cafe_rounded, label: 'Cafés'),
              _EquivItem(count: _result!['lunches'], icon: Icons.lunch_dining_rounded, label: 'Almoços'),
              _EquivItem(count: _result!['gasLiters'], icon: Icons.local_gas_station_rounded, label: 'L de Gas.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _EquivItem extends StatelessWidget {
  final int count;
  final IconData icon;
  final String label;

  const _EquivItem({required this.count, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 28),
        const SizedBox(height: 8),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

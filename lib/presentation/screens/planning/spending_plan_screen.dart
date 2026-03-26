import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/spending_plan.dart';
import '../../../data/providers/spending_plan_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/premium/upgrade_modal.dart';
import '../../widgets/common/loading_indicator.dart';

class SpendingPlanScreen extends ConsumerStatefulWidget {
  const SpendingPlanScreen({super.key});

  @override
  ConsumerState<SpendingPlanScreen> createState() => _SpendingPlanScreenState();
}

class _SpendingPlanScreenState extends ConsumerState<SpendingPlanScreen> {
  final _incomeController = TextEditingController(text: '0,00');
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  bool _planLoaded = false;

  @override
  void initState() {
    super.initState();
    for (var cat in AppConstants.expenseCategories) {
      _controllers[cat['key'] as String] = TextEditingController(text: '0,00');
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadPlan(SpendingPlan? plan) {
    if (plan == null) {
      _incomeController.text = '0,00';
      for (var c in _controllers.values) {
        c.text = '0,00';
      }
      _planLoaded = true;
      return;
    }
    _incomeController.text = _formatValue(plan.plannedIncome);
    for (var c in _controllers.values) {
      c.text = '0,00';
    }
    for (var detail in plan.details) {
      if (_controllers.containsKey(detail.category)) {
        _controllers[detail.category]!.text = _formatValue(detail.plannedAmount);
      }
    }
    _planLoaded = true;
  }

  String _formatValue(double value) {
    return CurrencyFormatter.formatNoSymbol(value);
  }

  double _parseValue(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return 0;
    return double.parse(clean) / 100;
  }

  double _calculateTotalDistributed() {
    double total = 0;
    for (var controller in _controllers.values) {
      total += _parseValue(controller.text);
    }
    return total;
  }

  void _clearAll() {
    setState(() {
      _incomeController.text = '0,00';
      for (var c in _controllers.values) {
        c.text = '0,00';
      }
    });
  }

  void _fillFromAverage() {
    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
    final now = DateTime.now();
    
    // Get last 3 months of transactions
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
    final pastTransactions = transactions.where((t) =>
      t.isExpense && t.isPaid && t.date.isAfter(threeMonthsAgo)
    ).toList();

    if (pastTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem dados de meses anteriores para calcular média')),
      );
      return;
    }

    // Calculate average per category
    final Map<String, double> totals = {};
    final Map<String, int> counts = {};
    for (var t in pastTransactions) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
      counts[t.category] = (counts[t.category] ?? 0) + 1;
    }

    // Calculate income average
    final incomeTransactions = transactions.where((t) =>
      t.isIncome && t.date.isAfter(threeMonthsAgo)
    );
    if (incomeTransactions.isNotEmpty) {
      final totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final avgIncome = totalIncome / 3;
      _incomeController.text = _formatValue(avgIncome);
    }

    setState(() {
      for (var entry in _controllers.entries) {
        final total = totals[entry.key];
        if (total != null) {
          final avg = total / 3; // average over 3 months
          entry.value.text = _formatValue(avg);
        } else {
          entry.value.text = '0,00';
        }
      }
    });
  }

  void _changeMonth(int delta) {
    final current = ref.read(selectedMonthProvider);
    final year = current ~/ 100;
    final month = current % 100;
    final newDate = DateTime(year, month + delta, 1);
    final newMonth = newDate.year * 100 + newDate.month;
    ref.read(selectedMonthProvider.notifier).state = newMonth;
    _planLoaded = false;
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final income = _parseValue(_incomeController.text);
    final month = ref.read(selectedMonthProvider);
    final currentPlan = ref.read(spendingPlanProvider).valueOrNull;

    final plan = SpendingPlan(
      id: currentPlan?.id ?? '',
      userId: user.id,
      month: month,
      plannedIncome: income,
      createdAt: currentPlan?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      details: _controllers.entries.map((e) => PlanDetail(
        id: '',
        planId: currentPlan?.id ?? '',
        category: e.key,
        plannedAmount: _parseValue(e.value.text),
      )).where((d) => d.plannedAmount > 0).toList(),
    );

    setState(() => _isLoading = true);
    try {
      await ref.read(spendingPlanProvider.notifier).savePlan(plan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planejamento salvo com sucesso! ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleValueChange(String value, TextEditingController controller) {
    if (value.isEmpty) return;
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      controller.text = '0,00';
      setState(() {});
      return;
    }
    final val = double.parse(clean) / 100;
    final formatted = _formatValue(val);
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(spendingPlanProvider);
    final month = ref.watch(selectedMonthProvider);
    final year = month ~/ 100;
    final m = month % 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load plan data when it arrives
    ref.listen(spendingPlanProvider, (prev, next) {
      if (next is AsyncData && !_planLoaded) {
        _loadPlan(next.value);
        setState(() {});
      }
    });

    // Also load on first build if data is already available
    if (!_planLoaded && planAsync is AsyncData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPlan(planAsync.value);
        if (mounted) setState(() {});
      });
    }

    final income = _parseValue(_incomeController.text);
    final totalDistributed = _calculateTotalDistributed();
    final remaining = income - totalDistributed;
    final progress = income > 0 ? (totalDistributed / income).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planejamento Mensal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded),
            onPressed: () {
              final subscription = ref.read(subscriptionProvider);
              if (!subscription.isPremium) {
                UpgradeModal.show(
                  context,
                  title: 'Planejamento Inteligente!',
                  message: 'O preenchimento automático baseado no seu histórico financeiro é uma função Premium.\nAssine agora para facilitar seu planejamento.',
                );
                return;
              }
              _fillFromAverage();
            },
            tooltip: 'Preencher pela média (3 meses)',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearAll,
            tooltip: 'Limpar tudo',
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const MoniflyLoader(),
        error: (e, stack) => Center(child: Text('Erro: $e')),
        data: (plan) {
          final subscription = ref.watch(subscriptionProvider);
          
          return Column(
            children: [
              if (!subscription.isPremium)
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppConstants.routePaywall),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.amber.withOpacity(0.15),
                    child: const Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Desbloqueie o planejamento completo com Monifly Premium!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.amber, size: 20),
                      ],
                    ),
                  ),
                ),
              // Header Summary Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Month Selector with arrows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                        ),
                        Text(
                          '${_getMonthName(m)} / $year',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Receita Prevista', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 200,
                      child: TextField(
                        controller: _incomeController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: 'R\$ ',
                          prefixStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          filled: false,
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                        onChanged: (v) => _handleValueChange(v, _incomeController),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HeaderStat(label: 'Distribuído', value: totalDistributed),
                        _HeaderStat(label: 'Restante', value: remaining),
                        _HeaderStat(label: '% Alocado', valueText: '${(progress * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(remaining >= 0 ? Colors.white : AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ),

              // Categories List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: AppConstants.expenseCategories.length,
                  itemBuilder: (context, index) {
                    final cat = AppConstants.expenseCategories[index];
                    final key = cat['key'] as String;
                    final controller = _controllers[key]!;
                    final planned = _parseValue(controller.text);
                    final pct = income > 0 ? (planned / income * 100) : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: planned > 0 ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(cat['icon'] as String, style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (planned > 0)
                                  Text(
                                    '${pct.toStringAsFixed(1)}% da receita',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: TextField(
                              controller: controller,
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: 'R\$ ',
                                isDense: true,
                              ),
                              onChanged: (v) => _handleValueChange(v, controller),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_isLoading || remaining < 0) ? null : _save,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Salvar Planejamento', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int m) {
    const months = ['', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    return months[m];
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final double? value;
  final String? valueText;
  const _HeaderStat({required this.label, this.value, this.valueText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          valueText ?? CurrencyFormatter.format(value ?? 0),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

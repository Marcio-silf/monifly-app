import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/premium/upgrade_modal.dart';
import 'package:uuid/uuid.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType;
  final String? transactionId;
  const AddTransactionScreen({super.key, this.initialType, this.transactionId});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  String _category = 'outros';
  String _paymentStatus = AppConstants.statusPaid;
  String? _paymentMethod;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _isRecurring = false;
  String? _recurringFrequency;
  bool _isLoading = false;
  int _step = 0;
  String? _selectedGoalId;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? AppConstants.typeExpense;
    _category = _getDefaultCategory(_type);

    if (widget.transactionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTransaction();
      });
    }
  }

  Future<void> _loadTransaction() async {
    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
    Transaction? t =
        transactions.where((tx) => tx.id == widget.transactionId).firstOrNull;

    if (t == null) {
      // Fetch from repository if not in current month's list
      try {
        final repo = ref.read(transactionRepositoryProvider);
        t = await repo.getTransaction(widget.transactionId!);
      } catch (e) {
        debugPrint('Error loading transaction: $e');
      }
    }

    if (t != null) {
      final Transaction transaction = t;
      setState(() {
        _type = transaction.type;
        _category = transaction.category;
        _paymentStatus = transaction.paymentStatus;
        _paymentMethod = transaction.paymentMethod;
        _date = transaction.date;
        _dueDate = transaction.dueDate;
        _isRecurring = transaction.isRecurring;
        _recurringFrequency = transaction.recurringFrequency;
        _selectedGoalId = transaction.goalId;
        _amountController.text =
            CurrencyFormatter.formatNoSymbol(transaction.amount);
        _descriptionController.text = transaction.description;
        _notesController.text = transaction.notes ?? '';

        // Skip type step if editing
        _step = 1;
      });
    }
  }

  String _getDefaultCategory(String type) {
    switch (type) {
      case AppConstants.typeIncome:
        return 'salario';
      case AppConstants.typeExpense:
        return 'alimentacao';
      case AppConstants.typeInvestmentIn:
      case AppConstants.typeInvestmentOut:
        return 'acoes';
      default:
        return 'outros';
    }
  }

  List<Map<String, dynamic>> get _categories {
    switch (_type) {
      case AppConstants.typeIncome:
        return AppConstants.incomeCategories;
      case AppConstants.typeExpense:
        return AppConstants.expenseCategories;
      default:
        return AppConstants.investmentCategories;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Monetization Verification
      final subscription = ref.read(subscriptionProvider);
      if (!subscription.isPremium && widget.transactionId == null) {
        final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
        final now = DateTime.now();
        // Contar transações só deste mês
        final currentMonthTxs = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).length;
        
        if (currentMonthTxs >= 15) {
          setState(() => _isLoading = false);
          UpgradeModal.show(
            context,
            title: 'Limite Atingido!',
            message: 'Você atingiu o limite gratuito de 15 transações neste mês.\nDesbloqueie o Monifly Premium para transações ilimitadas e muitos outros benefícios exclusivos.',
          );
          return;
        }
      }

      final amount = CurrencyFormatter.parse(_amountController.text);
      final transaction = Transaction(
        id: widget.transactionId ?? const Uuid().v4(),
        userId: user.id,
        type: _type,
        description: _descriptionController.text,
        amount: amount,
        date: _date,
        category: _category,
        paymentStatus: _paymentStatus,
        paymentMethod: _paymentMethod,
        dueDate: _dueDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isRecurring: _isRecurring,
        recurringFrequency: _isRecurring ? _recurringFrequency : null,
        goalId: _selectedGoalId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.transactionId != null) {
        await ref
            .read(transactionsProvider.notifier)
            .updateTransaction(transaction);
      } else {
        await ref
            .read(transactionsProvider.notifier)
            .addTransaction(transaction);
      }

      // If linking to a goal, update goal amount
      if (_selectedGoalId != null) {
        final goals = ref.read(goalsProvider).valueOrNull ?? [];
        final goal = goals.firstWhere((g) => g.id == _selectedGoalId);
        await ref.read(goalsProvider.notifier).addAmountToGoal(goal, amount);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionId != null
            ? 'Editar Movimentação'
            : AppStrings.newTransaction),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(_step),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('Voltar'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.monifly,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_step < 3) {
                              setState(() => _step++);
                            } else {
                              _save();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _step < 3 ? AppStrings.next : AppStrings.save,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildTypeStep();
      case 1:
        return _buildAmountStep();
      case 2:
        return _buildDescriptionStep();
      case 3:
        return _buildDetailsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildTypeStep() {
    final types = [
      {
        'type': AppConstants.typeIncome,
        'label': 'Receita',
        'icon': Icons.trending_up_rounded,
        'gradient': AppGradients.success,
      },
      {
        'type': AppConstants.typeExpense,
        'label': 'Despesa',
        'icon': Icons.trending_down_rounded,
        'gradient': AppGradients.danger,
      },
      {
        'type': AppConstants.typeInvestmentIn,
        'label': 'Aplicar Investimento',
        'icon': Icons.savings_rounded,
        'gradient': AppGradients.investment,
      },
      {
        'type': AppConstants.typeInvestmentOut,
        'label': 'Resgatar Investimento',
        'icon': Icons.payments_rounded,
        'gradient': AppGradients.warning,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passo 1 de 4',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Tipo de movimentação',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        ...types.map((t) {
          final isSelected = _type == t['type'];
          return GestureDetector(
            onTap: () => setState(() {
              _type = t['type'] as String;
              _category = _getDefaultCategory(_type);
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isSelected ? t['gradient'] as LinearGradient : null,
                color: isSelected ? null : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : AppColors.borderLight,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    t['icon'] as IconData,
                    size: 32,
                    color: isSelected ? Colors.white : (t['gradient'] as LinearGradient).colors.first,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    t['label'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passo 2 de 4',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Valor e data',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          validator: AppValidators.amount,
          decoration: const InputDecoration(
            labelText: 'Valor (R\$)',
            prefixIcon: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'R\$',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          onChanged: (v) {
            String digits = v.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.isEmpty) {
              _amountController.value = const TextEditingValue(
                text: '0,00',
                selection: TextSelection.collapsed(offset: 4),
              );
              return;
            }
            double value = double.parse(digits) / 100;
            final formatted = CurrencyFormatter.formatNoSymbol(value);
            _amountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          },
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              locale: const Locale('pt', 'BR'),
            );
            if (picked != null) setState(() => _date = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    Text(
                      '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passo 3 de 4',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Descrição e categoria',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descrição',
            prefixIcon: Icon(Icons.description_outlined),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _categories.any((c) => c['key'] == _category)
              ? _category
              : _categories.first['key'] as String,
          decoration: const InputDecoration(
            labelText: 'Categoria',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: _categories.map((c) {
            return DropdownMenuItem<String>(
              value: c['key'] as String,
              child: Row(
                children: [
                  Text(c['icon'] as String),
                  const SizedBox(width: 8),
                  Text(c['label'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _category = v ?? 'outros'),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passo 4 de 4',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Detalhes adicionais',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        // Payment status
        Row(
          children: [
            Expanded(
              child: _StatusButton(
                label: 'Pago',
                icon: Icons.check_circle_rounded,
                color: AppColors.income,
                isSelected: _paymentStatus == AppConstants.statusPaid,
                onTap: () =>
                    setState(() => _paymentStatus = AppConstants.statusPaid),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusButton(
                label: 'Pendente',
                icon: Icons.schedule_rounded,
                color: AppColors.pending,
                isSelected: _paymentStatus == AppConstants.statusPending,
                onTap: () =>
                    setState(() => _paymentStatus = AppConstants.statusPending),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusButton(
                label: 'Agendado',
                icon: Icons.event_outlined,
                color: AppColors.secondary,
                isSelected: _paymentStatus == AppConstants.statusScheduled,
                onTap: () => setState(
                  () => _paymentStatus = AppConstants.statusScheduled,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _paymentMethod,
          decoration: const InputDecoration(
            labelText: 'Forma de pagamento',
            prefixIcon: Icon(Icons.payment_rounded),
          ),
          items: AppConstants.paymentMethods.map((m) {
            return DropdownMenuItem<String>(value: m, child: Text(m));
          }).toList(),
          onChanged: (v) => setState(() => _paymentMethod = v),
        ),
        const SizedBox(height: 16),
        // Recurring
        SwitchListTile(
          title: const Text('Recorrente'),
          subtitle: const Text('Esta transação se repete?'),
          value: _isRecurring,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _isRecurring = v),
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _recurringFrequency,
            decoration: const InputDecoration(labelText: 'Frequência'),
            items: const [
              DropdownMenuItem(
                value: AppConstants.freqMonthly,
                child: Text('Mensal'),
              ),
              DropdownMenuItem(
                value: AppConstants.freqYearly,
                child: Text('Anual'),
              ),
              DropdownMenuItem(
                value: AppConstants.freqWeekly,
                child: Text('Semanal'),
              ),
            ],
            onChanged: (v) => setState(() => _recurringFrequency = v),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 16),
        // Goal selection
        ref.watch(goalsProvider).when(
              data: (goals) {
                if (goals.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String>(
                  value: _selectedGoalId,
                  decoration: const InputDecoration(
                    labelText: 'Vincular a uma Meta',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                    ...goals.map((g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedGoalId = v),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

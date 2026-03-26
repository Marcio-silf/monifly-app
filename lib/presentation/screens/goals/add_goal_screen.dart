import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/goal.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  final String? goalId;
  const AddGoalScreen({super.key, this.goalId});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  String _category = 'viagem';
  DateTime? _targetDate;
  String _color = '#06B6D4';
  bool _hasCurrentAmount = false;
  bool _isLoading = false;
  Goal? _existingGoal;

  @override
  void initState() {
    super.initState();
    if (widget.goalId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGoal();
      });
    }
  }

  void _loadGoal() {
    final goals = ref.read(goalsProvider).valueOrNull ?? [];
    final goal = goals.firstWhere((g) => g.id == widget.goalId);
    _existingGoal = goal;
    _nameController.text = goal.name;
    _descriptionController.text = goal.description ?? '';
    _targetAmountController.text = goal.targetAmount.toString();
    _currentAmountController.text = goal.currentAmount.toString();
    setState(() {
      _category = goal.category;
      _targetDate = goal.targetDate;
      _color = goal.color;
      _hasCurrentAmount = goal.currentAmount > 0;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final targetAmount =
          double.tryParse(_targetAmountController.text.replaceAll(',', '.')) ??
              0;
      final currentAmount = _hasCurrentAmount
          ? (double.tryParse(
                _currentAmountController.text.replaceAll(',', '.'),
              ) ??
              0)
          : 0.0;
      final goal = (_existingGoal ?? Goal.empty(user.id)).copyWith(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        category: _category,
        color: _color,
      );
      
      if (_existingGoal != null) {
        await ref.read(goalsProvider.notifier).updateGoal(goal);
      } else {
        await ref.read(goalsProvider.notifier).addGoal(goal);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingGoal != null ? 'Editar Meta' : AppStrings.newGoal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo/logo_monifly.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vamos criar sua nova meta!',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                validator: AppValidators.name,
                decoration: const InputDecoration(
                  labelText: 'Nome da meta (ex: Viagem para Disney)',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.goalCategories.map((c) {
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
              const SizedBox(height: 16),
              // Target amount
              TextFormField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                validator: AppValidators.positiveNumber,
                decoration: const InputDecoration(
                  labelText: 'Valor alvo (R\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 16),
              // Target date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) setState(() => _targetDate = picked);
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
                      Text(
                        _targetDate == null
                            ? 'Data alvo (opcional)'
                            : '${_targetDate!.day.toString().padLeft(2, '0')}/${_targetDate!.month.toString().padLeft(2, '0')}/${_targetDate!.year}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _targetDate == null
                                  ? AppColors.textSecondaryLight
                                  : null,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Has current amount?
              CheckboxListTile(
                title: const Text('Já guardei algum valor'),
                value: _hasCurrentAmount,
                onChanged: (v) =>
                    setState(() => _hasCurrentAmount = v ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              if (_hasCurrentAmount) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor já guardado (R\$)',
                    prefixIcon: Icon(Icons.savings_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : ClipOval(
                          child: Image.asset(
                            'assets/images/logo/logo_monifly.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                          ),
                        ),
                  label: Text(_existingGoal != null
                      ? (_isLoading ? 'Salvando...' : 'Salvar Alterações')
                      : (_isLoading ? 'Criando...' : 'Criar meta')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



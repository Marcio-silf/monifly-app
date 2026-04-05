import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/providers/goal_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/premium/upgrade_modal.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addAmount(dynamic goal) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.addToGoal,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
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

            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final amount =
                      double.tryParse(
                        _amountController.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  if (amount > 0) {
                    await ref
                        .read(goalsProvider.notifier)
                        .addAmountToGoal(goal, amount);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _amountController.clear();
                  }
                },
                icon: const Text('✈️', style: TextStyle(fontSize: 18)),
                label: const Text('Adicionar à meta'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      body: goalsAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
        data: (goals) {
          final list = goals.where((g) => g.id == widget.goalId).toList();
          if (list.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Meta não encontrada')),
            );
          }
          final goal = list.first;
          final progress = (goal.progressPercent / 100).clamp(0.0, 1.0);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppGradients.monifly,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Big circular progress
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          value: progress > 0 ? progress : 0.001, // Small value if 0 to show background properly
                                          color: Colors.white,
                                          radius: 24,
                                          showTitle: false,
                                        ),
                                        PieChartSectionData(
                                          value: progress < 1 ? (1 - progress) : 0,
                                          color: Colors.white.withValues(alpha: 0.2),
                                          radius: 24,
                                          showTitle: false,
                                        ),
                                      ],
                                      centerSpaceRadius: 36,
                                      sectionsSpace: 0,
                                      startDegreeOffset: 270,
                                    ),
                                  ),
                                  Text(
                                    '${goal.progressPercent.toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              goal.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (goal.targetDate != null)
                              Text(
                                DateFormatter.formatDueDate(goal.targetDate!),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final subscription = ref.read(subscriptionProvider);
                      if (!subscription.isPremium && goals.length > 1) {
                         // Sort goals by date to find the first one
                         final sorted = [...goals];
                         sorted.sort((a,b) => a.createdAt.compareTo(b.createdAt));
                         final firstId = sorted.first.id;
                         
                         if (goal.id != firstId) {
                           UpgradeModal.show(
                             context,
                             title: 'Apenas uma meta editável',
                             message: 'No plano Grátis você só pode editar sua primeira meta cadastrada.\nPara editar todas as suas metas, assine o plano Premium.',
                           );
                           return;
                         }
                      }
                      Navigator.pushNamed(
                        context,
                        AppConstants.routeAddGoal,
                        arguments: {'id': goal.id},
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      await ref
                          .read(goalsProvider.notifier)
                          .deleteGoal(goal.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],

              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Progress info
                    _InfoRow(
                      label: 'Valor atual',
                      value: CurrencyFormatter.format(goal.currentAmount),
                    ),
                    _InfoRow(
                      label: 'Valor alvo',
                      value: CurrencyFormatter.format(goal.targetAmount),
                    ),
                    _InfoRow(
                      label: 'Faltam',
                      value: CurrencyFormatter.format(goal.remaining),
                    ),
                    if (goal.monthlyContributionNeeded > 0)
                      _InfoRow(
                        label: 'Contribuição mensal',
                        value: CurrencyFormatter.format(
                          goal.monthlyContributionNeeded,
                        ),
                      ),
                    if (goal.targetDate != null)
                      _InfoRow(
                        label: 'Dias restantes',
                        value: '${goal.daysRemaining} dias',
                      ),
                    if (goal.description != null &&
                        goal.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        goal.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Add amount button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: goal.isCompleted
                            ? null
                            : () => _addAmount(goal),
                        icon: const Text('✈️', style: TextStyle(fontSize: 18)),
                        label: Text(
                          goal.isCompleted
                              ? 'Meta concluída! 🎉'
                              : AppStrings.addToGoal,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}


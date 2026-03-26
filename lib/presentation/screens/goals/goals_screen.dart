import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/goal_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/cards/goal_card.dart';
import '../../widgets/premium/upgrade_modal.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final activeGoals = ref.watch(activeGoalsProvider);
    final completedGoals = ref.watch(completedGoalsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).state = 0;
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppGradients.monifly),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          AppStrings.myGoals,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          AppStrings.goalsSubtitle,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        goalsAsync.when(
                          data: (goals) {
                            final totalTarget = goals.fold<double>(
                              0,
                              (s, g) => s + g.targetAmount,
                            );
                            final totalCurrent = goals.fold<double>(
                              0,
                              (s, g) => s + g.currentAmount,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${CurrencyFormatter.format(totalCurrent)} / ${CurrencyFormatter.format(totalTarget)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Active Goals
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (activeGoals.isNotEmpty) ...[
                  Text(
                    AppStrings.activeGoals,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...activeGoals.map(
                    (g) => GoalCard(
                      goal: g,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppConstants.routeGoalDetail,
                        arguments: {'id': g.id},
                      ),
                    ),
                  ),
                ],
                if (completedGoals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${AppStrings.completedGoals} 🎉',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...completedGoals.map((g) => GoalCard(goal: g)),
                ],
                if (activeGoals.isEmpty && completedGoals.isEmpty)
                  const EmptyStateWidget(
                    title: 'Nenhuma meta ainda',
                    message:
                        'Crie sua primeira meta e salve para o seu futuro! 🎯',
                    actionLabel: 'Criar meta',
                  ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.monifly,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            final subscription = ref.read(subscriptionProvider);
            if (!subscription.isPremium && activeGoals.isNotEmpty) {
              UpgradeModal.show(
                context,
                title: 'Desbloqueie Metas Ilimitadas!',
                message: 'No plano Grátis você pode ter apenas 1 meta ativa de cada vez.\nPara organizar todos os seus sonhos, assine o Monifly Premium.',
              );
              return;
            }
            Navigator.pushNamed(context, AppConstants.routeAddGoal);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

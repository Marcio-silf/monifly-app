import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:monifly/data/models/goal.dart';
import 'package:monifly/core/constants/colors.dart';
import 'package:monifly/core/utils/currency_formatter.dart';
import 'package:monifly/core/constants/app_constants.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (goal.progressPercent / 100).clamp(0.0, 1.0);
    final goalColor = _getGoalColor(goal.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: goalColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _getCategoryIcon(goal.category),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (goal.targetDate != null)
                        Text(
                          '${goal.daysRemaining} dias restantes',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                        ),
                    ],
                  ),
                ),
                // Progress percentage
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${goal.progressPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: goalColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: goalColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(goalColor),
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(goal.currentAmount),
                  style: TextStyle(
                    color: goalColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(goal.targetAmount),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (goal.monthlyContributionNeeded > 0) ...[
              const SizedBox(height: 6),
              Text(
                '✈️ Contribuição mensal: ${CurrencyFormatter.format(goal.monthlyContributionNeeded)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getGoalColor(String category) {
    switch (category) {
      case 'viagem':
        return AppColors.primary;
      case 'carro':
        return AppColors.accent;
      case 'casa':
        return AppColors.income;
      case 'estudos':
        return AppColors.investment;
      case 'aposentadoria':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  String _getCategoryIcon(String category) {
    final match = AppConstants.goalCategories.where(
      (c) => c['key'] == category,
    );
    if (match.isNotEmpty) return match.first['icon'] as String;
    return '🎯';
  }
}


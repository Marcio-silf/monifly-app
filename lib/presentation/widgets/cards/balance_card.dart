import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monifly/core/constants/strings.dart';
import 'package:monifly/core/utils/currency_formatter.dart';
import 'package:monifly/data/providers/theme_provider.dart';
import 'package:monifly/core/constants/colors.dart';
import '../common/gradient_card.dart';

class BalanceCard extends ConsumerWidget {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double totalInvested;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.totalInvested,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(balanceVisibleProvider);

    return GradientCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalBalance,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        ref.read(balanceVisibleProvider.notifier).toggle(),
                    child: Icon(
                      isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          isVisible
              ? Text(
                  CurrencyFormatter.format(totalBalance),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                      ),
                )
              : Text(
                  'R\$ ••••••',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        fontSize: 28,
                      ),
                ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                label: AppStrings.monthlyIncome,
                amount: monthlyIncome,
                icon: Icons.arrow_upward_rounded,
                color: AppColors.income,
                isVisible: isVisible,
              ),
              const SizedBox(width: 16),
              _StatItem(
                label: AppStrings.monthlyExpense,
                amount: monthlyExpense,
                icon: Icons.arrow_downward_rounded,
                color: AppColors.expense,
                isVisible: isVisible,
              ),
              const SizedBox(width: 16),
              _StatItem(
                label: AppStrings.totalInvested,
                amount: totalInvested,
                icon: Icons.trending_up_rounded,
                color: AppColors.investment,
                isVisible: isVisible,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isVisible;

  const _StatItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isVisible ? CurrencyFormatter.format(amount) : '••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


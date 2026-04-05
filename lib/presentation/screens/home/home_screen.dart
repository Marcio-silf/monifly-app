import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monifly/core/constants/colors.dart';
import 'package:monifly/core/constants/gradients.dart';
import 'package:monifly/core/constants/strings.dart';
import 'package:monifly/core/constants/app_constants.dart';
import 'package:monifly/core/utils/currency_formatter.dart';
import 'package:monifly/core/utils/calculators.dart';
import 'package:monifly/data/providers/auth_provider.dart';
import 'package:monifly/data/providers/transaction_provider.dart';
import 'package:monifly/data/providers/goal_provider.dart';
import 'package:monifly/data/providers/notification_provider.dart';
import 'package:monifly/data/providers/navigation_provider.dart';
import 'package:monifly/data/providers/spending_plan_provider.dart';
import 'package:monifly/presentation/widgets/cards/balance_card.dart';
import 'package:monifly/presentation/widgets/cards/transaction_card.dart';
import 'package:monifly/presentation/widgets/common/month_picker.dart';
import 'package:monifly/presentation/widgets/common/loading_indicator.dart';
import 'package:monifly/presentation/widgets/common/empty_state.dart';
import '../../providers/subscription_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 18) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final overallBalance = ref.watch(overallBalanceProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final pendingBills = ref.watch(pendingBillsProvider);
    final activeGoals = ref.watch(activeGoalsProvider);
    final subscription = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fabKey = GlobalKey<_ExpandableFABState>();

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (fabKey.currentState?._isOpen ?? false) {
            fabKey.currentState?._toggle();
          }
        },
        child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(transactionsProvider.notifier).refresh();
          await ref.read(goalsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      children: [
                        // Month Selector on Top Right
                        Align(
                          alignment: Alignment.topRight,
                          child: MonthPicker(
                            selectedMonth: selectedMonth,
                            isCompact: true,
                            onChanged: (val) => ref
                                .read(selectedMonthProvider.notifier)
                                .state = val,
                          ),
                        ),
                        const Spacer(),
                        // Main row with Logo, Greeting and Notification
                        Row(
                          children: [
                            // Logo
                            ClipOval(
                              child: Image.asset(
                                'assets/images/logo/logo_monifly.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Greeting + name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  profileAsync.when(
                                    data: (profile) => RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${_getGreeting()}, ',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: isDark
                                                      ? AppColors.textSecondaryDark
                                                      : AppColors
                                                          .textSecondaryLight,
                                                ),
                                          ),
                                          TextSpan(
                                            text:
                                                '${profile?.firstName ?? 'Usuário'}! ',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                  Text(
                                    _formatDate(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Notification Icon far right
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppConstants.routeNotifications,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (ref
                                      .watch(displayableNotificationsProvider)
                                      .any((n) => n.isNew))
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.expense,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Balance Card
                  BalanceCard(
                    totalBalance: summary['balance'] ?? 0,
                    monthlyIncome: summary['income'] ?? 0,
                    monthlyExpense: summary['expense'] ?? 0,
                    totalInvested: summary['netInvestment'] ?? 0,
                  ),
                  const SizedBox(height: 16),

                  if (subscription.planType == 'trial' && subscription.premiumUntil != null)
                    _buildTrialAlert(context, subscription.premiumUntil!),
                  
                  if (!subscription.isPremium)
                    _buildUsageLimitTracker(context, transactionsAsync.valueOrNull ?? []),

                  // Smart Notifications Carousel
                  _NotificationsCarousel(
                    pendingBillsCount: pendingBills.length,
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats Row
                  _QuickStatsRow(
                    goalsTotal: activeGoals.fold<double>(
                      0,
                      (s, g) => s + g.currentAmount,
                    ),
                    billsToPay: pendingBills.fold<double>(
                      0,
                      (s, t) => s + t.amount,
                    ),
                    totalInvested: summary['netInvestment'] ?? 0,
                  ),
                  const SizedBox(height: 16),

                  // Financial Health Score
                  _HealthScoreCard(
                    income: summary['income'] ?? 0,
                    expense: summary['expense'] ?? 0,
                    investment: summary['netInvestment'] ?? 0,
                  ),
                  const SizedBox(height: 16),

                  // Planning Tracking Card
                  const _PlanningTrackingCard(),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _QuickActions(),
                  const SizedBox(height: 16),

                  // Recent Transactions
                  _RecentTransactions(
                    transactionsAsync: transactionsAsync,
                    ref: ref,
                  ),
                  const SizedBox(height: 16),

                  // Expense Donut Chart
                  _ExpenseDonutChart(
                    transactionsAsync: transactionsAsync,
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    ),
      floatingActionButton: _ExpandableFAB(key: fabKey),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    const weekdays = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';
  }

  Widget _buildTrialAlert(BuildContext context, DateTime premiumUntil) {
    final diff = premiumUntil.difference(DateTime.now());
    final days = diff.inDays + (diff.inHours % 24 > 0 ? 1 : 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.income.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.income),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Período de Teste Premium', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.income)),
                Text('Aproveite todas as funções. Restam $days dias.', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageLimitTracker(BuildContext context, List<dynamic> transactions) {
    final now = DateTime.now();
    final currentMonthTxs = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).length;
    final progress = (currentMonthTxs / 15.0).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lançamentos Grátis', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$currentMonthTxs / 15', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? AppColors.expense : AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              const Expanded(child: Text('Renova no dia 1 de cada mês', style: TextStyle(fontSize: 11, color: Colors.grey))),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppConstants.routePaywall),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ser Premium', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Notifications Carousel ─────────────────────────────────────────────────────

class _NotificationsCarousel extends ConsumerStatefulWidget {
  final int pendingBillsCount;
  const _NotificationsCarousel({required this.pendingBillsCount});

  @override
  ConsumerState<_NotificationsCarousel> createState() =>
      _NotificationsCarouselState();
}

class _NotificationsCarouselState extends ConsumerState<_NotificationsCarousel> {
  int _index = 0;

  List<Map<String, dynamic>> _getNotifications(List<NotificationItem> unread) {
    if (unread.isEmpty) return [];

    return unread.map((n) {
      return {
        'id': n.id,
        'icon': n.icon,
        'text': n.message,
        'color': AppColors.primary,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allNotifications = ref.watch(notificationsProvider);
    final unread = allNotifications.where((n) => n.isNew).toList();
    final items = _getNotifications(unread);

    if (items.isEmpty) return const SizedBox.shrink();
    if (_index >= items.length) _index = 0;

    final n = items[_index];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppConstants.routeNotifications),
      onHorizontalDragEnd: (details) {
        if (items.length <= 1) return;
        if (details.primaryVelocity! < 0) {
          setState(() => _index = (_index + 1) % items.length);
        } else {
          setState(
            () => _index = (_index - 1 + items.length) % items.length,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (n['color'] as Color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: (n['color'] as Color).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(n['icon'] as IconData, size: 24, color: n['color'] as Color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                n['text'] as String,
                style: TextStyle(
                  color: n['color'] as Color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            if (items.length > 1)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  items.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? (n['color'] as Color)
                          : (n['color'] as Color).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Stats Row ─────────────────────────────────────────────────────────────

class _QuickStatsRow extends ConsumerWidget {
  final double goalsTotal;
  final double billsToPay;
  final double totalInvested;

  const _QuickStatsRow({
    required this.goalsTotal,
    required this.billsToPay,
    required this.totalInvested,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.rocket_launch_rounded,
          label: AppStrings.goalsTotal,
          amount: goalsTotal,
          color: AppColors.primary,
          onTap: () => ref.read(navigationIndexProvider.notifier).state = 2,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.calendar_month_rounded,
          label: AppStrings.billsToPay,
          amount: billsToPay,
          color: AppColors.pending,
          onTap: () => Navigator.pushNamed(context, AppConstants.routeBills),
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.trending_up_rounded,
          label: AppStrings.investments,
          amount: totalInvested,
          color: AppColors.investment,
          onTap: () =>
              Navigator.pushNamed(context, AppConstants.routeInvestments),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Financial Health Score ─────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final double income;
  final double expense;
  final double investment;

  const _HealthScoreCard({
    required this.income,
    required this.expense,
    required this.investment,
  });

  @override
  Widget build(BuildContext context) {
    final score = AppCalculators.calculateHealthScore(
      monthlyIncome: income,
      monthlyExpense: expense,
      monthlyInvestment: investment,
      budgetAdherence: 0.8,
    );

    final scoreColor = score >= 80
        ? AppColors.income
        : score >= 60
            ? AppColors.primary
            : score >= 40
                ? AppColors.accent
                : AppColors.expense;

    final scoreIcon = score >= 80
        ? Icons.rocket_launch_rounded
        : score >= 60
            ? Icons.check_circle_rounded
            : score >= 40
                ? Icons.warning_rounded
                : Icons.error_rounded;

    final scoreLabel = score >= 80
        ? 'Excelente!'
        : score >= 60
            ? 'Bom'
            : score >= 40
                ? 'Regular'
                : 'Atenção!';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: score > 0 ? (score / 100) : 0.001,
                        color: scoreColor,
                        radius: 16,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: score < 100 ? (1 - (score / 100)) : 0,
                        color: scoreColor.withValues(alpha: 0.1),
                        radius: 16,
                        showTitle: false,
                      ),
                    ],
                    centerSpaceRadius: 24,
                    sectionsSpace: 0,
                    startDegreeOffset: 270,
                  ),
                ),
                Text(
                  score.toInt().toString(),
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.financialHealth,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(scoreIcon, color: scoreColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  income >= expense
                      ? 'Você economizou ${CurrencyFormatter.format((income - expense).abs())} este mês'
                      : 'Você gastou ${CurrencyFormatter.format((expense - income).abs())} acima da renda',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickActionItem(
          icon: Icons.insights_rounded,
          label: 'Estratégia',
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, AppConstants.routeStrategy),
        ),
        _QuickActionItem(
          icon: Icons.receipt_long_rounded,
          label: 'Contas',
          color: AppColors.pending,
          onTap: () => Navigator.pushNamed(context, AppConstants.routeBills),
        ),
        _QuickActionItem(
          icon: Icons.savings_rounded,
          label: 'Investir',
          color: AppColors.investment,
          onTap: () =>
              Navigator.pushNamed(context, AppConstants.routeInvestments),
        ),
        _QuickActionItem(
          icon: Icons.donut_large_rounded,
          label: 'Orçamento',
          color: AppColors.accent,
          onTap: () => Navigator.pushNamed(context, AppConstants.routeBudget),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Recent Transactions ────────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  final AsyncValue transactions;
  final WidgetRef ref;

  const _RecentTransactions({
    required this.transactionsAsync,
    required this.ref,
  }) : transactions = transactionsAsync;

  final AsyncValue transactionsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.recentTransactions,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(navigationIndexProvider.notifier).state = 1,
              child: const Text(AppStrings.seeAll),
            ),
          ],
        ),
        const SizedBox(height: 8),
        transactionsAsync.when(
          loading: () => const MoniflyLoader(),
          error: (e, _) => AppErrorWidget(message: e.toString()),
          data: (data) {
            final txns = data as List;
            if (txns.isEmpty) {
              return const EmptyStateWidget(
                title: 'Nenhuma transação',
                message: 'Toque no + para adicionar sua primeira movimentação',
              );
            }
            final recent = txns.take(5).toList();
            return Column(
              children: recent.map((t) {
                return TransactionCard(
                  transaction: t,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppConstants.routeTransactionDetail,
                    arguments: {'id': t.id},
                  ),
                  onDelete: () => ref
                      .read(transactionsProvider.notifier)
                      .deleteTransaction(t.id),
                  onEdit: () => Navigator.pushNamed(
                    context,
                    AppConstants.routeAddTransaction,
                    arguments: {'id': t.id},
                  ),
                  onStatusChange: (status) => ref
                      .read(transactionsProvider.notifier)
                      .updateTransactionStatus(t.id, status),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Expandable FAB ─────────────────────────────────────────────────────────────

class _ExpandableFAB extends StatefulWidget {
  const _ExpandableFAB({super.key});

  @override
  State<_ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<_ExpandableFAB>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _navigateToAdd(BuildContext context, String type) {
    _toggle();
    Navigator.pushNamed(
      context,
      AppConstants.routeAddTransaction,
      arguments: {'type': type},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sub-buttons
        ScaleTransition(
          scale: _expandAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _FabOption(
                label: 'Nova Meta',
                color: AppColors.accent,
                icon: Icons.flag_rounded,
                onTap: () {
                  _toggle();
                  Navigator.pushNamed(context, AppConstants.routeAddGoal);
                },
              ),
              const SizedBox(height: 8),
              _FabOption(
                label: 'Novo Investimento',
                color: AppColors.investment,
                icon: Icons.trending_up_rounded,
                onTap: () =>
                    _navigateToAdd(context, AppConstants.typeInvestmentIn),
              ),
              const SizedBox(height: 8),
              _FabOption(
                label: 'Nova Despesa',
                color: AppColors.expense,
                icon: Icons.remove_circle_outline_rounded,
                onTap: () => _navigateToAdd(context, AppConstants.typeExpense),
              ),
              const SizedBox(height: 8),
              _FabOption(
                label: 'Nova Receita',
                color: AppColors.income,
                icon: Icons.add_circle_outline_rounded,
                onTap: () => _navigateToAdd(context, AppConstants.typeIncome),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Main FAB
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 60,
            height: 60,
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
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FabOption extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _FabOption({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Planning Tracking Card ──────────────────────────────────────────────────────

class _PlanningTrackingCard extends ConsumerWidget {
  const _PlanningTrackingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(monthlyReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // No plan exists
    if (report == null || report.plannedExpenses == 0) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/spending-plan'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.event_note_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planejamento Mensal',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Crie um plano de gastos por categoria',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    // Plan exists – show tracking
    final progress = report.plannedExpenses > 0
        ? (report.actualExpenses / report.plannedExpenses).clamp(0.0, 1.0)
        : 0.0;
    final progressPct = (progress * 100).toStringAsFixed(0);
    final diff = report.plannedExpenses - report.actualExpenses;
    final diffLabel = diff >= 0 ? 'economia' : 'excedente';
    final diffColor = diff >= 0 ? AppColors.income : AppColors.expense;

    return GestureDetector(
      onTap: () {
        // Navigate to Reports tab (index 3) - Planejamento tab
        ref.read(navigationIndexProvider.notifier).state = 3;
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
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
                const Icon(Icons.analytics_outlined, size: 24, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Acompanhamento do Mês',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TrackingValue(label: 'Planejado', value: report.plannedExpenses, color: AppColors.primary),
                _TrackingValue(label: 'Realizado', value: report.actualExpenses, color: AppColors.accent),
                _TrackingValue(label: diffLabel, value: diff.abs(), color: diffColor),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  diff >= 0 ? AppColors.primary : AppColors.expense,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$progressPct% do orçamento utilizado',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CategoryCountChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Dentro',
                  count: report.categoriesWithinBudget,
                  color: AppColors.income,
                ),
                const SizedBox(width: 8),
                _CategoryCountChip(
                  icon: Icons.warning_rounded,
                  label: 'Acima',
                  count: report.categoriesOverBudget,
                  color: AppColors.expense,
                ),
                const Spacer(),
                Text(
                  'Ver relatório →',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingValue extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _TrackingValue({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatCompact(value),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

class _CategoryCountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _CategoryCountChip({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label: $count', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Expense Donut Chart ─────────────────────────────────────────────────────────

class _ExpenseDonutChart extends StatelessWidget {
  final AsyncValue transactionsAsync;
  const _ExpenseDonutChart({required this.transactionsAsync});

  static const _chartColors = [
    Color(0xFF00BFA6), Color(0xFF00ACC1), Color(0xFF5C6BC0), Color(0xFFAB47BC),
    Color(0xFFEF5350), Color(0xFFFF7043), Color(0xFFFFA726), Color(0xFFFFCA28),
    Color(0xFF66BB6A), Color(0xFF26A69A), Color(0xFF42A5F5), Color(0xFF7E57C2),
    Color(0xFFEC407A), Color(0xFF8D6E63), Color(0xFF78909C), Color(0xFFD4E157),
    Color(0xFF29B6F6), Color(0xFFFF8A65), Color(0xFF9CCC65), Color(0xFFBDBDBD),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return transactionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final txns = (data as List).where((t) => t.isExpense && t.isPaid).toList();
        if (txns.isEmpty) return const SizedBox.shrink();

        // Group by category
        final Map<String, double> byCategory = {};
        double total = 0;
        for (var t in txns) {
          byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
          total += t.amount;
        }

        // Sort by value descending
        final sorted = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        List<Map<String, dynamic>> displayData = [];
        double cumulative = 0;
        double othersSum = 0;
        bool inOthers = false;

        for (int i = 0; i < sorted.length; i++) {
          final e = sorted[i];
          if (!inOthers) {
            displayData.add({
              'key': e.key,
              'label': _getCategoryLabel(e.key),
              'value': e.value,
              'color': _chartColors[displayData.length % _chartColors.length],
            });
            cumulative += e.value;

            // Group if cumulative >= 80% AND we have more than 1 item left
            if (cumulative >= total * 0.8 && i < sorted.length - 1) {
              if (sorted.length - i > 1) {
                inOthers = true;
              }
            }
          } else {
            othersSum += e.value;
          }
        }

        if (othersSum > 0) {
          displayData.add({
            'key': 'others',
            'label': 'Outros',
            'value': othersSum,
            'color': Colors.grey[500]!,
            'isOthers': true,
          });
        }

        final sections = displayData.map((data) {
          final double val = data['value'];
          final pct = total > 0 ? (val / total * 100) : 0.0;
          return PieChartSectionData(
            value: val,
            title: '${pct.toStringAsFixed(0)}%',
            color: data['color'] as Color,
            radius: 35,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Despesas por Categoria',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 55,
                        sectionsSpace: 2,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatCompact(total),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              ...displayData.map((data) {
                final double val = data['value'];
                final pct = total > 0 ? (val / total * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: data['color'] as Color, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(data['label'] as String, style: const TextStyle(fontSize: 13))),
                      Text(
                        CurrencyFormatter.formatCompact(val),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${pct.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _getCategoryLabel(String category) {
    final match = AppConstants.expenseCategories.where((c) => c['key'] == category);
    if (match.isNotEmpty) return match.first['label'] as String;
    return category;
  }
}

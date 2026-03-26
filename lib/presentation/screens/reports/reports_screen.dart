import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../data/models/transaction.dart';
import '../../../core/services/export_service.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/premium/upgrade_modal.dart';
import 'category_report_tab.dart';
import '../../../data/providers/spending_plan_provider.dart';
import '../../widgets/common/month_picker.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(monthlySummaryProvider);
    final expenseByCategory = ref.watch(expenseByCategoryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        actions: [
          MonthPicker(
            selectedMonth: selectedMonth,
            isCompact: true,
            onChanged: (val) => ref.read(selectedMonthProvider.notifier).state = val,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: AppStrings.exportCSV,
            onPressed: () {
              final subscription = ref.read(subscriptionProvider);
              if (!subscription.isPremium) {
                UpgradeModal.show(
                  context,
                  title: 'Relatórios Avançados!',
                  message: 'A exportação de dados em Excel com múltiplas abas e relatórios detalhados são exclusivos do plano Premium.\nAssine agora para ter total controle dos seus dados.',
                );
                return;
              }

              final transactions = transactionsAsync.valueOrNull ?? [];
              final expenseByCategory = ref.read(expenseByCategoryProvider);
              final report = ref.read(monthlyReportProvider);

              if (transactions.isNotEmpty) {
                ExportService.exportFullReport(
                  summary: summary,
                  expenseByCategory: expenseByCategory,
                  report: report,
                  transactions: transactions,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Nenhuma movimentação para exportar')),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumo'),
            Tab(text: 'Categorias'),
            Tab(text: 'Planejamento'),
            Tab(text: 'Evolução'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Summary
          _SummaryTab(summary: summary),
          // Tab 2: Categories (Transactions only)
          _CategoriesTab(expenseByCategory: expenseByCategory),
          // Tab 3: Planning Comparison
          Consumer(builder: (context, ref, _) {
            final subscription = ref.watch(subscriptionProvider);
            if (!subscription.isPremium) {
              return _PremiumLockOverlay(
                title: 'Comparativo de Planejamento',
                description: 'Veja o quanto você planejou vs o quanto gastou em cada categoria com riqueza de detalhes.',
              );
            }
            return const CategoryReportTab();
          }),
          // Tab 4: Evolution
          Consumer(builder: (context, ref, _) {
            final subscription = ref.watch(subscriptionProvider);
            if (!subscription.isPremium) {
              return _PremiumLockOverlay(
                title: 'Evolução Patrimonial',
                description: 'Gráficos avançados de evolução diária e mensal para você dominar seu futuro financeiro.',
              );
            }
            return _EvolutionTab(transactionsAsync: transactionsAsync);
          }),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final Map<String, double> summary;
  const _SummaryTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final income = summary['income'] ?? 0;
    final expense = summary['expense'] ?? 0;
    final balance = summary['balance'] ?? 0;
    final investment = summary['investmentIn'] ?? 0;
    final savingsRate = income > 0 ? ((income - expense) / income * 100) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Big balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'Saldo do Mês',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Taxa de poupança: ${savingsRate.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Receitas',
                  amount: income,
                  icon: Icons.trending_up_rounded,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Despesas',
                  amount: expense,
                  icon: Icons.trending_down_rounded,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Investido',
                  amount: investment,
                  icon: Icons.savings_rounded,
                  color: AppColors.investment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Economizado',
                  amount: (income - expense).clamp(0, double.infinity),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final Map<String, double> expenseByCategory;
  const _CategoriesTab({required this.expenseByCategory});

  @override
  Widget build(BuildContext context) {
    final allCats = AppConstants.expenseCategories;
    
    // Create a list of all categories with their spent values
    final List<Map<String, dynamic>> catData = allCats.map((cat) {
      final key = cat['key'] as String;
      final spent = expenseByCategory[key] ?? 0.0;
      return {
        'key': key,
        'label': cat['label'] as String,
        'icon': cat['icon'] as String,
        'spent': spent,
      };
    }).toList();

    // Sort by spent amount (descending), then by label
    catData.sort((a, b) {
      final spentComp = (b['spent'] as double).compareTo(a['spent'] as double);
      if (spentComp != 0) return spentComp;
      return (a['label'] as String).compareTo(b['label'] as String);
    });

    final total = expenseByCategory.values.fold<double>(0, (s, v) => s + v);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: catData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final data = catData[i];
        final spent = data['spent'] as double;
        final pct = total > 0 ? spent / total : 0.0;
        final icon = data['icon'] as String;
        final catLabel = data['label'] as String;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      catLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(spent),
                    style: TextStyle(
                      color: spent > 0 ? AppColors.expense : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.expense.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  spent > 0 ? AppColors.expense : AppColors.textSecondaryLight.withValues(alpha: 0.3)
                ),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}


class _EvolutionTab extends StatelessWidget {
  final AsyncValue<List<Transaction>> transactionsAsync;
  const _EvolutionTab({required this.transactionsAsync});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Text('Nenhuma movimentação este mês'));
        }

        // Sort transactions by date
        final sorted = List<Transaction>.from(transactions)
          ..sort((a, b) => a.date.compareTo(b.date));

        // Build cumulative daily data
        final Map<int, double> incomeByDay = {};
        final Map<int, double> expenseByDay = {};
        final Map<int, double> investByDay = {};

        double cumIncome = 0, cumExpense = 0, cumInvest = 0;

        // Collect all days that have transactions
        final Set<int> allDays = {};
        for (final t in sorted) {
          allDays.add(t.date.day);
        }

        final sortedDays = allDays.toList()..sort();

        for (final day in sortedDays) {
          final dayTxns = sorted.where((t) => t.date.day == day);
          for (final t in dayTxns) {
            if (t.isIncome) cumIncome += t.amount;
            if (t.isExpense && t.isPaid) cumExpense += t.amount;
            if (t.isInvestmentIn) cumInvest += t.amount;
          }
          incomeByDay[day] = cumIncome;
          expenseByDay[day] = cumExpense;
          investByDay[day] = cumInvest;
        }

        if (sortedDays.isEmpty) {
          return const Center(child: Text('Nenhuma movimentação este mês'));
        }

        final minDay = sortedDays.first.toDouble();
        final maxDay = sortedDays.last.toDouble();
        final maxVal = [cumIncome, cumExpense, cumInvest].fold<double>(0, (m, v) => v > m ? v : m);

        List<FlSpot> makeSpots(Map<int, double> data) {
          return sortedDays.map((d) => FlSpot(d.toDouble(), data[d] ?? 0)).toList();
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Evolução Mensal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              // Summary row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _EvolutionSummaryItem(label: 'Receitas', value: cumIncome, color: AppColors.income),
                  _EvolutionSummaryItem(label: 'Despesas', value: cumExpense, color: AppColors.expense),
                  _EvolutionSummaryItem(label: 'Invest.', value: cumInvest, color: AppColors.investment),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: minDay,
                    maxX: maxDay,
                    minY: 0,
                    maxY: maxVal * 1.15,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipColor: (touchedSpot) => isDark ? AppColors.cardDark : AppColors.cardLight,
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            String label;
                            switch (spot.barIndex) {
                              case 0: label = 'Receitas'; break;
                              case 1: label = 'Despesas'; break;
                              case 2: label = 'Invest.'; break;
                              default: label = '';
                            }
                            return LineTooltipItem(
                              '$label\n${CurrencyFormatter.formatCompact(spot.y)}',
                              TextStyle(color: spot.bar.color, fontSize: 11, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt();
                            // Show every 5th day or first/last
                            if (day == sortedDays.first || day == sortedDays.last || day % 5 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: maxVal > 0 ? maxVal / 4 : 1,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              CurrencyFormatter.formatCompact(value).replaceAll('R\$ ', ''),
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Income line
                      LineChartBarData(
                        spots: makeSpots(incomeByDay),
                        isCurved: true,
                        color: AppColors.income,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.income,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.income.withValues(alpha: 0.08),
                        ),
                      ),
                      // Expense line
                      LineChartBarData(
                        spots: makeSpots(expenseByDay),
                        isCurved: true,
                        color: AppColors.expense,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.expense,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.expense.withValues(alpha: 0.08),
                        ),
                      ),
                      // Investment line
                      if (cumInvest > 0)
                        LineChartBarData(
                          spots: makeSpots(investByDay),
                          isCurved: true,
                          color: AppColors.investment,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                              radius: 3,
                              color: AppColors.investment,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.investment.withValues(alpha: 0.08),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ChartLegend(),
            ],
          ),
        );
      },
    );
  }
}

class _EvolutionSummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _EvolutionSummaryItem({required this.label, required this.value, required this.color});

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

class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppColors.income, label: 'Receitas'),
        const SizedBox(width: 16),
        _LegendItem(color: AppColors.expense, label: 'Despesas'),
        const SizedBox(width: 16),
        _LegendItem(color: AppColors.investment, label: 'Investimentos'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _PremiumLockOverlay extends StatelessWidget {
  final String title;
  final String description;

  const _PremiumLockOverlay({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/paywall'),
              icon: const Icon(Icons.star_rounded, color: Colors.amber),
              label: const Text(
                'Desbloquear Relatório Premium',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

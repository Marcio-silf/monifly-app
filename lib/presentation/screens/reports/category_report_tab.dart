import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/spending_plan.dart';
import '../../../data/providers/spending_plan_provider.dart';

class CategoryReportTab extends ConsumerWidget {
  const CategoryReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(monthlyReportProvider);

    if (report == null || report.plannedExpenses == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_note_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Nenhum planejamento encontrado para este mês.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Crie um planejamento para ver a comparação.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/spending-plan'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Criar Planejamento'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Summary
              _ExecutiveSummary(report: report),
              const SizedBox(height: 20),

              // 2. Donut Chart
              _DonutChartCard(report: report),
              const SizedBox(height: 20),

              // 3. Category Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionTitle(title: 'Detalhamento por Categoria'),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                    tooltip: 'Modificar Planejamento',
                    onPressed: () => Navigator.pushNamed(context, '/spending-plan'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _TableHeader(),
              const Divider(height: 1),
              ...report.categories.map((a) => _CategoryRow(analysis: a)),
              
              // Totals row
              _TotalsRow(report: report),
              const SizedBox(height: 20),

              // 4. Performance Summary
              _PerformanceSummary(report: report),
              const SizedBox(height: 20),

              // 5. Top deviations
              _TopDeviations(report: report),
              const SizedBox(height: 20),

              // 6. Smart Recommendations
              _Recommendations(report: report),
              const SizedBox(height: 100),
            ],
          ),
        ),
        // Floating update button for visibility
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/spending-plan'),
            icon: const Icon(Icons.edit_document, color: Colors.white),
            label: const Text('Ajustar Plano', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primary,
            shape: const StadiumBorder(),
          ),
        ),
      ],
    );
  }
}

// ─── Executive Summary ──────────────────────────────────────────────────────────

class _ExecutiveSummary extends StatelessWidget {
  final MonthlyReport report;
  const _ExecutiveSummary({required this.report});

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text('RESUMO DO MÊS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryItem(
                label: 'Receita Prevista',
                value: report.plannedIncome,
                color: Colors.white,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryItem(
                label: 'Receita Real',
                value: report.actualIncome,
                color: Colors.white,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryItem(
                label: 'Diferença',
                value: report.incomeVariance,
                color: report.incomeVariance >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                showSign: true,
              )),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            children: [
              Expanded(child: _SummaryItem(
                label: 'Despesas Prev.',
                value: report.plannedExpenses,
                color: Colors.white,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryItem(
                label: 'Despesas Reais',
                value: report.actualExpenses,
                color: Colors.white,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryItem(
                label: 'Diferença',
                value: report.expenseVariance,
                color: report.expenseVariance <= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                showSign: true,
              )),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            children: [
              Expanded(child: _SummaryItem(
                label: 'Saldo Previsto',
                value: report.plannedSavings,
                color: Colors.white,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryItem(
                label: 'Saldo Real',
                value: report.actualSavings,
                color: Colors.white,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryItem(
                label: report.savingsVariance >= 0 ? 'Economia +' : 'Excesso',
                value: report.savingsVariance,
                color: report.savingsVariance >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                showSign: true,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool showSign;
  const _SummaryItem({required this.label, required this.value, required this.color, this.showSign = false});

  @override
  Widget build(BuildContext context) {
    final prefix = showSign && value > 0 ? '+' : '';
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          '$prefix${CurrencyFormatter.formatCompact(value)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Donut Chart ────────────────────────────────────────────────────────────────

class _DonutChartCard extends StatelessWidget {
  final MonthlyReport report;
  const _DonutChartCard({required this.report});

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
    final totalActual = report.actualExpenses;
    final withActual = report.categories.where((a) => a.actual > 0).toList();
    
    // Sort descending to facilitate 80/20 grouping
    withActual.sort((a, b) => b.actual.compareTo(a.actual));

    List<Map<String, dynamic>> displayData = [];
    double cumulative = 0;
    double othersSum = 0;
    bool inOthers = false;

    for (final a in withActual) {
      if (!inOthers) {
        displayData.add({
          'label': _getCategoryLabel(a.category),
          'value': a.actual,
          'color': _chartColors[displayData.length % _chartColors.length],
        });
        cumulative += a.actual;
        
        // If we reached 80% and there are more items, group the rest
        if (cumulative >= totalActual * 0.8 && withActual.indexOf(a) < withActual.length - 1) {
          // Check if it's worth grouping (more than 1 item left or very small items)
          if (withActual.length - withActual.indexOf(a) > 1) {
            inOthers = true;
          }
        }
      } else {
        othersSum += a.actual;
      }
    }

    if (othersSum > 0) {
      displayData.add({
        'label': 'Outros',
        'value': othersSum,
        'color': Colors.grey[500]!,
        'isOthers': true,
      });
    }

    final sections = displayData.map((data) {
      final double val = data['value'] as double;
      final pct = totalActual > 0 ? (val / totalActual * 100) : 0.0;
      return PieChartSectionData(
        value: val,
        title: '${pct.toStringAsFixed(0)}%',
        color: data['color'] as Color,
        radius: 40,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('Distribuição de Gastos Reais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: sections.isEmpty
              ? const Center(child: Text('Sem gastos registrados'))
              : PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: displayData.map((data) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10, 
                    height: 10, 
                    decoration: BoxDecoration(
                      color: data['color'] as Color, 
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data['label'] as String, 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.formatCompact(data['value'] as double),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    final match = AppConstants.expenseCategories.where((c) => c['key'] == category);
    if (match.isNotEmpty) return match.first['label'] as String;
    return category;
  }
}

// ─── Table Components ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey);
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('CATEGORIA', style: style)),
          Expanded(flex: 3, child: Text('PREVISTO', textAlign: TextAlign.right, style: style)),
          Expanded(flex: 3, child: Text('REAL', textAlign: TextAlign.right, style: style)),
          Expanded(flex: 3, child: Text('DIF.', textAlign: TextAlign.right, style: style)),
          SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryAnalysis analysis;
  const _CategoryRow({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final diff = analysis.planned - analysis.actual;
    final diffColor = diff >= 0 ? AppColors.income : AppColors.expense;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget statusIcon;
    if (analysis.isOverBudget) {
      statusIcon = const Icon(Icons.warning_rounded, color: AppColors.expense, size: 16);
    } else if (analysis.isUnderBudget) {
      statusIcon = const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 16);
    } else {
      statusIcon = const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16);
    }

    final catLabel = _getCategoryLabel(analysis.category);
    final catIcon = _getCategoryIcon(analysis.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withValues(alpha: 0.5) : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(catIcon, style: const TextStyle(fontSize: 14))),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(catLabel, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimaryLight), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              Expanded(flex: 3, child: Text(CurrencyFormatter.formatCompact(analysis.planned), textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87))),
              Expanded(flex: 3, child: Text(CurrencyFormatter.formatCompact(analysis.actual), textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
              Expanded(
                flex: 3,
                child: Text(
                  '${diff >= 0 ? '-' : '+'}${CurrencyFormatter.formatCompact(diff.abs())}',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 20, child: Align(alignment: Alignment.centerRight, child: statusIcon)),
            ],
          ),
          if (analysis.planned > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (analysis.actual / analysis.planned).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(analysis.isOverBudget ? AppColors.expense : AppColors.primary),
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    final match = AppConstants.expenseCategories.where((c) => c['key'] == category);
    if (match.isNotEmpty) return match.first['label'] as String;
    return category;
  }

  String _getCategoryIcon(String category) {
    final match = AppConstants.expenseCategories.where((c) => c['key'] == category);
    if (match.isNotEmpty) return match.first['icon'] as String;
    return '📦';
  }
}

class _TotalsRow extends StatelessWidget {
  final MonthlyReport report;
  const _TotalsRow({required this.report});

  @override
  Widget build(BuildContext context) {
    final diff = report.plannedExpenses - report.actualExpenses;
    final diffColor = diff >= 0 ? AppColors.income : AppColors.expense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 3, child: Text(CurrencyFormatter.formatCompact(report.plannedExpenses), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 3, child: Text(CurrencyFormatter.formatCompact(report.actualExpenses), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
            flex: 3,
            child: Text(
              '${diff >= 0 ? '-' : '+'}${CurrencyFormatter.formatCompact(diff.abs())}',
              textAlign: TextAlign.right,
              style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

// ─── Performance Summary ────────────────────────────────────────────────────────

class _PerformanceSummary extends StatelessWidget {
  final MonthlyReport report;
  const _PerformanceSummary({required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Resumo de Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          _PerformanceRow(
            icon: '✅',
            label: 'Dentro do orçamento',
            count: report.categoriesWithinBudget,
            color: AppColors.income,
          ),
          const SizedBox(height: 8),
          _PerformanceRow(
            icon: '⚠️',
            label: 'Acima do orçamento',
            count: report.categoriesOverBudget,
            color: AppColors.expense,
          ),
          const SizedBox(height: 8),
          _PerformanceRow(
            icon: '🟢',
            label: 'Abaixo do orçamento',
            count: report.categoriesUnderBudget,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String icon;
  final String label;
  final int count;
  final Color color;
  const _PerformanceRow({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Top Deviations ─────────────────────────────────────────────────────────────

class _TopDeviations extends StatelessWidget {
  final MonthlyReport report;
  const _TopDeviations({required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Top 3 over budget
    final overBudget = report.categories.where((c) => c.isOverBudget).toList()
      ..sort((a, b) => b.difference.compareTo(a.difference));
    final topOver = overBudget.take(3).toList();

    // Top 3 economies (under budget)
    final underBudget = report.categories.where((c) => c.isUnderBudget).toList()
      ..sort((a, b) => a.difference.compareTo(b.difference));
    final topUnder = underBudget.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topOver.isNotEmpty) ...[
            const Text('🔴 Maiores Excessos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...topOver.map((c) => _DeviationItem(
              category: _getCategoryLabel(c.category),
              value: c.difference,
              percentDiff: c.percentageDiff,
              isOver: true,
            )),
            const SizedBox(height: 16),
          ],
          if (topUnder.isNotEmpty) ...[
            const Text('🟢 Maiores Economias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...topUnder.map((c) => _DeviationItem(
              category: _getCategoryLabel(c.category),
              value: c.difference.abs(),
              percentDiff: c.percentageDiff.abs(),
              isOver: false,
            )),
          ],
          if (topOver.isEmpty && topUnder.isEmpty)
            const Center(child: Text('Sem desvios significativos')),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    final match = AppConstants.expenseCategories.where((c) => c['key'] == category);
    if (match.isNotEmpty) return match.first['label'] as String;
    return category;
  }
}

class _DeviationItem extends StatelessWidget {
  final String category;
  final double value;
  final double percentDiff;
  final bool isOver;
  const _DeviationItem({required this.category, required this.value, required this.percentDiff, required this.isOver});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isOver ? AppColors.expense : AppColors.income;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('• ', style: TextStyle(color: color, fontSize: 16)),
          Expanded(child: Text(category, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight))),
          Text(
            '${isOver ? '+' : '-'}${CurrencyFormatter.formatCompact(value)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            '(${(percentDiff * 100).toStringAsFixed(0)}%)',
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Smart Recommendations ──────────────────────────────────────────────────────

class _Recommendations extends StatelessWidget {
  final MonthlyReport report;
  const _Recommendations({required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tips = _generateTips();

    if (tips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 Recomendações para o Próximo Mês', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip['icon'] as String, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text(tip['text'] as String, style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<Map<String, String>> _generateTips() {
    final tips = <Map<String, String>>[];

    // Over budget categories
    final overBudget = report.categories.where((c) => c.isOverBudget).toList()
      ..sort((a, b) => b.difference.compareTo(a.difference));

    for (var c in overBudget.take(3)) {
      final label = _getCategoryLabel(c.category);
      final pct = (c.percentageDiff * 100).toStringAsFixed(0);
      tips.add({
        'icon': '⚠️',
        'text': 'Reveja os gastos com "$label" — ${pct}% acima do planejado. Considere aumentar o orçamento para ${CurrencyFormatter.format(c.actual)}.',
      });
    }

    // Under budget categories (praise)
    final underBudget = report.categories.where((c) => c.isUnderBudget).toList();
    if (underBudget.isNotEmpty) {
      final names = underBudget.take(3).map((c) => _getCategoryLabel(c.category)).join(', ');
      tips.add({
        'icon': '🎉',
        'text': 'Parabéns! Você economizou em: $names.',
      });
    }

    // Overall savings tip
    if (report.actualSavings > report.plannedSavings) {
      tips.add({
        'icon': '💰',
        'text': 'Você poupou ${CurrencyFormatter.format(report.savingsVariance)} a mais do que o planejado!',
      });
    } else if (report.actualSavings < report.plannedSavings) {
      tips.add({
        'icon': '📉',
        'text': 'O saldo ficou ${CurrencyFormatter.format(report.savingsVariance.abs())} abaixo do previsto. Tente reduzir gastos supérfluos.',
      });
    }

    return tips;
  }

  String _getCategoryLabel(String category) {
    final match = AppConstants.expenseCategories.where((c) => c['key'] == category);
    if (match.isNotEmpty) return match.first['label'] as String;
    return category;
  }
}

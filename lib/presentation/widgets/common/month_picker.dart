import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class MonthPicker extends StatelessWidget {
  final int selectedMonth;
  final ValueChanged<int> onChanged;
  final bool isCompact;

  const MonthPicker({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final year = selectedMonth ~/ 100;
    final month = selectedMonth % 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(year, month),
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          helpText: 'Selecionar Mês',
        );
        if (picked != null) {
          onChanged(picked.year * 100 + picked.month);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 0 : 12,
          vertical: isCompact ? 4 : 8,
        ),
        decoration: isCompact 
          ? null 
          : BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompact) ...[
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              _getMonthName(month, year, full: isCompact),
              style: TextStyle(
                color: isCompact 
                  ? (isDark ? Colors.white70 : Colors.grey[600])
                  : AppColors.primary,
                fontWeight: isCompact ? FontWeight.w400 : FontWeight.w600,
                fontSize: isCompact ? 14 : 13,
              ),
            ),
            if (isCompact) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month, int year, {bool full = false}) {
    if (full) {
      const names = [
        '',
        'Janeiro',
        'Fevereiro',
        'Março',
        'Abril',
        'Maio',
        'Junho',
        'Julho',
        'Agosto',
        'Setembro',
        'Outubro',
        'Novembro',
        'Dezembro'
      ];
      return '${names[month]} $year';
    }
    const names = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    return '${names[month]} $year';
  }

}

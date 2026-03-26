import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static DateFormat get _fullDate => DateFormat('dd/MM/yyyy', 'pt_BR');
  static DateFormat get _shortDate => DateFormat('dd/MM', 'pt_BR');
  static DateFormat get _monthYear => DateFormat('MMMM yyyy', 'pt_BR');
  static DateFormat get _dayMonth => DateFormat('dd MMM', 'pt_BR');
  static DateFormat get _time => DateFormat('HH:mm', 'pt_BR');
  static DateFormat get _fullDateTime => DateFormat(
        'dd/MM/yyyy HH:mm',
        'pt_BR',
      );

  static String formatFull(DateTime date) => _fullDate.format(date);
  static String formatShort(DateTime date) => _shortDate.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);
  static String formatTime(DateTime date) => _time.format(date);
  static String formatFullDateTime(DateTime date) => _fullDateTime.format(date);

  /// Friendly relative date label in PT-BR
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    if (diff <= 7) return 'Esta semana';
    if (d.month == today.month && d.year == today.year) return 'Este mês';
    return formatMonthYear(date);
  }

  /// Days until a future date
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return d.difference(today).inDays;
  }

  /// Days since a past date
  static int daysSince(DateTime date) {
    final now = DateTime.now();
    return now.difference(date).inDays;
  }

  /// Format month as YYYYMM integer
  static int toMonthInt(DateTime date) => date.year * 100 + date.month;

  /// Parse YYYYMM to DateTime
  static DateTime fromMonthInt(int monthInt) {
    final year = monthInt ~/ 100;
    final month = monthInt % 100;
    return DateTime(year, month);
  }

  /// Due date label: "Hoje", "Amanhã", "X dias"
  static String formatDueDate(DateTime date) {
    final days = daysUntil(date);
    if (days < 0) return 'Vencido há ${(-days)} dia(s)';
    if (days == 0) return 'Vence hoje';
    if (days == 1) return 'Vence amanhã';
    return 'Vence em $days dias';
  }
}


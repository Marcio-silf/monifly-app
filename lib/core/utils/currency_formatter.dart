import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _brlFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'pt_BR',
  );

  /// Formats a double to BRL currency string: R$ 1.234,56
  static String format(double value) => _brlFormat.format(value);

  /// Formats without symbol: 1.234,56
  static String formatNoSymbol(double value) => NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  ).format(value).trim();

  /// Compact format for large numbers: R$ 1,2M
  static String formatCompact(double value) =>
      'R\$ ${_compactFormat.format(value)}';

  /// Parse a BRL string to double
  static double parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[R\$\s]'), '').trim();
    // Brazilian format: 1.234,56 → 1234.56
    final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  /// Format number as percentage
  static String formatPercent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }
}


import 'package:flutter/material.dart';
import 'package:monifly/core/constants/colors.dart';
import 'package:monifly/core/utils/currency_formatter.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool isVisible;
  final bool showSign;
  final Color? color;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.isVisible = true,
    this.showSign = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return Text(
        'R\$ ••••••',
        style: style ??
            Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: color, letterSpacing: 2),
      );
    }

    final formattedAmount = CurrencyFormatter.format(amount.abs());
    String text = formattedAmount;
    if (showSign && amount > 0) text = '+$formattedAmount';
    if (showSign && amount < 0) text = '-$formattedAmount';

    Color? resolvedColor = color;
    if (showSign && color == null) {
      resolvedColor = amount >= 0 ? AppColors.income : AppColors.expense;
    }

    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.titleLarge)?.copyWith(
        color: resolvedColor,
      ),
    );
  }
}


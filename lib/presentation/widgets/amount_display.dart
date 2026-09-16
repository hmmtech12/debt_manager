import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;

  const AmountDisplay({
    super.key,
    required this.amount,
    required this.currency,
    this.color,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      CurrencyFormatter.format(amount, currency),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/payment.dart';

class PaymentHistoryItem extends StatelessWidget {
  final Payment payment;
  final String currency;

  const PaymentHistoryItem({super.key, required this.payment, required this.currency});

  String _methodLabel() {
    switch (payment.method.name) {
      case 'bankTransfer':
        return 'Bank Transfer';
      case 'other':
        return 'Other';
      default:
        return 'Cash';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.paid.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.paid, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.format(payment.amount, currency),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${DateFormatter.medium(payment.paymentDate)} · ${_methodLabel()}'
                  '${payment.notes != null && payment.notes!.isNotEmpty ? ' · ${payment.notes}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

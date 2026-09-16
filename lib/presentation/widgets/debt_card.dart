import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/enums.dart';
import 'status_badge.dart';

class DebtCard extends StatelessWidget {
  final DebtWithDetails item;
  final VoidCallback onTap;

  const DebtCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLent = item.debt.type == DebtType.lent;
    final accent = isLent ? AppColors.owedToMe : AppColors.iOwe;
    final days = DateFormatter.daysUntil(item.debt.dueDate);

    String dueLabel;
    if (item.status == DebtStatus.paid) {
      dueLabel = DateFormatter.medium(item.debt.dueDate);
    } else if (days < 0) {
      dueLabel = l10n.overdueBy.replaceAll('{n}', '${-days}');
    } else if (days == 0) {
      dueLabel = l10n.dueToday;
    } else if (days == 1) {
      dueLabel = l10n.dueTomorrow;
    } else {
      dueLabel = l10n.dueInDays.replaceAll('{n}', '$days');
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  item.person.name.isNotEmpty ? item.person.name[0].toUpperCase() : '?',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.person.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.format(item.remainingAmount, item.debt.currency)} ${l10n.remaining}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(dueLabel, style: theme.textTheme.bodySmall?.copyWith(
                      color: item.status == DebtStatus.overdue ? AppColors.overdue : null,
                      fontWeight: item.status == DebtStatus.overdue ? FontWeight.w600 : null,
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: item.status),
            ],
          ),
        ),
      ),
    );
  }
}

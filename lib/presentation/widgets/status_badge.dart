import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/entities/enums.dart';

class StatusBadge extends StatelessWidget {
  final DebtStatus status;
  const StatusBadge({super.key, required this.status});

  IconData get _icon {
    switch (status) {
      case DebtStatus.paid:
        return Icons.check_circle_rounded;
      case DebtStatus.partiallyPaid:
        return Icons.donut_small_rounded;
      case DebtStatus.overdue:
        return Icons.error_rounded;
      case DebtStatus.outstanding:
        return Icons.schedule_rounded;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (status) {
      case DebtStatus.paid:
        return l10n.statusPaid;
      case DebtStatus.partiallyPaid:
        return l10n.statusPartiallyPaid;
      case DebtStatus.overdue:
        return l10n.statusOverdue;
      case DebtStatus.outstanding:
        return l10n.statusOutstanding;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = AppColors.statusColor(status.dbValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _label(l10n),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

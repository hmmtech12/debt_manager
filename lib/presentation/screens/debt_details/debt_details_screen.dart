import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/debt_providers.dart';
import '../../widgets/payment_history_item.dart';
import '../../widgets/status_badge.dart';

class DebtDetailsScreen extends ConsumerWidget {
  final String debtId;
  const DebtDetailsScreen({super.key, required this.debtId});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.areYouSure),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.overdue),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(debtsProvider.notifier).deleteDebt(debtId);
      if (context.mounted) context.pop();
    }
  }

  Future<void> _confirmMarkPaid(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.markAsPaid),
        content: Text(l10n.areYouSure),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(debtsProvider.notifier).markPaid(debtId);
    }
  }

  Future<void> _openReminderSheet(BuildContext context, WidgetRef ref, DebtWithDetails item, AppLocalizations l10n) async {
    final offset = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.addReminder, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final entry in AppConstants.reminderOffsets.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(_offsetLabel(entry.key, entry.value)),
                    onTap: () => Navigator.pop(ctx, entry.value),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (offset == null || !context.mounted) return;

    await ref.read(debtsProvider.notifier).addReminder(
          debtId: item.debt.id,
          dueDate: item.debt.dueDate,
          offsetDays: offset,
          personName: item.person.name,
          remainingAmount: item.remainingAmount,
          currency: item.debt.currency,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb
              ? 'Reminder saved (browser notifications aren\'t supported yet)'
              : l10n.addReminder),
        ),
      );
    }
  }

  String _offsetLabel(String key, int days) {
    switch (key) {
      case 'ON_DUE_DATE':
        return 'On the due date';
      case 'ONE_DAY_BEFORE':
        return '1 day before';
      case 'THREE_DAYS_BEFORE':
        return '3 days before';
      case 'SEVEN_DAYS_BEFORE':
        return '7 days before';
      default:
        return '$days days before';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              final debts = ref.read(debtsProvider).valueOrNull ?? [];
              DebtWithDetails? found;
              for (final d in debts) {
                if (d.debt.id == debtId) found = d;
              }
              if (found != null) {
                try {
                  final result = await ExportService.exportDebtPdf(found);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result), duration: const Duration(seconds: 6)),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSomethingWentWrong)));
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, ref, l10n),
          ),
        ],
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorSomethingWentWrong)),
        data: (debts) {
          DebtWithDetails? found;
          for (final d in debts) {
            if (d.debt.id == debtId) found = d;
          }
          if (found == null) {
            return Center(child: Text(l10n.errorSomethingWentWrong));
          }
          // Assigning to a `final` local (rather than using the nullable
          // `found` directly) is what makes Dart retain the non-null type
          // inside closures below, like the reminder button's onPressed.
          final item = found;

          final isLent = item.debt.type == DebtType.lent;
          final accent = isLent ? AppColors.owedToMe : AppColors.iOwe;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Text(
                      item.person.name.isNotEmpty ? item.person.name[0].toUpperCase() : '?',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.person.name, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          isLent ? l10n.iLentMoney : l10n.iBorrowedMoney,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatColumn(
                              label: l10n.originalAmount,
                              value: CurrencyFormatter.format(item.debt.originalAmount, item.debt.currency),
                            ),
                          ),
                          Expanded(
                            child: _StatColumn(
                              label: l10n.paid,
                              value: CurrencyFormatter.format(item.totalPaid, item.debt.currency),
                              color: AppColors.paid,
                            ),
                          ),
                          Expanded(
                            child: _StatColumn(
                              label: l10n.remaining,
                              value: CurrencyFormatter.format(item.remainingAmount, item.debt.currency),
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: item.progressFraction,
                          minHeight: 10,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${(item.progressFraction * 100).toStringAsFixed(0)}% paid',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(label: l10n.createdDate, value: DateFormatter.medium(item.debt.debtDate)),
                      const Divider(height: 20),
                      _DetailRow(label: l10n.dueDate, value: DateFormatter.medium(item.debt.dueDate)),
                      const Divider(height: 20),
                      _DetailRow(label: l10n.currency, value: item.debt.currency),
                      if (item.debt.description != null && item.debt.description!.trim().isNotEmpty) ...[
                        const Divider(height: 20),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(item.debt.description!, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (item.status != DebtStatus.paid)
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_card_rounded, size: 18),
                        label: Text(l10n.recordPayment),
                        onPressed: () => context.push('/debt/$debtId/record-payment'),
                      ),
                    ),
                  if (item.status != DebtStatus.paid) const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: Text(l10n.addReminder),
                      onPressed: () => _openReminderSheet(context, ref, item, l10n),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (item.status != DebtStatus.paid)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _confirmMarkPaid(context, ref, l10n),
                    child: Text(l10n.markAsPaid),
                  ),
                ),
              const SizedBox(height: 20),
              Text(l10n.paymentHistory, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              if (item.payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.noPaymentsYet, style: theme.textTheme.bodyMedium),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        for (int i = 0; i < item.payments.length; i++) ...[
                          PaymentHistoryItem(payment: item.payments[i], currency: item.debt.currency),
                          if (i != item.payments.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatColumn({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        FittedBox(
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

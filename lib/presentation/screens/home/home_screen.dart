import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/debt_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final debtsAsync = ref.watch(debtsProvider);
    final summary = ref.watch(debtSummaryProvider);
    final currency = ref.watch(defaultCurrencyProvider);
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      body: SafeArea(
        child: debtsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorSomethingWentWrong)),
          data: (debts) {
            if (debts.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => ref.read(debtsProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.only(top: 80),
                  children: [
                    EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: l10n.noDebtsYet,
                      subtitle: l10n.noDebtsSubtitle,
                      buttonLabel: l10n.addFirstDebt,
                      onButtonPressed: () => context.push('/add-debt'),
                    ),
                  ],
                ),
              );
            }

            final upcoming = debts
                .where((d) => d.status != DebtStatus.paid)
                .toList()
              ..sort((a, b) => a.debt.dueDate.compareTo(b.debt.dueDate));
            final upcomingTop = upcoming.take(4).toList();

            final recent = [...debts]..sort((a, b) => b.debt.updatedAt.compareTo(a.debt.updatedAt));
            final recentActivity = recent.take(4).toList();

            return RefreshIndicator(
              onRefresh: () => ref.read(debtsProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isNotEmpty
                                  ? '${l10n.greetingHi}, $userName 👋'
                                  : AppConstants.appName,
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormatter.medium(DateTime.now()),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.notifications_none_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.cardTheme.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          label: l10n.moneyOwedToMe,
                          amountText: CurrencyFormatter.format(summary.totalOwedToMe, currency),
                          accentColor: AppColors.owedToMe,
                          icon: Icons.call_received_rounded,
                          onTap: () => context.push('/debts?tab=receive'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          label: l10n.moneyIOwe,
                          amountText: CurrencyFormatter.format(summary.totalIOwe, currency),
                          accentColor: AppColors.iOwe,
                          icon: Icons.call_made_rounded,
                          onTap: () => context.push('/debts?tab=pay'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SummaryCard(
                    label: l10n.netDebtPosition,
                    amountText: CurrencyFormatter.format(summary.netPosition, currency),
                    accentColor: AppColors.neutral,
                    icon: Icons.balance_rounded,
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: l10n.upcomingDueDates,
                    onSeeAll: () => context.push('/debts'),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 10),
                  if (upcomingTop.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('—', style: theme.textTheme.bodyMedium),
                    )
                  else
                    ...upcomingTop.map((d) => _UpcomingTile(item: d)),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: l10n.recentActivity,
                    onSeeAll: () => context.push('/debts'),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 10),
                  ...recentActivity.map((d) => _ActivityTile(item: d)),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-debt'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addDebt),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  final AppLocalizations l10n;
  const _SectionHeader({required this.title, required this.onSeeAll, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: onSeeAll, child: Text(l10n.seeAll)),
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final DebtWithDetails item;
  const _UpcomingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final days = DateFormatter.daysUntil(item.debt.dueDate);
    final isOverdue = days < 0;

    String dueText;
    if (isOverdue) {
      dueText = l10n.overdueBy.replaceAll('{n}', '${-days}');
    } else if (days == 0) {
      dueText = l10n.dueToday;
    } else if (days == 1) {
      dueText = l10n.dueTomorrow;
    } else {
      dueText = l10n.dueInDays.replaceAll('{n}', '$days');
    }

    final accent = isOverdue ? AppColors.overdue : AppColors.neutral;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/debt/${item.debt.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.person.name, style: theme.textTheme.titleMedium),
                    Text(dueText, style: theme.textTheme.bodySmall?.copyWith(color: accent)),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(item.remainingAmount, item.debt.currency),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final DebtWithDetails item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLent = item.debt.type == DebtType.lent;
    final hasPayments = item.payments.isNotEmpty;
    final lastPayment = hasPayments ? item.payments.first : null;

    final sign = isLent ? '+' : '-';
    final color = isLent ? AppColors.owedToMe : AppColors.iOwe;
    final label = lastPayment != null
        ? '${lastPayment.amount == item.debt.originalAmount ? 'Repayment' : 'Partial repayment'} '
            '${isLent ? 'from' : 'to'} ${item.person.name}'
        : 'New debt ${isLent ? 'to' : 'from'} ${item.person.name}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(isLent ? Icons.south_west_rounded : Icons.north_east_rounded, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '$sign ${CurrencyFormatter.format(lastPayment?.amount ?? item.debt.originalAmount, item.debt.currency)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

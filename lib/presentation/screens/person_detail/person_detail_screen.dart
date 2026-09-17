import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/debt_providers.dart';
import '../../widgets/amount_display.dart';
import '../../widgets/debt_card.dart';
import '../../widgets/empty_state.dart';

/// Consolidated view for one person: every debt they're part of (lent
/// AND borrowed) in one place, with running totals, instead of hunting
/// through the main Debts list for each separate transaction with them.
class PersonDetailScreen extends ConsumerWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final debtsAsync = ref.watch(debtsProvider);

    return debtsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorSomethingWentWrong)),
      ),
      data: (allDebts) {
        final personDebts = allDebts.where((d) => d.person.id == personId).toList()
          ..sort((a, b) => b.debt.updatedAt.compareTo(a.debt.updatedAt));

        if (personDebts.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              icon: Icons.person_off_outlined,
              title: l10n.noDebtsYet,
              subtitle: l10n.noDebtsSubtitle,
            ),
          );
        }

        return _PersonDetailContent(personDebts: personDebts);
      },
    );
  }
}

class _PersonDetailContent extends StatelessWidget {
  final List<DebtWithDetails> personDebts;
  const _PersonDetailContent({required this.personDebts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final person = personDebts.first.person;
    // Assumes one currency per person, which holds for typical use; if
    // someone has debts in multiple currencies, totals below mix
    // currencies numerically — a known simplification.
    final currency = personDebts.first.debt.currency;

    double totalLentRemaining = 0;
    double totalBorrowedRemaining = 0;
    for (final d in personDebts) {
      if (d.debt.type == DebtType.lent) {
        totalLentRemaining += d.remainingAmount;
      } else {
        totalBorrowedRemaining += d.remainingAmount;
      }
    }
    final net = totalLentRemaining - totalBorrowedRemaining;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(person.name, style: theme.textTheme.headlineMedium),
                    if (person.phone != null && person.phone!.isNotEmpty)
                      Text(person.phone!, style: theme.textTheme.bodyMedium),
                    if (person.email != null && person.email!.isNotEmpty)
                      Text(person.email!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: _TotalCard(
                        label: l10n.moneyOwedToMe,
                        amount: totalLentRemaining,
                        currency: currency,
                        color: AppColors.owedToMe,
                        icon: Icons.call_received_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TotalCard(
                        label: l10n.moneyIOwe,
                        amount: totalBorrowedRemaining,
                        currency: currency,
                        color: AppColors.iOwe,
                        icon: Icons.call_made_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.netDebtPosition, style: theme.textTheme.titleMedium),
                      AmountDisplay(
                        amount: net.abs(),
                        currency: currency,
                        fontSize: 20,
                        color: net >= 0 ? AppColors.owedToMe : AppColors.iOwe,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${personDebts.length} transaction${personDebts.length == 1 ? '' : 's'}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                for (final d in personDebts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DebtCard(item: d, onTap: () => context.push('/debt/${d.debt.id}')),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;

  const _TotalCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              CurrencyFormatter.format(amount, currency),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
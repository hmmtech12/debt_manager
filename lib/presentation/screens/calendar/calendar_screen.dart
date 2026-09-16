import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/debt_providers.dart';
import '../../widgets/empty_state.dart';

/// Simple, dependency-free month calendar (no external calendar package)
/// so the project has fewer moving parts to keep compiling. Color-codes
/// each day per the spec: green = paid, orange = upcoming, red = overdue,
/// blue = future with no near-term activity.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  Map<DateTime, List<DebtWithDetails>> _groupByDay(List<DebtWithDetails> debts) {
    final map = <DateTime, List<DebtWithDetails>>{};
    for (final d in debts) {
      final due = d.debt.dueDate;
      final key = DateTime(due.year, due.month, due.day);
      map.putIfAbsent(key, () => []).add(d);
    }
    return map;
  }

  Color _dayColor(List<DebtWithDetails> items) {
    if (items.every((d) => d.status == DebtStatus.paid)) return AppColors.paid;
    if (items.any((d) => d.status == DebtStatus.overdue)) return AppColors.overdue;
    final soon = items.any((d) {
      final days = d.debt.dueDate.difference(DateTime.now()).inDays;
      return days <= 3 && d.status != DebtStatus.paid;
    });
    if (soon) return AppColors.partiallyPaid; // orange = upcoming
    return AppColors.neutral; // blue = future
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCalendar)),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorSomethingWentWrong)),
        data: (debts) {
          final grouped = _groupByDay(debts);
          final firstOfMonth = DateTime(_month.year, _month.month, 1);
          final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
          final leadingBlanks = firstOfMonth.weekday % 7; // Sun=0 offset

          final selectedItems = _selectedDay != null ? (grouped[_selectedDay] ?? []) : <DebtWithDetails>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  ),
                  Text(
                    '${_monthName(_month.month)} ${_month.year}',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox.shrink();
                  final day = index - leadingBlanks + 1;
                  final date = DateTime(_month.year, _month.month, day);
                  final items = grouped[date] ?? [];
                  final isSelected = _selectedDay == date;
                  final isToday = DateUtils.isSameDay(date, DateTime.now());

                  return Padding(
                    padding: const EdgeInsets.all(3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: items.isEmpty ? null : () => setState(() => _selectedDay = date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.16) : null,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday ? Border.all(color: AppColors.primary) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$day', style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 2),
                            if (items.isNotEmpty)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: _dayColor(items), shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _LegendDot(color: AppColors.paid, label: l10n.statusPaid),
                  _LegendDot(color: AppColors.partiallyPaid, label: 'Upcoming'),
                  _LegendDot(color: AppColors.overdue, label: l10n.statusOverdue),
                  _LegendDot(color: AppColors.neutral, label: 'Future'),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedDay != null) ...[
                Text(
                  '${selectedItems.length} due',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (selectedItems.isEmpty)
                  const SizedBox.shrink()
                else
                  ...selectedItems.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => context.push('/debt/${item.debt.id}'),
                          title: Text(item.person.name),
                          subtitle: Text(item.debt.type == DebtType.lent ? l10n.iLentMoney : l10n.iBorrowedMoney),
                          trailing: Text(
                            CurrencyFormatter.format(item.remainingAmount, item.debt.currency),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      )),
              ] else if (grouped.isEmpty)
                EmptyState(
                  icon: Icons.event_available_outlined,
                  title: l10n.noDebtsYet,
                  subtitle: l10n.noDebtsSubtitle,
                )
              else
                Text('Tap a marked day to see what\'s due.', style: theme.textTheme.bodyMedium),
            ],
          );
        },
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

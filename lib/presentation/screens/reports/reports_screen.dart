import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/debt_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/summary_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final debtsAsync = ref.watch(debtsProvider);
    final summary = ref.watch(debtSummaryProvider);
    final currency = ref.watch(defaultCurrencyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navReports)),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorSomethingWentWrong)),
        data: (debts) {
          if (debts.isEmpty) {
            return EmptyState(
              icon: Icons.bar_chart_rounded,
              title: l10n.noDebtsYet,
              subtitle: l10n.noDebtsSubtitle,
            );
          }

          return MaxWidthBox(
            maxWidth: 760,
            child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 128, // fixed card height — avoids overflow regardless of card width
                ),
                children: [
                  SummaryCard(
                    label: l10n.totalLent,
                    amountText: CurrencyFormatter.format(summary.totalLent, currency),
                    accentColor: AppColors.owedToMe,
                    icon: Icons.call_received_rounded,
                  ),
                  SummaryCard(
                    label: l10n.totalBorrowed,
                    amountText: CurrencyFormatter.format(summary.totalBorrowed, currency),
                    accentColor: AppColors.iOwe,
                    icon: Icons.call_made_rounded,
                  ),
                  SummaryCard(
                    label: l10n.totalRepaid,
                    amountText: CurrencyFormatter.format(summary.totalRepaid, currency),
                    accentColor: AppColors.paid,
                    icon: Icons.task_alt_rounded,
                  ),
                  SummaryCard(
                    label: l10n.totalOutstanding,
                    amountText: CurrencyFormatter.format(summary.totalOutstanding, currency),
                    accentColor: AppColors.neutral,
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SummaryCard(
                label: l10n.overdueAmount,
                amountText: CurrencyFormatter.format(summary.overdueAmount, currency),
                accentColor: AppColors.overdue,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 28),
              Text('Money owed to me vs money I owe', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final label = value == 0 ? l10n.moneyOwedToMe : l10n.moneyIOwe;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(label, style: theme.textTheme.bodySmall),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [
                        BarChartRodData(
                          toY: summary.totalOwedToMe,
                          color: AppColors.owedToMe,
                          width: 36,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ]),
                      BarChartGroupData(x: 1, barRods: [
                        BarChartRodData(
                          toY: summary.totalIOwe,
                          color: AppColors.iOwe,
                          width: 36,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(l10n.debtStatusDistribution, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 34,
                          sections: [
                            if (summary.paidCount > 0)
                              PieChartSectionData(
                                value: summary.paidCount.toDouble(),
                                color: AppColors.paid,
                                title: '${summary.paidCount}',
                                radius: 46,
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            if (summary.partiallyPaidCount > 0)
                              PieChartSectionData(
                                value: summary.partiallyPaidCount.toDouble(),
                                color: AppColors.partiallyPaid,
                                title: '${summary.partiallyPaidCount}',
                                radius: 46,
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            if (summary.outstandingCount > 0)
                              PieChartSectionData(
                                value: summary.outstandingCount.toDouble(),
                                color: AppColors.neutral,
                                title: '${summary.outstandingCount}',
                                radius: 46,
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            if (summary.overdueCount > 0)
                              PieChartSectionData(
                                value: summary.overdueCount.toDouble(),
                                color: AppColors.overdue,
                                title: '${summary.overdueCount}',
                                radius: 46,
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendRow(color: AppColors.paid, label: l10n.statusPaid, count: summary.paidCount),
                          _LegendRow(color: AppColors.partiallyPaid, label: l10n.statusPartiallyPaid, count: summary.partiallyPaidCount),
                          _LegendRow(color: AppColors.neutral, label: l10n.statusOutstanding, count: summary.outstandingCount),
                          _LegendRow(color: AppColors.overdue, label: l10n.statusOverdue, count: summary.overdueCount),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _LegendRow({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$label ($count)', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

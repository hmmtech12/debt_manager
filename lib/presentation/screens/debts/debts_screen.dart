import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/debt_providers.dart';
import '../../widgets/debt_card.dart';
import '../../widgets/empty_state.dart';

enum _SortOption { dueDate, amount, recent, name }

class DebtsScreen extends ConsumerStatefulWidget {
  final String initialTab; // 'receive' | 'pay'
  const DebtsScreen({super.key, this.initialTab = 'receive'});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SortOption _sort = _SortOption.dueDate;
  DebtStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab == 'pay' ? 1 : 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DebtWithDetails> _filterAndSort(List<DebtWithDetails> debts, DebtType type) {
    var filtered = debts.where((d) => d.debt.type == type).toList();

    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      filtered = filtered.where((d) => d.person.name.toLowerCase().contains(q)).toList();
    }
    if (_statusFilter != null) {
      filtered = filtered.where((d) => d.status == _statusFilter).toList();
    }

    switch (_sort) {
      case _SortOption.dueDate:
        filtered.sort((a, b) => a.debt.dueDate.compareTo(b.debt.dueDate));
        break;
      case _SortOption.amount:
        filtered.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
        break;
      case _SortOption.recent:
        filtered.sort((a, b) => b.debt.createdAt.compareTo(a.debt.createdAt));
        break;
      case _SortOption.name:
        filtered.sort((a, b) => a.person.name.compareTo(b.person.name));
        break;
    }
    return filtered;
  }

  Future<void> _openFilterSheet() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet(
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
                Text(l10n.filter, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    for (final s in DebtStatus.values)
                      ChoiceChip(
                        label: Text(_statusLabel(l10n, s)),
                        selected: _statusFilter == s,
                        onSelected: (_) => setState(() => _statusFilter = s),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(l10n.sortBy, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Due date'),
                      selected: _sort == _SortOption.dueDate,
                      onSelected: (_) => setState(() => _sort = _SortOption.dueDate),
                    ),
                    ChoiceChip(
                      label: const Text('Amount'),
                      selected: _sort == _SortOption.amount,
                      onSelected: (_) => setState(() => _sort = _SortOption.amount),
                    ),
                    ChoiceChip(
                      label: const Text('Recently added'),
                      selected: _sort == _SortOption.recent,
                      onSelected: (_) => setState(() => _sort = _SortOption.recent),
                    ),
                    ChoiceChip(
                      label: const Text('Name'),
                      selected: _sort == _SortOption.name,
                      onSelected: (_) => setState(() => _sort = _SortOption.name),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
    setState(() {});
  }

  String _statusLabel(AppLocalizations l10n, DebtStatus s) {
    switch (s) {
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
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navDebts),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l10n.toReceive), Tab(text: l10n.toPay)],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: debtsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorSomethingWentWrong)),
              data: (debts) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _DebtListView(items: _filterAndSort(debts, DebtType.lent), l10n: l10n),
                    _DebtListView(items: _filterAndSort(debts, DebtType.borrowed), l10n: l10n),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-debt'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _DebtListView extends StatelessWidget {
  final List<DebtWithDetails> items;
  final AppLocalizations l10n;
  const _DebtListView({required this.items, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: l10n.noDebtsYet,
        subtitle: l10n.noDebtsSubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        return DebtCard(item: item, onTap: () => context.push('/person/${item.person.id}'));
      },
    );
  }
}

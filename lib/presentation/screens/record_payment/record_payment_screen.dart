import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/debt_providers.dart';
import '../../widgets/primary_button.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  final String debtId;
  const RecordPaymentScreen({super.key, required this.debtId});

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(DebtWithDetails item) async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

    if (amount > item.remainingAmount + 0.0001) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.errorPaymentExceedsBalance),
          content: Text(
            '${l10n.remaining}: ${CurrencyFormatter.format(item.remainingAmount, item.debt.currency)}\n'
            '${l10n.paymentAmount}: ${CurrencyFormatter.format(amount, item.debt.currency)}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(debtsProvider.notifier).recordPayment(
            debtId: widget.debtId,
            amount: amount,
            paymentDate: _date,
            method: _method,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSomethingWentWrong)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordPayment)),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorSomethingWentWrong)),
        data: (debts) {
          DebtWithDetails? item;
          for (final d in debts) {
            if (d.debt.id == widget.debtId) item = d;
          }
          if (item == null) return Center(child: Text(l10n.errorSomethingWentWrong));

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _Row(label: l10n.originalDebt, value: CurrencyFormatter.format(item.debt.originalAmount, item.debt.currency)),
                        const SizedBox(height: 10),
                        _Row(label: l10n.alreadyPaid, value: CurrencyFormatter.format(item.totalPaid, item.debt.currency)),
                        const Divider(height: 24),
                        _Row(
                          label: l10n.remaining,
                          value: CurrencyFormatter.format(item.remainingAmount, item.debt.currency),
                          emphasized: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.paymentAmount,
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.errorEnterAmount;
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return l10n.errorAmountGreaterThanZero;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.date,
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                    ),
                    child: Text(DateFormatter.medium(_date)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(l10n.paymentMethod, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.cash),
                      selected: _method == PaymentMethod.cash,
                      onSelected: (_) => setState(() => _method = PaymentMethod.cash),
                    ),
                    ChoiceChip(
                      label: Text(l10n.bankTransfer),
                      selected: _method == PaymentMethod.bankTransfer,
                      onSelected: (_) => setState(() => _method = PaymentMethod.bankTransfer),
                    ),
                    ChoiceChip(
                      label: Text(l10n.other),
                      selected: _method == PaymentMethod.other,
                      onSelected: (_) => setState(() => _method = PaymentMethod.other),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.descriptionNotes, alignLabelWithHint: true),
                ),
                const SizedBox(height: 28),
                PrimaryButton(label: l10n.savePayment, onPressed: () => _save(item!), loading: _saving),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  const _Row({required this.label, required this.value, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: emphasized
              ? theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)
              : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

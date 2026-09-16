import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/contacts_support.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/debt_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/primary_button.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({super.key});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DebtType _type = DebtType.lent;
  String? _currency;
  DateTime _debtDate = DateTime.now();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDueDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? (_dueDate ?? DateTime.now().add(const Duration(days: 7))) : _debtDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _debtDate = picked;
        }
      });
    }
  }

  Future<void> _pickContact() async {
    if (!contactsPickerSupported) return;
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission was not granted.')),
        );
      }
      return;
    }

    final picked = await FlutterContacts.openExternalPick();
    if (picked == null) return;

    final full = await FlutterContacts.getContact(picked.id);
    if (full == null || !mounted) return;

    setState(() {
      _nameCtrl.text = full.displayName;
      if (full.phones.isNotEmpty) {
        _phoneCtrl.text = full.phones.first.number;
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSelectDueDate)));
      return;
    }

    setState(() => _saving = true);
    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
      await ref.read(debtsProvider.notifier).addDebt(
            type: _type,
            personName: _nameCtrl.text.trim(),
            personPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            amount: amount,
            currency: _currency ?? ref.read(defaultCurrencyProvider),
            debtDate: _debtDate,
            dueDate: _dueDate!,
            description: [_notesCtrl.text.trim(), if (_refCtrl.text.trim().isNotEmpty) 'Ref: ${_refCtrl.text.trim()}']
                .where((e) => e.isNotEmpty)
                .join(' · '),
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
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    _currency ??= defaultCurrency;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addDebt)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(l10n.whatTypeOfDebt, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeOption(
                    label: l10n.iLentMoney,
                    icon: Icons.call_received_rounded,
                    color: AppColors.owedToMe,
                    selected: _type == DebtType.lent,
                    onTap: () => setState(() => _type = DebtType.lent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeOption(
                    label: l10n.iBorrowedMoney,
                    icon: Icons.call_made_rounded,
                    color: AppColors.iOwe,
                    selected: _type == DebtType.borrowed,
                    onTap: () => setState(() => _type = DebtType.borrowed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.personName,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                suffixIcon: !contactsPickerSupported
                    ? null
                    : IconButton(
                        tooltip: l10n.pickFromContacts,
                        icon: const Icon(Icons.contacts_outlined),
                        onPressed: _pickContact,
                      ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.errorPersonNameRequired : null,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.amount, prefixIcon: const Icon(Icons.payments_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.errorEnterAmount;
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return l10n.errorAmountGreaterThanZero;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(labelText: l10n.currency),
                    items: AppConstants.currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: l10n.date,
                    value: DateFormatter.medium(_debtDate),
                    onTap: () => _pickDate(isDueDate: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: l10n.dueDate,
                    value: _dueDate != null ? DateFormatter.medium(_dueDate!) : '—',
                    onTap: () => _pickDate(isDueDate: true),
                    isError: _dueDate == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneOptional, prefixIcon: const Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _refCtrl,
              decoration: InputDecoration(labelText: l10n.referenceOptional, prefixIcon: const Icon(Icons.tag_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.descriptionNotes, alignLabelWithHint: true),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: l10n.saveDebt, onPressed: _save, loading: _saving),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : Theme.of(context).dividerColor, width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, color: selected ? color : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isError;

  const _DateField({required this.label, required this.value, required this.onTap, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          enabledBorder: isError
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.overdue),
                )
              : null,
        ),
        child: Text(value, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}

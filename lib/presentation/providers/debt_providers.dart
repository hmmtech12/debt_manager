import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/notification_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/debt_repository.dart';

final _uuid = const Uuid();

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(AppDatabase.instance);
});

/// Single source of truth for all debts (with joined person + payments).
/// Screens watch this; mutating providers below call `.refresh()` after
/// every write so the whole app stays in sync without manual plumbing.
class DebtsNotifier extends AsyncNotifier<List<DebtWithDetails>> {
  @override
  Future<List<DebtWithDetails>> build() async {
    final repo = ref.read(debtRepositoryProvider);
    return repo.getAllDebts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(debtRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getAllDebts());
  }

  Future<Person> _resolvePerson(String name, {String? phone}) async {
    final repo = ref.read(debtRepositoryProvider);
    final existing = await repo.findPersonByName(name);
    if (existing != null) return existing;
    final person = Person(id: _uuid.v4(), name: name, phone: phone);
    return repo.upsertPerson(person);
  }

  Future<void> addDebt({
    required DebtType type,
    required String personName,
    String? personPhone,
    required double amount,
    required String currency,
    required DateTime debtDate,
    required DateTime dueDate,
    String? description,
  }) async {
    final repo = ref.read(debtRepositoryProvider);
    final person = await _resolvePerson(personName, phone: personPhone);
    final now = DateTime.now();
    final debt = Debt(
      id: _uuid.v4(),
      type: type,
      personId: person.id,
      originalAmount: amount,
      currency: currency,
      debtDate: debtDate,
      dueDate: dueDate,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    await repo.addDebt(debt);
    await refresh();
  }

  Future<void> recordPayment({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    required PaymentMethod method,
    String? notes,
  }) async {
    final repo = ref.read(debtRepositoryProvider);
    final payment = Payment(
      id: _uuid.v4(),
      debtId: debtId,
      amount: amount,
      paymentDate: paymentDate,
      method: method,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await repo.addPayment(payment);
    await refresh();
  }

  Future<void> addReminder({
    required String debtId,
    required DateTime dueDate,
    required int offsetDays,
    required String personName,
    required double remainingAmount,
    required String currency,
  }) async {
    final repo = ref.read(debtRepositoryProvider);
    final reminderDate = dueDate.subtract(Duration(days: offsetDays));
    await repo.addReminder(
      debtId: debtId,
      reminderDate: reminderDate,
      reminderType: 'DUE_DATE',
    );

    final notificationId = debtId.hashCode ^ offsetDays.hashCode;
    await NotificationService.instance.scheduleReminder(
      id: notificationId,
      title: 'Debt reminder',
      body:
          '${CurrencyFormatter.format(remainingAmount, currency)} is due ${offsetDays == 0 ? 'today' : 'soon'} — $personName',
      scheduledDate: reminderDate,
    );
  }

  Future<void> markPaid(String debtId) async {
    final repo = ref.read(debtRepositoryProvider);
    await repo.markDebtPaid(debtId);
    await refresh();
  }

  Future<void> deleteDebt(String debtId) async {
    final repo = ref.read(debtRepositoryProvider);
    await repo.deleteDebt(debtId);
    await refresh();
  }

  /// Recreates debts (and, where a "Paid" amount is present, one
  /// approximating payment) from parsed CSV rows — the same column
  /// layout `ExportService.exportCsv` produces. The first row is always
  /// treated as a header and skipped. Malformed rows are skipped rather
  /// than aborting the whole import. Returns how many debts were
  /// successfully created.
  Future<int> importCsvRows(List<List<String>> rows) async {
    if (rows.length < 2) return 0;
    final repo = ref.read(debtRepositoryProvider);
    final now = DateTime.now();
    var imported = 0;

    for (final row in rows.skip(1)) {
      if (row.length < 8) continue;
      try {
        final personName = row[0].trim();
        if (personName.isEmpty) continue;

        final type = row[1].trim().toLowerCase().startsWith('lent') ? DebtType.lent : DebtType.borrowed;

        final originalAmount = double.tryParse(row[2].trim());
        if (originalAmount == null || originalAmount <= 0) continue;

        final currency = row[3].trim().isEmpty ? 'AED' : row[3].trim();
        final paidAmount = double.tryParse(row[4].trim()) ?? 0;

        final debtDate = _parseCsvDate(row[6].trim()) ?? now;
        final dueDate = _parseCsvDate(row[7].trim()) ?? debtDate.add(const Duration(days: 7));
        final notes = row.length > 9 ? row[9].trim() : null;

        final person = await _resolvePerson(personName);
        final debt = Debt(
          id: _uuid.v4(),
          type: type,
          personId: person.id,
          originalAmount: originalAmount,
          currency: currency,
          debtDate: debtDate,
          dueDate: dueDate,
          description: (notes != null && notes.isNotEmpty) ? notes : null,
          createdAt: now,
          updatedAt: now,
        );
        await repo.addDebt(debt);

        if (paidAmount > 0) {
          await repo.addPayment(Payment(
            id: _uuid.v4(),
            debtId: debt.id,
            amount: paidAmount > originalAmount ? originalAmount : paidAmount,
            paymentDate: debtDate,
            method: PaymentMethod.other,
            notes: 'Imported payment',
            createdAt: now,
          ));
        }

        imported++;
      } catch (_) {
        continue; // skip this row, keep going
      }
    }

    await refresh();
    return imported;
  }

  DateTime? _parseCsvDate(String value) {
    if (value.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (_) {
      return DateTime.tryParse(value); // fallback: ISO-ish formats
    }
  }

  Future<void> seedDemoDataIfEmpty() async {
    final repo = ref.read(debtRepositoryProvider);
    await repo.seedDemoData();
    await refresh();
  }

  Future<void> deleteAllData() async {
    final repo = ref.read(debtRepositoryProvider);
    await repo.deleteAllData();
    await refresh();
  }
}

final debtsProvider = AsyncNotifierProvider<DebtsNotifier, List<DebtWithDetails>>(
  DebtsNotifier.new,
);

/// Derived, read-only summary numbers for the dashboard & reports —
/// computed once here so no screen duplicates this logic.
class DebtSummary {
  final double totalOwedToMe;
  final double totalIOwe;
  final double totalLent;
  final double totalBorrowed;
  final double totalRepaid;
  final double totalOutstanding;
  final double overdueAmount;
  final int paidCount;
  final int partiallyPaidCount;
  final int outstandingCount;
  final int overdueCount;

  const DebtSummary({
    required this.totalOwedToMe,
    required this.totalIOwe,
    required this.totalLent,
    required this.totalBorrowed,
    required this.totalRepaid,
    required this.totalOutstanding,
    required this.overdueAmount,
    required this.paidCount,
    required this.partiallyPaidCount,
    required this.outstandingCount,
    required this.overdueCount,
  });

  double get netPosition => totalOwedToMe - totalIOwe;

  static const empty = DebtSummary(
    totalOwedToMe: 0,
    totalIOwe: 0,
    totalLent: 0,
    totalBorrowed: 0,
    totalRepaid: 0,
    totalOutstanding: 0,
    overdueAmount: 0,
    paidCount: 0,
    partiallyPaidCount: 0,
    outstandingCount: 0,
    overdueCount: 0,
  );
}

final debtSummaryProvider = Provider<DebtSummary>((ref) {
  final debtsAsync = ref.watch(debtsProvider);
  final debts = debtsAsync.valueOrNull ?? [];

  double owedToMe = 0, iOwe = 0, lent = 0, borrowed = 0, repaid = 0, outstanding = 0, overdue = 0;
  int paidCount = 0, partialCount = 0, outstandingCount = 0, overdueCount = 0;

  for (final d in debts) {
    repaid += d.totalPaid;
    if (d.debt.type == DebtType.lent) {
      lent += d.debt.originalAmount;
      owedToMe += d.remainingAmount;
    } else {
      borrowed += d.debt.originalAmount;
      iOwe += d.remainingAmount;
    }
    outstanding += d.remainingAmount;

    switch (d.status) {
      case DebtStatus.paid:
        paidCount++;
        break;
      case DebtStatus.partiallyPaid:
        partialCount++;
        break;
      case DebtStatus.outstanding:
        outstandingCount++;
        break;
      case DebtStatus.overdue:
        overdueCount++;
        overdue += d.remainingAmount;
        break;
    }
  }

  return DebtSummary(
    totalOwedToMe: owedToMe,
    totalIOwe: iOwe,
    totalLent: lent,
    totalBorrowed: borrowed,
    totalRepaid: repaid,
    totalOutstanding: outstanding,
    overdueAmount: overdue,
    paidCount: paidCount,
    partiallyPaidCount: partialCount,
    outstandingCount: outstandingCount,
    overdueCount: overdueCount,
  );
});

import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/domain/entities/debt.dart';
import 'package:debt_manager/domain/entities/enums.dart';
import 'package:debt_manager/domain/entities/payment.dart';
import 'package:debt_manager/domain/entities/person.dart';

Debt _debt({
  double amount = 1000,
  DateTime? dueDate,
  bool manuallyPaid = false,
}) {
  final now = DateTime.now();
  return Debt(
    id: 'd1',
    type: DebtType.lent,
    personId: 'p1',
    originalAmount: amount,
    currency: 'AED',
    debtDate: now,
    dueDate: dueDate ?? now.add(const Duration(days: 10)),
    createdAt: now,
    updatedAt: now,
    manuallyMarkedPaid: manuallyPaid,
  );
}

final _person = const Person(id: 'p1', name: 'Ahmed');

void main() {
  group('DebtWithDetails calculations', () {
    test('no payments -> OUTSTANDING, remaining = full amount', () {
      final item = DebtWithDetails(debt: _debt(), person: _person, payments: const []);
      expect(item.totalPaid, 0);
      expect(item.remainingAmount, 1000);
      expect(item.status, DebtStatus.outstanding);
    });

    test('partial payment -> PARTIALLY_PAID, correct remaining', () {
      final payment = Payment(
        id: 'pay1',
        debtId: 'd1',
        amount: 400,
        paymentDate: DateTime.now(),
        method: PaymentMethod.cash,
        createdAt: DateTime.now(),
      );
      final item = DebtWithDetails(debt: _debt(), person: _person, payments: [payment]);
      expect(item.totalPaid, 400);
      expect(item.remainingAmount, 600);
      expect(item.status, DebtStatus.partiallyPaid);
    });

    test('full payment -> PAID, remaining = 0', () {
      final payment = Payment(
        id: 'pay1',
        debtId: 'd1',
        amount: 1000,
        paymentDate: DateTime.now(),
        method: PaymentMethod.cash,
        createdAt: DateTime.now(),
      );
      final item = DebtWithDetails(debt: _debt(), person: _person, payments: [payment]);
      expect(item.remainingAmount, 0);
      expect(item.status, DebtStatus.paid);
    });

    test('past due date with balance remaining -> OVERDUE', () {
      final item = DebtWithDetails(
        debt: _debt(dueDate: DateTime.now().subtract(const Duration(days: 3))),
        person: _person,
        payments: const [],
      );
      expect(item.status, DebtStatus.overdue);
    });

    test('manually marked paid overrides balance -> PAID', () {
      final item = DebtWithDetails(debt: _debt(manuallyPaid: true), person: _person, payments: const []);
      expect(item.status, DebtStatus.paid);
    });

    test('progress fraction is clamped between 0 and 1', () {
      final overpayment = Payment(
        id: 'pay1',
        debtId: 'd1',
        amount: 1500, // more than original amount
        paymentDate: DateTime.now(),
        method: PaymentMethod.cash,
        createdAt: DateTime.now(),
      );
      final item = DebtWithDetails(debt: _debt(), person: _person, payments: [overpayment]);
      expect(item.progressFraction, 1.0);
      expect(item.remainingAmount, 0);
    });

    test('no interest fields exist anywhere on Debt', () {
      // Static/structural guard: Debt.toMap() must never contain
      // interest/APR/penalty keys, by design of the schema.
      final map = _debt().toMap();
      for (final forbidden in ['interest', 'apr', 'penalty', 'lateFee']) {
        expect(map.keys.any((k) => k.toLowerCase().contains(forbidden)), isFalse);
      }
    });
  });
}

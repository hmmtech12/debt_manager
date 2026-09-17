import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/debt.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/debt_repository.dart';
import '../database/app_database.dart';

class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl(this._appDb);

  final AppDatabase _appDb;
  final Uuid _uuid = const Uuid();

  Future<Database> get _db async => _appDb.database;

  // ---------------- Persons ----------------

  @override
  Future<List<Person>> getAllPersons() async {
    final db = await _db;
    final rows = await db.query('persons', orderBy: 'name ASC');
    return rows.map(Person.fromMap).toList();
  }

  @override
  Future<Person> upsertPerson(Person person) async {
    final db = await _db;
    await db.insert('persons', person.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return person;
  }

  @override
    Future<Person?> findPersonByName(String name) async {
    final db = await _db;
    final rows = await db.query(
      'persons',
      where: 'LOWER(TRIM(name)) = ?',
      whereArgs: [name.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Person.fromMap(rows.first);
  }

  // ---------------- Debts ----------------

  @override
  Future<List<DebtWithDetails>> getAllDebts() async {
    final db = await _db;
    final debtRows = await db.query('debts', orderBy: 'dueDate ASC');
    final result = <DebtWithDetails>[];

    for (final row in debtRows) {
      final debt = Debt.fromMap(row);
      final personRows = await db.query('persons', where: 'id = ?', whereArgs: [debt.personId], limit: 1);
      if (personRows.isEmpty) continue;
      final person = Person.fromMap(personRows.first);
      final paymentRows =
          await db.query('payments', where: 'debtId = ?', whereArgs: [debt.id], orderBy: 'paymentDate DESC');
      final payments = paymentRows.map(Payment.fromMap).toList();
      result.add(DebtWithDetails(debt: debt, person: person, payments: payments));
    }
    return result;
  }

  @override
  Future<DebtWithDetails?> getDebtById(String id) async {
    final db = await _db;
    final debtRows = await db.query('debts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (debtRows.isEmpty) return null;
    final debt = Debt.fromMap(debtRows.first);
    final personRows = await db.query('persons', where: 'id = ?', whereArgs: [debt.personId], limit: 1);
    if (personRows.isEmpty) return null;
    final person = Person.fromMap(personRows.first);
    final paymentRows =
        await db.query('payments', where: 'debtId = ?', whereArgs: [debt.id], orderBy: 'paymentDate DESC');
    final payments = paymentRows.map(Payment.fromMap).toList();
    return DebtWithDetails(debt: debt, person: person, payments: payments);
  }

  @override
  Future<Debt> addDebt(Debt debt) async {
    final db = await _db;
    await db.insert('debts', debt.toMap());
    return debt;
  }

  @override
  Future<Debt> updateDebt(Debt debt) async {
    final db = await _db;
    await db.update('debts', debt.toMap(), where: 'id = ?', whereArgs: [debt.id]);
    return debt;
  }

  @override
  Future<void> deleteDebt(String id) async {
    final db = await _db;
    await db.delete('payments', where: 'debtId = ?', whereArgs: [id]);
    await db.delete('reminders', where: 'debtId = ?', whereArgs: [id]);
    await db.delete('attachments', where: 'debtId = ?', whereArgs: [id]);
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> markDebtPaid(String id) async {
    final db = await _db;
    await db.update(
      'debts',
      {'manuallyMarkedPaid': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- Payments ----------------

  @override
  Future<Payment> addPayment(Payment payment) async {
    final db = await _db;
    await db.insert('payments', payment.toMap());
    // Touch the parent debt's updatedAt so lists reflect recent activity.
    await db.update(
      'debts',
      {'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [payment.debtId],
    );
    return payment;
  }

  @override
  Future<List<Payment>> getPaymentsForDebt(String debtId) async {
    final db = await _db;
    final rows = await db.query('payments', where: 'debtId = ?', whereArgs: [debtId], orderBy: 'paymentDate DESC');
    return rows.map(Payment.fromMap).toList();
  }

  @override
  Future<void> deletePayment(String id) async {
    final db = await _db;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Reminders ----------------

  @override
  Future<void> addReminder({
    required String debtId,
    required DateTime reminderDate,
    required String reminderType,
  }) async {
    final db = await _db;
    await db.insert('reminders', {
      'id': _uuid.v4(),
      'debtId': debtId,
      'reminderDate': reminderDate.toIso8601String(),
      'reminderType': reminderType,
      'isEnabled': 1,
    });
  }

  // ---------------- Bulk ----------------

  @override
  Future<void> deleteAllData() async {
    await _appDb.deleteAllRows();
  }

  @override
  Future<void> seedDemoData() async {
    final existing = await getAllPersons();
    if (existing.isNotEmpty) return; // never overwrite real user data

    final ahmed = Person(id: _uuid.v4(), name: 'Ahmed', phone: '+971501234567');
    final omar = Person(id: _uuid.v4(), name: 'Omar', phone: '+971502223344');
    final ali = Person(id: _uuid.v4(), name: 'Ali', phone: '+971503334455');

    for (final p in [ahmed, omar, ali]) {
      await upsertPerson(p);
    }

    final now = DateTime.now();

    final debt1 = Debt(
      id: _uuid.v4(),
      type: DebtType.lent,
      personId: ahmed.id,
      originalAmount: 5000,
      currency: 'AED',
      debtDate: now.subtract(const Duration(days: 20)),
      dueDate: now.add(const Duration(days: 5)),
      description: 'Qard Hasan — helped with car repair',
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
    );
    await addDebt(debt1);
    await addPayment(Payment(
      id: _uuid.v4(),
      debtId: debt1.id,
      amount: 2000,
      paymentDate: now.subtract(const Duration(days: 4)),
      method: PaymentMethod.cash,
      notes: 'Partial repayment',
      createdAt: now.subtract(const Duration(days: 4)),
    ));

    final debt2 = Debt(
      id: _uuid.v4(),
      type: DebtType.lent,
      personId: omar.id,
      originalAmount: 500,
      currency: 'AED',
      debtDate: now.subtract(const Duration(days: 10)),
      dueDate: now.add(const Duration(days: 1)),
      description: 'Lunch money',
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now,
    );
    await addDebt(debt2);

    final debt3 = Debt(
      id: _uuid.v4(),
      type: DebtType.borrowed,
      personId: ali.id,
      originalAmount: 1000,
      currency: 'AED',
      debtDate: now.subtract(const Duration(days: 30)),
      dueDate: now.subtract(const Duration(days: 2)),
      description: 'Emergency travel expense',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
    await addDebt(debt3);
    await addPayment(Payment(
      id: _uuid.v4(),
      debtId: debt3.id,
      amount: 250,
      paymentDate: now.subtract(const Duration(days: 1)),
      method: PaymentMethod.bankTransfer,
      notes: 'Partial repayment',
      createdAt: now.subtract(const Duration(days: 1)),
    ));
  }
}

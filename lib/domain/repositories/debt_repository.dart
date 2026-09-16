import '../entities/debt.dart';
import '../entities/payment.dart';
import '../entities/person.dart';

/// Contract the UI/providers depend on. The concrete implementation lives
/// in data/repositories and can be swapped (e.g. for a test fake) without
/// touching any screen or provider code.
abstract class DebtRepository {
  // Persons
  Future<List<Person>> getAllPersons();
  Future<Person> upsertPerson(Person person);
  Future<Person?> findPersonByName(String name);

  // Debts
  Future<List<DebtWithDetails>> getAllDebts();
  Future<DebtWithDetails?> getDebtById(String id);
  Future<Debt> addDebt(Debt debt);
  Future<Debt> updateDebt(Debt debt);
  Future<void> deleteDebt(String id);
  Future<void> markDebtPaid(String id);

  // Payments
  Future<Payment> addPayment(Payment payment);
  Future<List<Payment>> getPaymentsForDebt(String debtId);
  Future<void> deletePayment(String id);

  // Reminders
  Future<void> addReminder({
    required String debtId,
    required DateTime reminderDate,
    required String reminderType,
  });

  // Bulk / lifecycle
  Future<void> deleteAllData();
  Future<void> seedDemoData();
}

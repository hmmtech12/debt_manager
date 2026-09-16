import 'enums.dart';
import 'payment.dart';
import 'person.dart';

/// Raw debt record as stored. No interest fields exist by design — only
/// principal, an agreed due date, and free-text notes.
class Debt {
  final String id;
  final DebtType type;
  final String personId;
  final double originalAmount;
  final String currency;
  final DateTime debtDate;
  final DateTime dueDate;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool manuallyMarkedPaid;

  const Debt({
    required this.id,
    required this.type,
    required this.personId,
    required this.originalAmount,
    required this.currency,
    required this.debtDate,
    required this.dueDate,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.manuallyMarkedPaid = false,
  });

  Debt copyWith({
    DebtType? type,
    String? personId,
    double? originalAmount,
    String? currency,
    DateTime? debtDate,
    DateTime? dueDate,
    String? description,
    DateTime? updatedAt,
    bool? manuallyMarkedPaid,
  }) {
    return Debt(
      id: id,
      type: type ?? this.type,
      personId: personId ?? this.personId,
      originalAmount: originalAmount ?? this.originalAmount,
      currency: currency ?? this.currency,
      debtDate: debtDate ?? this.debtDate,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      manuallyMarkedPaid: manuallyMarkedPaid ?? this.manuallyMarkedPaid,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.dbValue,
        'personId': personId,
        'originalAmount': originalAmount,
        'currency': currency,
        'debtDate': debtDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'manuallyMarkedPaid': manuallyMarkedPaid ? 1 : 0,
      };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
        id: map['id'] as String,
        type: DebtTypeX.fromDb(map['type'] as String),
        personId: map['personId'] as String,
        originalAmount: (map['originalAmount'] as num).toDouble(),
        currency: map['currency'] as String,
        debtDate: DateTime.parse(map['debtDate'] as String),
        dueDate: DateTime.parse(map['dueDate'] as String),
        description: map['description'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        manuallyMarkedPaid: (map['manuallyMarkedPaid'] as int? ?? 0) == 1,
      );
}

/// UI-facing aggregate: a debt joined with its person and payments, plus
/// derived fields computed purely from data (never hardcoded in widgets).
class DebtWithDetails {
  final Debt debt;
  final Person person;
  final List<Payment> payments;

  const DebtWithDetails({
    required this.debt,
    required this.person,
    required this.payments,
  });

  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);

  double get remainingAmount {
    final remaining = debt.originalAmount - totalPaid;
    return remaining < 0 ? 0 : remaining;
  }

  double get progressFraction {
    if (debt.originalAmount <= 0) return 0;
    return (totalPaid / debt.originalAmount).clamp(0.0, 1.0);
  }

  /// Business rule (kept out of the UI, per the spec):
  /// - no payments -> OUTSTANDING (or OVERDUE if past due date)
  /// - some payments, balance > 0 -> PARTIALLY_PAID (or OVERDUE if past due)
  /// - balance == 0 -> PAID
  DebtStatus get status {
    if (remainingAmount <= 0.0001 || debt.manuallyMarkedPaid) {
      return DebtStatus.paid;
    }
    final isPastDue = DateTime.now().isAfter(debt.dueDate);
    if (totalPaid <= 0) {
      return isPastDue ? DebtStatus.overdue : DebtStatus.outstanding;
    }
    return isPastDue ? DebtStatus.overdue : DebtStatus.partiallyPaid;
  }
}

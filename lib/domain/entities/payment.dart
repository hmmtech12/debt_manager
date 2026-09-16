import 'enums.dart';

class Payment {
  final String id;
  final String debtId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod method;
  final String? notes;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'debtId': debtId,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentMethod': method.dbValue,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as String,
        debtId: map['debtId'] as String,
        amount: (map['amount'] as num).toDouble(),
        paymentDate: DateTime.parse(map['paymentDate'] as String),
        method: PaymentMethodX.fromDb(map['paymentMethod'] as String),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

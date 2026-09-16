enum DebtType { lent, borrowed }

enum DebtStatus { outstanding, partiallyPaid, paid, overdue }

enum PaymentMethod { cash, bankTransfer, other }

enum ReminderType { dueDate, paymentDate, followUp }

extension DebtTypeX on DebtType {
  String get dbValue => this == DebtType.lent ? 'LENT' : 'BORROWED';

  static DebtType fromDb(String value) => value == 'LENT' ? DebtType.lent : DebtType.borrowed;
}

extension DebtStatusX on DebtStatus {
  String get dbValue {
    switch (this) {
      case DebtStatus.outstanding:
        return 'OUTSTANDING';
      case DebtStatus.partiallyPaid:
        return 'PARTIALLY_PAID';
      case DebtStatus.paid:
        return 'PAID';
      case DebtStatus.overdue:
        return 'OVERDUE';
    }
  }

  static DebtStatus fromDb(String value) {
    switch (value) {
      case 'PARTIALLY_PAID':
        return DebtStatus.partiallyPaid;
      case 'PAID':
        return DebtStatus.paid;
      case 'OVERDUE':
        return DebtStatus.overdue;
      case 'OUTSTANDING':
      default:
        return DebtStatus.outstanding;
    }
  }
}

extension PaymentMethodX on PaymentMethod {
  String get dbValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
      case PaymentMethod.other:
        return 'OTHER';
    }
  }

  static PaymentMethod fromDb(String value) {
    switch (value) {
      case 'BANK_TRANSFER':
        return PaymentMethod.bankTransfer;
      case 'OTHER':
        return PaymentMethod.other;
      case 'CASH':
      default:
        return PaymentMethod.cash;
    }
  }
}

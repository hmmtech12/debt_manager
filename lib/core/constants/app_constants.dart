class AppConstants {
  AppConstants._();

  static const String appName = 'Debt Manager';

  /// Supported currencies. AED is first/default for UAE users.
  static const List<String> currencies = [
    'AED',
    'SAR',
    'USD',
    'EUR',
    'GBP',
    'INR',
    'PKR',
    'BDT',
    'MYR',
    'IDR',
  ];

  static const String defaultCurrency = 'AED';

  static const List<String> paymentMethods = [
    'CASH',
    'BANK_TRANSFER',
    'OTHER',
  ];

  static const String shariahDisclaimer =
      'This application is a debt-recording and management tool. It does '
      'not provide a formal Shariah ruling or financial advice. Consult a '
      'qualified scholar for specific Islamic finance questions.';

  static const String qardHasanNote =
      'This app follows the spirit of Qard Hasan (a benevolent, '
      'interest-free loan). It never calculates interest, APR, or late '
      'payment penalties — only principal, repayments, and the agreed '
      'due date.';

  /// Reminder offsets, in days before the due date. 0 = on the due date.
  static const Map<String, int> reminderOffsets = {
    'ON_DUE_DATE': 0,
    'ONE_DAY_BEFORE': 1,
    'THREE_DAYS_BEFORE': 3,
    'SEVEN_DAYS_BEFORE': 7,
  };
}

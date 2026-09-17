class AppConstants {
  AppConstants._();

  static const String appName = 'Easy Debt Manager';

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

  /// PLACEHOLDER TEXT — replace with your own actual privacy policy.
  /// This is what shows when someone taps "Privacy Policy" in Settings
  /// → About. Edit this constant's value directly; nothing else needs
  /// to change.
  static const String privacyPolicyText =
      'Your privacy policy goes here.\n\n'
      'For example: This app stores all data locally on your device. '
      'No debt information is transmitted to any server unless you '
      'explicitly enable a backup or export feature. Contact details '
      'you add for a person are used only within this app.\n\n'
      'Replace this placeholder with your actual policy before '
      'publishing the app.';

  /// PLACEHOLDER TEXT — replace with your own actual terms of use.
  /// Shows when someone taps "Terms" in Settings → About.
  static const String termsText =
      'Your terms of use go here.\n\n'
      'For example: This app is provided as-is for personal debt '
      'tracking. It is not a financial institution, does not provide '
      'legal or financial advice, and the developer is not responsible '
      'for decisions made based on data recorded in the app.\n\n'
      'Replace this placeholder with your actual terms before '
      'publishing the app.';

  /// Reminder offsets, in days before the due date. 0 = on the due date.
  static const Map<String, int> reminderOffsets = {
    'ON_DUE_DATE': 0,
    'ONE_DAY_BEFORE': 1,
    'THREE_DAYS_BEFORE': 3,
    'SEVEN_DAYS_BEFORE': 7,
  };
}
import 'package:flutter/material.dart';

/// Hand-written localization layer. Avoids requiring `flutter gen-l10n` /
/// ARB build steps so the project compiles immediately. To add a string:
/// 1. Add a getter here.
/// 2. Add the English value to [_en] and Arabic value to [_ar].
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Map<String, String> get _map => locale.languageCode == 'ar' ? _ar : _en;

  String _t(String key) => _map[key] ?? _en[key] ?? key;

  // Onboarding
  String get onboardTitle1 => _t('onboardTitle1');
  String get onboardSubtitle1 => _t('onboardSubtitle1');
  String get onboardTitle2 => _t('onboardTitle2');
  String get onboardBullet2a => _t('onboardBullet2a');
  String get onboardBullet2b => _t('onboardBullet2b');
  String get onboardBullet2c => _t('onboardBullet2c');
  String get onboardTitle3 => _t('onboardTitle3');
  String get onboardSubtitle3 => _t('onboardSubtitle3');
  String get getStarted => _t('getStarted');
  String get skip => _t('skip');

  // Home
  String get greetingHi => _t('greetingHi');
  String get moneyOwedToMe => _t('moneyOwedToMe');
  String get moneyIOwe => _t('moneyIOwe');
  String get netDebtPosition => _t('netDebtPosition');
  String get upcomingDueDates => _t('upcomingDueDates');
  String get recentActivity => _t('recentActivity');
  String get addDebt => _t('addDebt');
  String get noDebtsYet => _t('noDebtsYet');
  String get noDebtsSubtitle => _t('noDebtsSubtitle');
  String get addFirstDebt => _t('addFirstDebt');
  String get seeAll => _t('seeAll');
  String get dueTomorrow => _t('dueTomorrow');
  String get dueToday => _t('dueToday');
  String get dueInDays => _t('dueInDays');
  String get overdueBy => _t('overdueBy');

  // Nav
  String get navHome => _t('navHome');
  String get navDebts => _t('navDebts');
  String get navCalendar => _t('navCalendar');
  String get navReports => _t('navReports');
  String get navSettings => _t('navSettings');

  // Debts list
  String get toReceive => _t('toReceive');
  String get toPay => _t('toPay');
  String get search => _t('search');
  String get filter => _t('filter');
  String get sortBy => _t('sortBy');
  String get remaining => _t('remaining');
  String get due => _t('due');

  // Statuses
  String get statusOutstanding => _t('statusOutstanding');
  String get statusPartiallyPaid => _t('statusPartiallyPaid');
  String get statusPaid => _t('statusPaid');
  String get statusOverdue => _t('statusOverdue');

  // Add debt
  String get whatTypeOfDebt => _t('whatTypeOfDebt');
  String get iLentMoney => _t('iLentMoney');
  String get iBorrowedMoney => _t('iBorrowedMoney');
  String get personName => _t('personName');
  String get amount => _t('amount');
  String get currency => _t('currency');
  String get date => _t('date');
  String get dueDate => _t('dueDate');
  String get descriptionNotes => _t('descriptionNotes');
  String get phoneOptional => _t('phoneOptional');
  String get referenceOptional => _t('referenceOptional');
  String get saveDebt => _t('saveDebt');
  String get pickFromContacts => _t('pickFromContacts');

  // Debt details
  String get originalAmount => _t('originalAmount');
  String get paid => _t('paid');
  String get createdDate => _t('createdDate');
  String get recordPayment => _t('recordPayment');
  String get edit => _t('edit');
  String get addReminder => _t('addReminder');
  String get markAsPaid => _t('markAsPaid');
  String get delete => _t('delete');
  String get paymentHistory => _t('paymentHistory');
  String get noPaymentsYet => _t('noPaymentsYet');

  // Record payment
  String get originalDebt => _t('originalDebt');
  String get alreadyPaid => _t('alreadyPaid');
  String get paymentAmount => _t('paymentAmount');
  String get paymentMethod => _t('paymentMethod');
  String get cash => _t('cash');
  String get bankTransfer => _t('bankTransfer');
  String get other => _t('other');
  String get savePayment => _t('savePayment');

  // Reports
  String get totalLent => _t('totalLent');
  String get totalBorrowed => _t('totalBorrowed');
  String get totalRepaid => _t('totalRepaid');
  String get totalOutstanding => _t('totalOutstanding');
  String get overdueAmount => _t('overdueAmount');
  String get debtStatusDistribution => _t('debtStatusDistribution');

  // Settings
  String get profile => _t('profile');
  String get defaultCurrency => _t('defaultCurrency');
  String get appearance => _t('appearance');
  String get light => _t('light');
  String get darkMode => _t('darkMode');
  String get systemDefault => _t('systemDefault');
  String get language => _t('language');
  String get notifications => _t('notifications');
  String get enableReminders => _t('enableReminders');
  String get security => _t('security');
  String get appLock => _t('appLock');
  String get biometricUnlock => _t('biometricUnlock');
  String get data => _t('data');
  String get exportData => _t('exportData');
  String get importData => _t('importData');
  String get backup => _t('backup');
  String get restore => _t('restore');
  String get deleteAllData => _t('deleteAllData');
  String get about => _t('about');
  String get privacyPolicy => _t('privacyPolicy');
  String get terms => _t('terms');
  String get shariahDisclaimer => _t('shariahDisclaimer');
  String get aboutApp => _t('aboutApp');

  // Errors / validation
  String get errorEnterAmount => _t('errorEnterAmount');
  String get errorAmountGreaterThanZero => _t('errorAmountGreaterThanZero');
  String get errorPersonNameRequired => _t('errorPersonNameRequired');
  String get errorSelectDueDate => _t('errorSelectDueDate');
  String get errorPaymentExceedsBalance => _t('errorPaymentExceedsBalance');
  String get errorSomethingWentWrong => _t('errorSomethingWentWrong');

  // Common
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get save => _t('save');
  String get areYouSure => _t('areYouSure');
}

const Map<String, String> _en = {
  'onboardTitle1': 'Manage your debts with clarity',
  'onboardSubtitle1':
      'A simple, private way to track money lent and borrowed — with no interest, ever.',
  'onboardTitle2': 'Everything in one place',
  'onboardBullet2a': 'Track what you owe',
  'onboardBullet2b': 'Track what others owe you',
  'onboardBullet2c': 'Record repayments as they happen',
  'onboardTitle3': 'Designed with Shariah-conscious principles',
  'onboardSubtitle3':
      'This app never calculates interest, APR, or late-payment penalties. It only records principal amounts and agreed due dates, in the spirit of Qard Hasan.',
  'getStarted': 'Get Started',
  'skip': 'Skip',
  'greetingHi': 'Hi',
  'moneyOwedToMe': 'Money Owed to Me',
  'moneyIOwe': 'Money I Owe',
  'netDebtPosition': 'Net Debt Position',
  'upcomingDueDates': 'Upcoming Due Dates',
  'recentActivity': 'Recent Activity',
  'addDebt': 'Add Debt',
  'noDebtsYet': 'No debts recorded yet',
  'noDebtsSubtitle': 'Keep track of money you owe and money owed to you.',
  'addFirstDebt': 'Add Your First Debt',
  'seeAll': 'See all',
  'dueTomorrow': 'Due tomorrow',
  'dueToday': 'Due today',
  'dueInDays': 'Due in {n} days',
  'overdueBy': 'Overdue by {n} days',
  'navHome': 'Home',
  'navDebts': 'Debts',
  'navCalendar': 'Calendar',
  'navReports': 'Reports',
  'navSettings': 'Settings',
  'toReceive': 'To Receive',
  'toPay': 'To Pay',
  'search': 'Search',
  'filter': 'Filter',
  'sortBy': 'Sort by',
  'remaining': 'remaining',
  'due': 'Due',
  'statusOutstanding': 'Outstanding',
  'statusPartiallyPaid': 'Partially Paid',
  'statusPaid': 'Paid',
  'statusOverdue': 'Overdue',
  'whatTypeOfDebt': 'What type of debt is this?',
  'iLentMoney': 'I Lent Money',
  'iBorrowedMoney': 'I Borrowed Money',
  'personName': 'Person name',
  'amount': 'Amount',
  'currency': 'Currency',
  'date': 'Date',
  'dueDate': 'Due date',
  'descriptionNotes': 'Description / notes',
  'phoneOptional': 'Phone number (optional)',
  'referenceOptional': 'Reference number (optional)',
  'saveDebt': 'Save Debt',
  'pickFromContacts': 'Pick from contacts',
  'originalAmount': 'Original Amount',
  'paid': 'Paid',
  'createdDate': 'Created date',
  'recordPayment': 'Record Payment',
  'edit': 'Edit',
  'addReminder': 'Add Reminder',
  'markAsPaid': 'Mark as Paid',
  'delete': 'Delete',
  'paymentHistory': 'Payment History',
  'noPaymentsYet': 'No payments recorded yet',
  'originalDebt': 'Original debt',
  'alreadyPaid': 'Amount already paid',
  'paymentAmount': 'Payment Amount',
  'paymentMethod': 'Payment method',
  'cash': 'Cash',
  'bankTransfer': 'Bank Transfer',
  'other': 'Other',
  'savePayment': 'Save Payment',
  'totalLent': 'Total Lent',
  'totalBorrowed': 'Total Borrowed',
  'totalRepaid': 'Total Repaid',
  'totalOutstanding': 'Total Outstanding',
  'overdueAmount': 'Overdue Amount',
  'debtStatusDistribution': 'Debt Status Distribution',
  'profile': 'Profile',
  'defaultCurrency': 'Default currency',
  'appearance': 'Appearance',
  'light': 'Light',
  'darkMode': 'Dark mode',
  'systemDefault': 'System default',
  'language': 'Language',
  'notifications': 'Notifications',
  'enableReminders': 'Enable reminders',
  'security': 'Security',
  'appLock': 'App lock (PIN)',
  'biometricUnlock': 'Biometric unlock',
  'data': 'Data',
  'exportData': 'Export data',
  'importData': 'Import data',
  'backup': 'Backup',
  'restore': 'Restore',
  'deleteAllData': 'Delete all data',
  'about': 'About',
  'privacyPolicy': 'Privacy Policy',
  'terms': 'Terms',
  'shariahDisclaimer': 'Shariah Disclaimer',
  'aboutApp': 'About the app',
  'errorEnterAmount': 'Please enter an amount.',
  'errorAmountGreaterThanZero': 'Amount must be greater than 0.',
  'errorPersonNameRequired': 'Please enter the person\'s name.',
  'errorSelectDueDate': 'Please select a due date.',
  'errorPaymentExceedsBalance': 'Payment cannot be greater than the remaining balance.',
  'errorSomethingWentWrong': 'Something went wrong. Please try again.',
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'save': 'Save',
  'areYouSure': 'Are you sure?',
};

const Map<String, String> _ar = {
  'onboardTitle1': 'أدر ديونك بوضوح',
  'onboardSubtitle1': 'طريقة بسيطة وخاصة لتتبّع الأموال المُقرَضة والمُقترَضة — دون فوائد على الإطلاق.',
  'onboardTitle2': 'كل شيء في مكان واحد',
  'onboardBullet2a': 'تتبّع ما عليك',
  'onboardBullet2b': 'تتبّع ما لك عند الآخرين',
  'onboardBullet2c': 'سجّل السدادات فور حدوثها',
  'onboardTitle3': 'مصمم وفق مبادئ مراعية للشريعة',
  'onboardSubtitle3':
      'لا يحسب هذا التطبيق فائدة أو نسبة سنوية أو غرامات تأخير أبدًا. يسجّل فقط المبالغ الأصلية وتواريخ الاستحقاق المتفق عليها، بروح القرض الحسن.',
  'getStarted': 'ابدأ الآن',
  'skip': 'تخطي',
  'greetingHi': 'مرحبًا',
  'moneyOwedToMe': 'المال المستحق لي',
  'moneyIOwe': 'المال الذي عليّ',
  'netDebtPosition': 'صافي وضع الدين',
  'upcomingDueDates': 'تواريخ الاستحقاق القادمة',
  'recentActivity': 'النشاط الأخير',
  'addDebt': 'إضافة دين',
  'noDebtsYet': 'لا توجد ديون مسجّلة بعد',
  'noDebtsSubtitle': 'تتبّع الأموال التي عليك والأموال المستحقة لك.',
  'addFirstDebt': 'أضف أول دين',
  'seeAll': 'عرض الكل',
  'dueTomorrow': 'يستحق غدًا',
  'dueToday': 'يستحق اليوم',
  'dueInDays': 'يستحق خلال {n} أيام',
  'overdueBy': 'متأخر منذ {n} أيام',
  'navHome': 'الرئيسية',
  'navDebts': 'الديون',
  'navCalendar': 'التقويم',
  'navReports': 'التقارير',
  'navSettings': 'الإعدادات',
  'toReceive': 'لي عند الآخرين',
  'toPay': 'عليّ للآخرين',
  'search': 'بحث',
  'filter': 'تصفية',
  'sortBy': 'ترتيب حسب',
  'remaining': 'متبقٍ',
  'due': 'الاستحقاق',
  'statusOutstanding': 'قائم',
  'statusPartiallyPaid': 'مسدد جزئيًا',
  'statusPaid': 'مسدد',
  'statusOverdue': 'متأخر',
  'whatTypeOfDebt': 'ما نوع هذا الدين؟',
  'iLentMoney': 'أقرضتُ مالًا',
  'iBorrowedMoney': 'اقترضتُ مالًا',
  'personName': 'اسم الشخص',
  'amount': 'المبلغ',
  'currency': 'العملة',
  'date': 'التاريخ',
  'dueDate': 'تاريخ الاستحقاق',
  'descriptionNotes': 'وصف / ملاحظات',
  'phoneOptional': 'رقم الهاتف (اختياري)',
  'referenceOptional': 'رقم مرجعي (اختياري)',
  'saveDebt': 'حفظ الدين',
  'pickFromContacts': 'اختيار من جهات الاتصال',
  'originalAmount': 'المبلغ الأصلي',
  'paid': 'المسدد',
  'createdDate': 'تاريخ الإنشاء',
  'recordPayment': 'تسجيل سداد',
  'edit': 'تعديل',
  'addReminder': 'إضافة تذكير',
  'markAsPaid': 'وضع علامة كمسدد',
  'delete': 'حذف',
  'paymentHistory': 'سجل السدادات',
  'noPaymentsYet': 'لا توجد سدادات مسجّلة بعد',
  'originalDebt': 'الدين الأصلي',
  'alreadyPaid': 'المبلغ المسدد سابقًا',
  'paymentAmount': 'مبلغ السداد',
  'paymentMethod': 'طريقة السداد',
  'cash': 'نقدًا',
  'bankTransfer': 'تحويل بنكي',
  'other': 'أخرى',
  'savePayment': 'حفظ السداد',
  'totalLent': 'إجمالي المُقرَض',
  'totalBorrowed': 'إجمالي المُقترَض',
  'totalRepaid': 'إجمالي المسدد',
  'totalOutstanding': 'إجمالي القائم',
  'overdueAmount': 'المبلغ المتأخر',
  'debtStatusDistribution': 'توزيع حالات الديون',
  'profile': 'الملف الشخصي',
  'defaultCurrency': 'العملة الافتراضية',
  'appearance': 'المظهر',
  'light': 'فاتح',
  'darkMode': 'الوضع الداكن',
  'systemDefault': 'افتراضي النظام',
  'language': 'اللغة',
  'notifications': 'الإشعارات',
  'enableReminders': 'تفعيل التذكيرات',
  'security': 'الأمان',
  'appLock': 'قفل التطبيق (رمز PIN)',
  'biometricUnlock': 'فتح بالبصمة',
  'data': 'البيانات',
  'exportData': 'تصدير البيانات',
  'importData': 'استيراد البيانات',
  'backup': 'نسخ احتياطي',
  'restore': 'استعادة',
  'deleteAllData': 'حذف جميع البيانات',
  'about': 'حول',
  'privacyPolicy': 'سياسة الخصوصية',
  'terms': 'الشروط',
  'shariahDisclaimer': 'إخلاء المسؤولية الشرعي',
  'aboutApp': 'عن التطبيق',
  'errorEnterAmount': 'الرجاء إدخال مبلغ.',
  'errorAmountGreaterThanZero': 'يجب أن يكون المبلغ أكبر من 0.',
  'errorPersonNameRequired': 'الرجاء إدخال اسم الشخص.',
  'errorSelectDueDate': 'الرجاء اختيار تاريخ الاستحقاق.',
  'errorPaymentExceedsBalance': 'لا يمكن أن يتجاوز السداد الرصيد المتبقي.',
  'errorSomethingWentWrong': 'حدث خطأ ما. الرجاء المحاولة مرة أخرى.',
  'cancel': 'إلغاء',
  'confirm': 'تأكيد',
  'save': 'حفظ',
  'areYouSure': 'هل أنت متأكد؟',
};

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

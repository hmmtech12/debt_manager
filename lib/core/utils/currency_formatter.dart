import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats e.g. 12500.0 + 'AED' -> "AED 12,500.00"
  static String format(double amount, String currencyCode, {String locale = 'en_US'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '$currencyCode ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Compact form for tight UI spaces, e.g. "AED 12.5K"
  static String formatCompact(double amount, String currencyCode) {
    final formatter = NumberFormat.compactCurrency(symbol: '$currencyCode ');
    return formatter.format(amount);
  }
}

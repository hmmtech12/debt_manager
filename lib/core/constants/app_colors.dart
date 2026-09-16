import 'package:flutter/material.dart';

/// Central color palette. Kept small and semantic on purpose:
/// - green  => money owed TO me
/// - orange/red => money I owe / overdue
/// - blue   => neutral / informational
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0F6E5C); // deep teal-green
  static const Color primaryLight = Color(0xFF3FA98A);
  static const Color primaryDark = Color(0xFF0A4A3E);

  // Semantic
  static const Color owedToMe = Color(0xFF1E9E6B); // green
  static const Color iOwe = Color(0xFFE0733E); // orange
  static const Color overdue = Color(0xFFD64545); // red
  static const Color neutral = Color(0xFF3B6EA5); // blue
  static const Color paid = Color(0xFF2FA84F);
  static const Color partiallyPaid = Color(0xFFCB9A1E);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF6F8F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE7ECEA);

  // Dark surfaces (not a simple invert — tuned for contrast)
  static const Color darkBackground = Color(0xFF101513);
  static const Color darkSurface = Color(0xFF1A211E);
  static const Color darkCardBorder = Color(0xFF2A332F);

  static const Color textPrimaryLight = Color(0xFF14201C);
  static const Color textSecondaryLight = Color(0xFF5C6B65);
  static const Color textPrimaryDark = Color(0xFFEAF2EF);
  static const Color textSecondaryDark = Color(0xFFA3B3AC);

  static Color statusColor(String status) {
    switch (status) {
      case 'PAID':
        return paid;
      case 'PARTIALLY_PAID':
        return partiallyPaid;
      case 'OVERDUE':
        return overdue;
      case 'OUTSTANDING':
      default:
        return neutral;
    }
  }
}

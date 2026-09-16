import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/add_debt/add_debt_screen.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/calendar/calendar_screen.dart';
import 'presentation/screens/debt_details/debt_details_screen.dart';
import 'presentation/screens/debts/debts_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/record_payment/record_payment_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

/// Tabs that live inside the persistent bottom navigation shell.
const _shellTabs = ['/home', '/debts', '/calendar', '/reports', '/settings'];

int _indexForLocation(String location) {
  for (int i = 0; i < _shellTabs.length; i++) {
    if (location.startsWith(_shellTabs[i])) return i;
  }
  return 0;
}

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),

    // Full-screen (non-shell) flows, pushed above the shell.
    GoRoute(path: '/add-debt', builder: (context, state) => const AddDebtScreen()),
    GoRoute(
      path: '/debt/:id',
      builder: (context, state) => DebtDetailsScreen(debtId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/debt/:id/record-payment',
      builder: (context, state) => RecordPaymentScreen(debtId: state.pathParameters['id']!),
    ),

    // Shell (bottom-nav) routes.
    ShellRoute(
      builder: (context, state, child) {
        final index = _indexForLocation(state.matchedLocation);
        return AppShell(
          currentIndex: index,
          onTap: (i) => context.go(_shellTabs[i]),
          child: child,
        );
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/debts',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'] == 'pay' ? 'pay' : 'receive';
            return DebtsScreen(initialTab: tab);
          },
        ),
        GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
        GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
    ),
  ],
);

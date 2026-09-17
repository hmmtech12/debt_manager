import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/debt_providers.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/screens/lock/lock_screen.dart';

void main() {
  runApp(const ProviderScope(child: ShariahDebtManagerApp()));
}

class ShariahDebtManagerApp extends ConsumerStatefulWidget {
  const ShariahDebtManagerApp({super.key});

  @override
  ConsumerState<ShariahDebtManagerApp> createState() => _ShariahDebtManagerAppState();
}

class _ShariahDebtManagerAppState extends ConsumerState<ShariahDebtManagerApp> {
  @override
  void initState() {
    super.initState();
    // Demo/sample data only ever seeds an EMPTY database, and is clearly
    // separate from anything the user enters — see seedDemoData().
    Future.microtask(() => ref.read(debtsProvider.notifier).seedDemoDataIfEmpty());
    NotificationService.instance.init();
    _checkAppLock();
  }

  /// A PIN, once set, lives in secure storage and survives app restarts —
  /// but `appLockEnabledProvider` (and `biometricEnabledProvider`) are
  /// just in-memory Riverpod state, so on a cold start we re-derive both
  /// from storage itself rather than trusting their defaults (false).
  Future<void> _checkAppLock() async {
    final hasPin = await AuthService.instance.hasPinSet();
    final biometricEnabled = hasPin && await AuthService.instance.isBiometricEnabled();
    if (!mounted) return;
    ref.read(appLockEnabledProvider.notifier).state = hasPin;
    ref.read(biometricEnabledProvider.notifier).state = biometricEnabled;
    ref.read(isAppLockedProvider.notifier).state = hasPin;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final AppThemeMode appThemeMode = ref.watch(themeModeProvider);
    final isLocked = ref.watch(isAppLockedProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mapThemeMode(appThemeMode),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Enforce RTL layout automatically for Arabic, LTR otherwise.
        return Directionality(
          textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: isLocked
              ? LockScreen(onUnlocked: () => ref.read(isAppLockedProvider.notifier).state = false)
              : child!,
        );
      },
      routerConfig: appRouter,
    );
  }
}

/// Plain if/else on purpose — no pattern-matching switch expression —
/// so this never depends on Dart's switch-exhaustiveness checking.
ThemeMode _mapThemeMode(AppThemeMode mode) {
  if (mode == AppThemeMode.light) return ThemeMode.light;
  if (mode == AppThemeMode.dark) return ThemeMode.dark;
  return ThemeMode.system;
}
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/notification_service.dart';
import '../../providers/debt_providers.dart';
import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Text(l10n.areYouSure),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.overdue),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(debtsProvider.notifier).deleteAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteAllData)));
      }
    }
  }

  /// Prompts for a 4-digit PIN twice (set + confirm) and stores its hash
  /// via [AuthService]. Returns true only if a PIN was successfully set.
  Future<bool> _promptSetPin(BuildContext context) async {
    final firstCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Set a 4-digit PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'New PIN', counterText: ''),
              ),
              TextField(
                controller: confirmCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Confirm PIN', counterText: ''),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.overdue, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (firstCtrl.text.length != 4) {
                  setState(() => error = 'PIN must be 4 digits');
                  return;
                }
                if (firstCtrl.text != confirmCtrl.text) {
                  setState(() => error = 'PINs do not match');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await AuthService.instance.setPin(firstCtrl.text);
      return true;
    }
    return false;
  }

  Future<void> _onToggleAppLock(BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      final pinSet = await _promptSetPin(context);
      if (pinSet) {
        ref.read(appLockEnabledProvider.notifier).state = true;
      }
    } else {
      await AuthService.instance.clearPin();
      ref.read(appLockEnabledProvider.notifier).state = false;
      ref.read(biometricEnabledProvider.notifier).state = false;
    }
  }

  Future<void> _onToggleBiometric(BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      final available = await AuthService.instance.isBiometricAvailable();
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication is not available on this device.')),
          );
        }
        return;
      }
    }
    ref.read(biometricEnabledProvider.notifier).state = enable;
  }

  Future<void> _onToggleReminders(WidgetRef ref, bool enable) async {
    if (enable) {
      await NotificationService.instance.requestPermission();
    }
    ref.read(remindersEnabledProvider.notifier).state = enable;
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final debts = ref.read(debtsProvider).valueOrNull ?? [];
    if (debts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noDebtsYet)));
      return;
    }
    try {
      final result = await ExportService.exportCsv(debts);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), duration: const Duration(seconds: 6)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSomethingWentWrong)));
      }
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    try {
      final rows = await ImportService.pickAndParseCsv();
      if (rows == null) return; // person cancelled the file picker

      final count = await ref.read(debtsProvider.notifier).importCsvRows(rows);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0 ? 'Imported $count debt${count == 1 ? '' : 's'}' : 'No valid rows found in that file'),
          duration: const Duration(seconds: 5),
        ),
      );
    } on UnsupportedError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Not available yet')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSomethingWentWrong)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currency = ref.watch(defaultCurrencyProvider);
    final appLockEnabled = ref.watch(appLockEnabledProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SectionLabel(l10n.appearance),
          _SettingsCard(children: [
            _RadioTile<AppThemeMode>(
              title: l10n.light,
              value: AppThemeMode.light,
              groupValue: themeMode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!),
            ),
            _RadioTile<AppThemeMode>(
              title: l10n.darkMode,
              value: AppThemeMode.dark,
              groupValue: themeMode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!),
            ),
            _RadioTile<AppThemeMode>(
              title: l10n.systemDefault,
              value: AppThemeMode.system,
              groupValue: themeMode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!),
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 20),
          _SectionLabel(l10n.language),
          _SettingsCard(children: [
            _RadioTile<String>(
              title: 'English',
              value: 'en',
              groupValue: locale.languageCode,
              onChanged: (v) => ref.read(localeProvider.notifier).setLocale(const Locale('en')),
            ),
            _RadioTile<String>(
              title: 'العربية',
              value: 'ar',
              groupValue: locale.languageCode,
              onChanged: (v) => ref.read(localeProvider.notifier).setLocale(const Locale('ar')),
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 20),
          _SectionLabel(l10n.profile),
          _SettingsCard(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.defaultCurrency),
              trailing: DropdownButton<String>(
                value: currency,
                underline: const SizedBox.shrink(),
                items: AppConstants.currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) ref.read(defaultCurrencyProvider.notifier).state = v;
                },
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _SectionLabel(l10n.notifications),
          _SettingsCard(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.enableReminders),
              subtitle: const Text('Notification alerts aren\'t available in this build — reminders still save'),
              value: false,
              onChanged: null,
            ),
          ]),
          const SizedBox(height: 20),
          _SectionLabel(l10n.security),
          _SettingsCard(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.appLock),
              value: appLockEnabled,
              onChanged: (v) => _onToggleAppLock(context, ref, v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.biometricUnlock),
              subtitle: const Text('Not available in this build — use your PIN'),
              value: biometricEnabled,
              onChanged: null,
            ),
          ]),
          const SizedBox(height: 20),
          _SectionLabel(l10n.data),
          _SettingsCard(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_upload_outlined),
              title: Text(l10n.exportData),
              subtitle: const Text('CSV, all debts'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _exportCsv(context, ref, l10n),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_download_outlined),
              title: Text(l10n.importData),
              subtitle: const Text('From a CSV exported by this app'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _importCsv(context, ref, l10n),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup_outlined),
              title: Text(l10n.backup),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_forever_outlined, color: AppColors.overdue),
              title: Text(l10n.deleteAllData, style: const TextStyle(color: AppColors.overdue)),
              onTap: () => _confirmDeleteAll(context, ref, l10n),
            ),
          ]),
          const SizedBox(height: 20),
          _SectionLabel(l10n.about),
          _SettingsCard(children: [
            ListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.privacyPolicy), onTap: () {}),
            const Divider(height: 1),
            ListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.terms), onTap: () {}),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shariahDisclaimer),
              onTap: () => _showDisclaimer(context, l10n),
            ),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppConstants.shariahDisclaimer,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDisclaimer(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.shariahDisclaimer),
        content: SingleChildScrollView(
          child: Text('${AppConstants.shariahDisclaimer}\n\n${AppConstants.qardHasanNote}'),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.confirm))],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final bool showDivider;

  const _RadioTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile<T>(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import '../../providers/settings_providers.dart';

/// Full-screen PIN pad shown before the app content when app-lock is
/// enabled. Also offers biometric unlock (device Face/Touch ID or
/// fingerprint) as a faster path when available and enabled.
class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entered = '';
  String? _error;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    // Offer biometric unlock immediately on open, if enabled.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (!ref.read(biometricEnabledProvider)) return;
    setState(() => _checkingBiometric = true);
    final ok = await AuthService.instance.authenticateWithBiometrics();
    if (mounted) setState(() => _checkingBiometric = false);
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= 6) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == 4) {
      final valid = await AuthService.instance.verifyPin(_entered);
      if (valid) {
        widget.onUnlocked();
      } else {
        setState(() {
          _error = 'Incorrect PIN';
          _entered = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final biometricEnabled = ref.watch(biometricEnabledProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 40, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(l10n.appLock, style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : Colors.transparent,
                    border: Border.all(color: AppColors.primary, width: 1.4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: _error != null
                  ? Text(_error!, style: const TextStyle(color: AppColors.overdue))
                  : (_checkingBiometric ? const Text('Checking biometrics…') : null),
            ),
            const SizedBox(height: 24),
            _NumberPad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              showBiometric: biometricEnabled,
              onBiometric: _tryBiometric,
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool showBiometric;
  final VoidCallback onBiometric;

  const _NumberPad({
    required this.onDigit,
    required this.onBackspace,
    required this.showBiometric,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((d) => _PadButton(label: d, onTap: () => onDigit(d))).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showBiometric)
              _PadButton(icon: Icons.fingerprint_rounded, onTap: onBiometric)
            else
              const SizedBox(width: 72, height: 72),
            _PadButton(label: '0', onTap: () => onDigit('0')),
            _PadButton(icon: Icons.backspace_outlined, onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  const _PadButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: label != null
                ? Text(label!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600))
                : Icon(icon, size: 22),
          ),
        ),
      ),
    );
  }
}

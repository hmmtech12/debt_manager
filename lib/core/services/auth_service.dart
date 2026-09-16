import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles the app-lock PIN. The PIN itself is never stored in
/// plaintext — only its salted hash goes into secure storage, which on
/// Android backs onto the Keystore, on iOS the Keychain, on desktop the
/// OS credential store, and on web the browser's own encrypted storage.
/// PIN lock therefore works everywhere.
///
/// Biometric unlock (`local_auth`) was deliberately removed: its Windows
/// implementation pulls in a NuGet package at build time, which fails on
/// machines without unrestricted internet/firewall access to nuget.org —
/// a bad trade-off for a "nice to have" unlock shortcut. [isBiometricAvailable]
/// always returns false, so the UI falls back to the PIN pad everywhere;
/// re-adding `local_auth` later is a self-contained change confined to
/// this file plus the Settings toggle.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const _pinHashKey = 'app_lock_pin_hash';
  static const _pinSaltKey = 'app_lock_pin_salt';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> hasPinSet() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = _hash(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final storedHash = await _storage.read(key: _pinHashKey);
    if (salt == null || storedHash == null) return false;
    return _hash(pin, salt) == storedHash;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt::$pin');
    return sha256.convert(bytes).toString();
  }

  // ---------------- Biometrics (disabled — see class doc) ----------------

  Future<bool> isBiometricAvailable() async => false;

  Future<bool> authenticateWithBiometrics({String reason = 'Unlock Debt Manager'}) async => false;
}

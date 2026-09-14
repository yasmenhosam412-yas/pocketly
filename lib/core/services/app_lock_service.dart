import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService extends ChangeNotifier {
  static const _enabledKey = 'app_lock_enabled';
  static const _biometricKey = 'app_lock_biometric';
  static const _pinHashKey = 'app_lock_pin_hash';
  static const _pinSaltKey = 'app_lock_pin_salt';

  static const pinLength = 4;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _enabled = false;
  bool _biometricEnabled = false;
  bool _isLocked = false;
  bool _loaded = false;
  bool _canUseBiometrics = false;
  List<BiometricType> _availableBiometrics = const [];

  bool get loaded => _loaded;
  bool get isEnabled => _enabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get isLocked => _isLocked;
  bool get canUseBiometrics => _canUseBiometrics;

  bool get supportsFace =>
      _availableBiometrics.contains(BiometricType.face);

  bool get supportsFingerprint =>
      _availableBiometrics.contains(BiometricType.fingerprint) ||
      _availableBiometrics.contains(BiometricType.strong);

  bool shouldGuard(bool isLoggedIn) =>
      isLoggedIn && _enabled && _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _biometricEnabled = prefs.getBool(_biometricKey) ?? false;
    _isLocked = _enabled;
    _loaded = true;
    notifyListeners();

    if (_enabled) {
      unawaited(_ensurePinOrDisable(prefs));
    }
    unawaited(
      _refreshBiometricCapability().then((_) {
        if (_loaded) notifyListeners();
      }),
    );
  }

  Future<void> _ensurePinOrDisable(SharedPreferences prefs) async {
    final hasPin = await _hasPin();
    if (hasPin) return;
    _enabled = false;
    _biometricEnabled = false;
    _isLocked = false;
    await prefs.setBool(_enabledKey, false);
    await prefs.setBool(_biometricKey, false);
    if (_loaded) notifyListeners();
  }

  Future<void> _refreshBiometricCapability() async {
    try {
      _canUseBiometrics = await _localAuth.canCheckBiometrics;
      if (_canUseBiometrics) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
      } else {
        _availableBiometrics = const [];
      }
    } catch (_) {
      _canUseBiometrics = false;
      _availableBiometrics = const [];
    }
  }

  Future<bool> _hasPin() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  void lock() {
    if (!_enabled) return;
    if (_isLocked) return;
    _isLocked = true;
    notifyListeners();
  }

  void unlock() {
    if (!_isLocked) return;
    _isLocked = false;
    notifyListeners();
  }

  void onLoggedOut() {
    _isLocked = false;
    notifyListeners();
  }

  void onAuthenticated() {
    if (_enabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  bool isValidPinFormat(String pin) {
    return RegExp('^\\d{$pinLength}\$').hasMatch(pin);
  }

  Future<bool> verifyPin(String pin) async {
    if (!isValidPinFormat(pin)) return false;
    final stored = await _secureStorage.read(key: _pinHashKey);
    if (stored == null) return false;
    final salt = await _secureStorage.read(key: _pinSaltKey);
    if (salt == null) return false;
    return stored == _hashPin(pin, salt);
  }

  Future<bool> enableLock(String pin) async {
    if (!isValidPinFormat(pin)) return false;

    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);

    final prefs = await SharedPreferences.getInstance();
    _enabled = true;
    _isLocked = false;
    await prefs.setBool(_enabledKey, true);
    notifyListeners();
    return true;
  }

  Future<bool> disableLock(String pin) async {
    if (!await verifyPin(pin)) return false;
    await _clearPinStorage();
    final prefs = await SharedPreferences.getInstance();
    _enabled = false;
    _biometricEnabled = false;
    _isLocked = false;
    await prefs.setBool(_enabledKey, false);
    await prefs.setBool(_biometricKey, false);
    notifyListeners();
    return true;
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!await verifyPin(currentPin)) return false;
    if (!isValidPinFormat(newPin)) return false;

    final salt = _generateSalt();
    final hash = _hashPin(newPin, salt);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    notifyListeners();
    return true;
  }

  Future<bool> setBiometricEnabled(
    bool enabled, {
    required String localizedReason,
  }) async {
    if (enabled) {
      if (!_canUseBiometrics) return false;
      final ok = await authenticate(localizedReason: localizedReason);
      if (!ok) return false;
    }

    _biometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithPin(String pin) async {
    if (!await verifyPin(pin)) return false;
    unlock();
    return true;
  }

  Future<bool> authenticate({required String localizedReason}) async {
    if (!_canUseBiometrics) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithBiometric({required String localizedReason}) async {
    if (!_biometricEnabled || !_canUseBiometrics) return false;
    final ok = await authenticate(localizedReason: localizedReason);
    if (ok) unlock();
    return ok;
  }

  Future<void> _clearPinStorage() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }
}

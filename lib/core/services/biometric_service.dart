import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._internal();
  BiometricService._internal();

  factory BiometricService() => instance;

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _pinKey = 'user_security_pin';
  static const String _pinEnabledKey = 'pin_lock_enabled';
  static const String _biometricEnabledKey = 'biometric_lock_enabled';

  Future<bool> canCheckBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canAuthenticateWithBiometrics() => canCheckBiometrics();

  Future<bool> authenticateWithBiometrics({String reason = 'Buka kunci aplikasi Cashbook'}) async {
    try {
      final isAvailable = await canCheckBiometrics();
      if (!isAvailable) return false;

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Buka kunci aplikasi Cashbook'}) =>
      authenticateWithBiometrics(reason: reason);

  Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _pinKey);
    final enabled = await _storage.read(key: _pinEnabledKey);
    return pin != null && pin.isNotEmpty && enabled != 'false';
  }

  Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin != null && storedPin == enteredPin;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }
}

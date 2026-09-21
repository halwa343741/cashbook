import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._internal();
  BiometricService._internal();

  factory BiometricService() => instance;

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _biometricEnabledKey = 'biometric_lock_enabled';
  static const String _pinKey = 'user_security_pin';
  static const String _pinEnabledKey = 'pin_lock_enabled';

  /// Memeriksa apakah perangkat mendukung autentikasi keamanan (biometrik / PIN / pola / password Android)
  Future<bool> canAuthenticate() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() => canAuthenticate();
  Future<bool> canAuthenticateWithBiometrics() => canAuthenticate();

  /// Menampilkan dialog autentikasi native Android (Fingerprint / Face / PIN / Pola perangkat)
  Future<bool> authenticate({
    String reason = 'Gunakan sidik jari atau PIN Android untuk membuka Cashbook',
  }) async {
    try {
      final available = await canAuthenticate();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // Mengizinkan PIN / Pola / Password bawaan Android
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Gunakan sidik jari atau PIN Android untuk membuka Cashbook',
  }) => authenticate(reason: reason);

  /// Status apakah penguncian aplikasi aktif
  Future<bool> isLockEnabled() async {
    final lockVal = await _storage.read(key: _appLockEnabledKey);
    if (lockVal != null) return lockVal == 'true';

    // Migrasi jika sebelumnya mengaktifkan biometrik atau PIN versi lama
    final bioVal = await _storage.read(key: _biometricEnabledKey);
    final pinVal = await _storage.read(key: _pinEnabledKey);
    return bioVal == 'true' || pinVal == 'true';
  }

  /// Aktifkan / nonaktifkan kunci aplikasi
  Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(key: _appLockEnabledKey, value: enabled.toString());
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
    // Bersihkan custom PIN lama agar tidak ada residu
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }

  // Kompatibilitas
  Future<bool> isBiometricEnabled() => isLockEnabled();
  Future<void> setBiometricEnabled(bool enabled) => setLockEnabled(enabled);

  // Custom PIN ditiadakan - gunakan PIN bawaan Android
  Future<bool> isPinSet() async => false;
  Future<bool> verifyPin(String enteredPin) async => false;
  Future<void> setPin(String pin) async {}
  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }
}

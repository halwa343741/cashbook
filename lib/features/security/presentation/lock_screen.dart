import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/google_drive_service.dart';

class LockScreen extends StatefulWidget {
  final LocalStorageService storage;
  final BiometricService biometricService;
  final GoogleDriveService driveService;

  const LockScreen({
    super.key,
    required this.storage,
    required this.biometricService,
    required this.driveService,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  static const int _pinLength = 6;
  String? _errorMessage;
  bool _canBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final canBio = await widget.biometricService.canAuthenticateWithBiometrics();
    final bioEnabled = await widget.biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _canBiometric = canBio && bioEnabled;
      });
      if (_canBiometric) {
        _triggerBiometric();
      }
    }
  }

  Future<void> _triggerBiometric() async {
    final success = await widget.biometricService.authenticate();
    if (success && mounted) {
      _unlockSuccess();
    }
  }

  void _onKeyPress(String value) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += value;
        _errorMessage = null;
      });

      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final isValid = await widget.biometricService.verifyPin(_pin);
    if (isValid) {
      _unlockSuccess();
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'PIN Salah. Coba lagi.';
          _pin = '';
        });
      }
    }
  }

  void _unlockSuccess() {
    if (!widget.driveService.isSignedIn) {
      context.go('/login');
    } else {
      final books = widget.storage.getBooks();
      if (books.isEmpty) {
        context.go('/create-initial-book');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(),
              // Icon Lock
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 36,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Masukkan PIN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kunci keamanan Cashbook',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.gray400 : AppColors.gray500,
                ),
              ),
              const SizedBox(height: 32),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  final isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColors.primary500
                          : (isDark ? AppColors.gray700 : AppColors.gray300),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.expenseRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const Spacer(),
              // Keypad
              _buildKeypad(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildKey('${row * 3 + col}', isDark),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _canBiometric
                ? _buildActionButton(
                    icon: Icons.fingerprint_rounded,
                    onTap: _triggerBiometric,
                    isDark: isDark,
                  )
                : const SizedBox(width: 72, height: 72),
            _buildKey('0', isDark),
            _buildActionButton(
              icon: Icons.backspace_outlined,
              onTap: _onDelete,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value, bool isDark) {
    return InkWell(
      onTap: () => _onKeyPress(value),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.gray900,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 28,
          color: isDark ? AppColors.gray300 : AppColors.gray700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  final LocalStorageService storage;
  final BiometricService biometricService;

  const LockScreen({
    super.key,
    required this.storage,
    required this.biometricService,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAuthentication();
    });
  }

  Future<void> _triggerAuthentication() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final success = await widget.biometricService.authenticate(
        reason: 'Buka kunci aplikasi Cashbook',
      );
      if (success && mounted) {
        _unlockSuccess();
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _unlockSuccess() {
    final books = widget.storage.getBooks();
    if (books.isEmpty) {
      context.go('/create-initial-book');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Kunci / Biometrik Android
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 56,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                loc.tr('cashbook_locked'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.gray900,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                loc.tr('unlock_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),

              const Spacer(),

              // Tombol Buka Kunci
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _triggerAuthentication,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_open_rounded, size: 22),
                  label: Text(
                    _isAuthenticating ? loc.tr('checking') : loc.tr('unlock_now'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                loc.tr('tap_unlock_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.gray500 : AppColors.gray400,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

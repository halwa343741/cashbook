import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/services/google_drive_service.dart';

class LoginScreen extends StatefulWidget {
  final GoogleDriveService driveService;
  final LocalStorageService storage;

  const LoginScreen({
    super.key,
    required this.driveService,
    required this.storage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final account = await widget.driveService.signIn();
      if (account != null && mounted) {
        // Try syncing / pulling data from Google Drive
        try {
          await widget.driveService.syncWithDrive(widget.storage);
        } catch (_) {
          // Sync error shouldn't block login if offline
        }

        if (!mounted) return;

        final books = widget.storage.getBooks();
        if (books.isEmpty) {
          context.go('/create-initial-book');
        } else {
          context.go('/home');
        }
      } else if (account == null && mounted) {
        setState(() {
          _errorMessage =
              'Google Sign-In dibatalkan atau SHA-1 belum terdaftar di Google Cloud Console. Anda dapat memilih "Lanjutkan Offline" di bawah.';
        });
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('10') || errStr.contains('sign_in_failed') || errStr.contains('12500')) {
          _errorMessage =
              'Google Sign-In belum terhubung ke Google Cloud Console (SHA-1). Anda bisa langsung masuk dengan tombol "Lanjutkan Offline" di bawah.';
        } else {
          _errorMessage = 'Gagal masuk dengan Google: $e';
        }
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleContinueOffline() {
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App Logo / Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary500.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Selamat Datang di Cashbook',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.gray900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kelola keuangan pribadi atau bisnis Anda secara terorganisir. 100% Gratis, aman, dan tersinkronisasi langsung ke Google Drive pribadi Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const Spacer(flex: 3),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.expenseRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.expenseRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.expenseRed,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                    foregroundColor: isDark ? Colors.white : AppColors.gray800,
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? AppColors.gray700 : AppColors.gray200,
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary500,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                              width: 22,
                              height: 22,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Masuk dengan Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Continue Offline / Local Mode Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleContinueOffline,
                  icon: const Icon(Icons.offline_pin_outlined, size: 20),
                  label: const Text(
                    'Lanjutkan Offline (Mode Lokal)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.primary,
                    side: BorderSide(
                      color: isDark ? AppColors.gray700 : AppColors.primary.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Serverless badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: isDark ? AppColors.gray500 : AppColors.gray400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Privasi terjaga, tanpa server perantara pihak ketiga',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.gray500 : AppColors.gray500,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

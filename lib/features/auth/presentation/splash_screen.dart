import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/biometric_service.dart';

class SplashScreen extends StatefulWidget {
  final LocalStorageService storage;
  final BiometricService biometricService;

  const SplashScreen({
    super.key,
    required this.storage,
    required this.biometricService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // 1. Cek apakah Kunci Aplikasi aktif (Biometrik / PIN Android)
    final isLocked = await widget.biometricService.isLockEnabled();
    if (!mounted) return;

    if (isLocked) {
      context.go('/lock');
      return;
    }

    // 2. Tidak ada kunci aktif → cek data lokal
    _proceedToApp();
  }

  void _proceedToApp() {
    final books = widget.storage.getBooks();
    if (books.isEmpty) {
      // First-time user → welcome screen
      context.go('/login');
    } else {
      // Returning user → home
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
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary500,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cashbook',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.gray900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.tr('app_tagline'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Created by TRHAH Tech',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: isDark ? AppColors.gray500 : AppColors.gray400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

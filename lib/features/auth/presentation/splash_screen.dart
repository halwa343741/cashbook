import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/google_drive_service.dart';

class SplashScreen extends StatefulWidget {
  final LocalStorageService storage;
  final BiometricService biometricService;
  final GoogleDriveService driveService;

  const SplashScreen({
    super.key,
    required this.storage,
    required this.biometricService,
    required this.driveService,
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

    final isPinEnabled = await widget.biometricService.isPinSet();
    if (!mounted) return;
    if (isPinEnabled) {
      context.go('/lock');
      return;
    }

    _proceedAfterAuth();
  }

  void _proceedAfterAuth() {
    final isSignedIn = widget.driveService.isSignedIn;
    if (!isSignedIn) {
      context.go('/login');
      return;
    }

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 48,
                color: Colors.white,
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
              'Catat Keuangan Cerdas & Aman',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.gray400 : AppColors.gray500,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  final LocalStorageService storage;

  const LoginScreen({
    super.key,
    required this.storage,
  });

  void _handleStart(BuildContext context) {
    context.go('/create-initial-book');
  }

  void _handleRestore(BuildContext context) {
    // TODO: Implement Android SAF file picker to restore backup
    // file_picker: FilePicker.platform.pickFiles(type: FileType.any)
    // -> read file -> LocalStorageService.restoreFromFile() -> /home
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur restore sedang dalam pengembangan.'),
        backgroundColor: AppColors.primary500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App Logo / Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                loc.tr('welcome_title'),
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
                loc.tr('welcome_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const Spacer(flex: 3),
              // Mulai Menggunakan Cashbook Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _handleStart(context),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                  label: Text(
                    loc.tr('get_started'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primary500.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Restore from Backup Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _handleRestore(context),
                  icon: const Icon(Icons.restore_rounded, size: 20),
                  label: Text(
                    loc.tr('restore_from_backup'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.gray800,
                    side: BorderSide(
                      color: isDark ? AppColors.gray700 : AppColors.gray300,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Local & Secure badge
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
                    loc.tr('local_secure_badge'),
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

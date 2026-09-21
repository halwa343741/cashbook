import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/biometric_service.dart';
import '../../book/cubit/book_cubit.dart';
import '../../localization/cubit/locale_cubit.dart';
import '../../theme/cubit/theme_cubit.dart';
import '../../transaction/cubit/transaction_cubit.dart';

class AccountScreen extends StatefulWidget {
  final LocalStorageService storage;
  final BiometricService biometricService;

  const AccountScreen({
    super.key,
    required this.storage,
    required this.biometricService,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isAppLockEnabled = false;
  bool _canAuthenticate = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    final locked = await widget.biometricService.isLockEnabled();
    final canAuth = await widget.biometricService.canAuthenticate();
    if (mounted) {
      setState(() {
        _isAppLockEnabled = locked;
        _canAuthenticate = canAuth;
      });
    }
  }

  /// Backup data ke lokasi pilihan user menggunakan share_plus
  Future<void> _handleBackup() async {
    try {
      // Simpan data terbaru dulu ke file
      await widget.storage.saveToFile();
      final file = await widget.storage.getDataFile();

      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File data tidak ditemukan.'),
              backgroundColor: AppColors.expenseRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      // Buka share sheet Android native (bisa pilih Drive, WA, dll)
      final xFile = XFile(file.path, name: 'data.cashbook', mimeType: 'application/octet-stream');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'Cashbook Backup - data.cashbook',
          text: 'Backup data Cashbook saya',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal backup: $e'),
            backgroundColor: AppColors.expenseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Restore data dari file backup via Android file picker
  Future<void> _handleRestore() async {
    try {
      // Buka Android native file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        dialogTitle: 'Pilih file backup data.cashbook',
      );

      if (result == null || result.files.isEmpty) return;

      final pickedPath = result.files.single.path;
      if (pickedPath == null) return;

      // Konfirmasi restore
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.tr('confirm_restore_title')),
          content: Text(loc.tr('confirm_restore_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.tr('yes_restore'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final success = await widget.storage.restoreFromFile(pickedPath);

      if (!mounted) return;
      if (success) {
        // Reload cubit agar UI langsung update
        context.read<BookCubit>().loadBooks();
        final activeBook = context.read<BookCubit>().activeBook;
        context.read<TransactionCubit>().loadTransactions(activeBook?.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.tr('restore_success_msg')),
            backgroundColor: AppColors.primary500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.tr('restore_failed_msg')),
            backgroundColor: AppColors.expenseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restore: $e'),
            backgroundColor: AppColors.expenseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _toggleAppLock(bool enable) async {
    final reason = enable
        ? 'Konfirmasi sidik jari atau PIN'
        : 'Konfirmasi sidik jari atau PIN';

    final authenticated = await widget.biometricService.authenticate(reason: reason);
    if (!authenticated) {
      if (mounted) {
        _loadSecurityStatus();
      }
      return;
    }

    await widget.biometricService.setLockEnabled(enable);
    if (mounted) {
      _loadSecurityStatus();
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enable
              ? loc.tr('biometric_enabled')
              : loc.tr('biometric_disabled')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showThemeDialog() {
    final currentMode = context.read<ThemeCubit>().state;
    final cubit = context.read<ThemeCubit>();
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.tr('select_app_theme')),
        children: [
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: Text(loc.tr('light_theme')),
            trailing: currentMode == ThemeMode.light
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                : null,
            onTap: () {
              cubit.setThemeMode(ThemeMode.light);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.nightlight_round_outlined),
            title: Text(loc.tr('dark_theme')),
            trailing: currentMode == ThemeMode.dark
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                : null,
            onTap: () {
              cubit.setThemeMode(ThemeMode.dark);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_suggest_outlined),
            title: Text(loc.tr('system_theme')),
            trailing: currentMode == ThemeMode.system
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                : null,
            onTap: () {
              cubit.setThemeMode(ThemeMode.system);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final currentLocale = context.read<LocaleCubit>().state.languageCode;
    final cubit = context.read<LocaleCubit>();
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.tr('select_language')),
        children: [
          ListTile(
            leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
            title: const Text('Bahasa Indonesia'),
            trailing: currentLocale == 'id'
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                : null,
            onTap: () {
              cubit.setLocale('id');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
            title: const Text('English'),
            trailing: currentLocale == 'en'
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                : null,
            onTap: () {
              cubit.setLocale('en');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
            title: const Text('Español'),
            trailing: currentLocale == 'es'
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                : null,
            onTap: () {
              cubit.setLocale('es');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🇨🇳', style: TextStyle(fontSize: 24)),
            title: const Text('简体中文'),
            trailing: currentLocale == 'zh'
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                : null,
            onTap: () {
              cubit.setLocale('zh');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
            title: const Text('العربية'),
            trailing: currentLocale == 'ar'
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                : null,
            onTap: () {
              cubit.setLocale('ar');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutModal(BuildContext context, bool isDark, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.gray700 : AppColors.gray300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Cashbook',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.gray400 : AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  loc.tr('about_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? AppColors.gray300 : AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.gray800 : AppColors.gray200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.code_rounded,
                        size: 16,
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Created by TRHAH Tech',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.gray800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Divider tipis dengan warna yang sesuai tema (tidak kontras)
  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final currentLang = context.watch<LocaleCubit>().state.languageCode;

    String getLanguageName(String code) {
      switch (code) {
        case 'en':
          return 'English';
        case 'es':
          return 'Español';
        case 'zh':
          return '简体中文';
        case 'ar':
          return 'العربية';
        default:
          return 'Bahasa Indonesia';
      }
    }

    final divider = _buildDivider(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(loc.tr('account_settings')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Backup & Restore Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.blue500.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined,
                            color: AppColors.blue500, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.tr('backup_restore_title'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(loc.tr('backup_restore_desc'),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.gray400 : AppColors.gray500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleBackup,
                          icon: const Icon(Icons.upload_rounded, size: 16),
                          label: Text(loc.tr('backup'), style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            side: BorderSide(
                              color: isDark ? AppColors.gray700 : AppColors.gray300,
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleRestore,
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: Text(loc.tr('restore'), style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            side: BorderSide(
                              color: isDark ? AppColors.gray700 : AppColors.gray300,
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Navigation Sections (Kelola Buku, Kategori, Import, Trash)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.menu_book_rounded, color: AppColors.primary500),
                    title: Text(loc.tr('manage_books')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/manage-books'),
                  ),
                  divider,
                  ListTile(
                    leading: const Icon(Icons.category_rounded, color: AppColors.amber500),
                    title: Text(loc.tr('manage_categories')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/categories'),
                  ),

                  divider,
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed),
                    title: Text(loc.tr('trash_menu')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/trash'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Security & App Settings
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: Text(loc.tr('language')),
                    subtitle: Text(
                      getLanguageName(currentLang),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showLanguageDialog,
                  ),
                  divider,
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: Text(loc.tr('app_theme')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showThemeDialog,
                  ),
                  divider,
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded),
                    title: Text(loc.tr('app_lock_title')),
                    subtitle: Text(
                      _isAppLockEnabled
                          ? loc.tr('app_lock_active')
                          : loc.tr('app_lock_inactive'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _isAppLockEnabled,
                    onChanged: _canAuthenticate ? _toggleAppLock : null,
                  ),
                  divider,
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(loc.tr('about_cashbook')),
                    subtitle: const Text(
                      'v1.0.0 • TRHAH Tech',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showAboutModal(context, isDark, loc),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Cashbook v1.0.0 • 100% Free & Serverless',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.gray500 : AppColors.gray400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Created by TRHAH Tech',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: isDark ? AppColors.gray500 : AppColors.gray400,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

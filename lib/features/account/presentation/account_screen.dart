import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/services/share_service.dart';
import '../../book/cubit/book_cubit.dart';
import '../../localization/cubit/locale_cubit.dart';
import '../../theme/cubit/theme_cubit.dart';
import '../../transaction/cubit/transaction_cubit.dart';

class AccountScreen extends StatefulWidget {
  final GoogleDriveService driveService;
  final LocalStorageService storage;
  final BiometricService biometricService;
  final ShareService shareService;

  const AccountScreen({
    super.key,
    required this.driveService,
    required this.storage,
    required this.biometricService,
    required this.shareService,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isPinSet = false;
  bool _isBiometricEnabled = false;
  bool _canUseBiometrics = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    final pin = await widget.biometricService.isPinSet();
    final bio = await widget.biometricService.isBiometricEnabled();
    final canBio = await widget.biometricService.canAuthenticateWithBiometrics();
    if (mounted) {
      setState(() {
        _isPinSet = pin;
        _isBiometricEnabled = bio;
        _canUseBiometrics = canBio;
      });
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      final success = await widget.driveService.syncWithDrive(widget.storage);
      if (mounted) {
        final activeBook = context.read<BookCubit>().activeBook;
        context.read<TransactionCubit>().loadTransactions(activeBook?.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Data berhasil disinkronkan ke Google Drive!'
                : 'Sinkronisasi gagal, periksa koneksi internet.'),
            backgroundColor: success ? AppColors.primary500 : AppColors.expenseRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expenseRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showSetPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur PIN Keamanan (6 Digit)'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Masukkan 6 digit angka',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 6) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await widget.biometricService.setPin(pin);
                if (mounted) {
                  nav.pop();
                  _loadSecurityStatus();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('PIN berhasil diatur')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    final currentMode = context.read<ThemeCubit>().state;
    final cubit = context.read<ThemeCubit>();
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Tema Aplikasi'),
        children: [
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Terang (Light)'),
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
            title: const Text('Gelap (Dark)'),
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
            title: const Text('Ikuti Sistem'),
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

  Future<void> _handleImportBook() async {
    final bookCubit = context.read<BookCubit>();
    final txCubit = context.read<TransactionCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final book = await widget.shareService.pickAndImportSharedBook();
    if (book != null && mounted) {
      bookCubit.loadBooks();
      bookCubit.selectBook(book.id);
      txCubit.loadTransactions(book.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Buku "${book.name}" (Read-Only) berhasil diimpor!'),
          backgroundColor: AppColors.primary500,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await widget.driveService.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.driveService.currentUser;
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(loc.tr('account_settings')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary500.withValues(alpha: 0.15),
                    backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person_rounded, size: 32, color: AppColors.primary500)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Cashbook User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'Offline Mode',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.gray400 : AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cloud Drive Sync Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.blue500.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_done_rounded,
                            color: AppColors.blue500, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.tr('drive_sync_title'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(loc.tr('drive_sync_desc'),
                                style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _isSyncing ? null : _syncNow,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: _isSyncing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(loc.tr('sync_now'), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Navigation Sections
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.category_rounded, color: AppColors.amber500),
                    title: Text(loc.tr('manage_categories')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/categories'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined, color: AppColors.blue500),
                    title: Text(loc.tr('import_cbshare')),
                    subtitle: Text(loc.tr('import_cbshare_sub')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _handleImportBook,
                  ),
                  const Divider(height: 1),
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: Text(loc.tr('app_theme')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showThemeDialog,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline_rounded),
                    title: Text(loc.tr('pin_security')),
                    subtitle: Text(_isPinSet ? 'PIN ON' : 'PIN OFF'),
                    value: _isPinSet,
                    onChanged: (val) {
                      if (val) {
                        _showSetPinDialog();
                      } else {
                        widget.biometricService.removePin();
                        _loadSecurityStatus();
                      }
                    },
                  ),
                  if (_canUseBiometrics) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded),
                      title: Text(loc.tr('biometric_security')),
                      subtitle: const Text('Touch ID / Face ID'),
                      value: _isBiometricEnabled,
                      onChanged: (val) async {
                        await widget.biometricService.setBiometricEnabled(val);
                        _loadSecurityStatus();
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout_rounded, color: AppColors.expenseRed),
                label: Text(loc.tr('logout'),
                    style: const TextStyle(color: AppColors.expenseRed, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.expenseRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Cashbook v1.0.0 • 100% Free & Serverless',
              style: TextStyle(
                fontSize: 12,
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

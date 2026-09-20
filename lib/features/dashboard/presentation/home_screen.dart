import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../../book/presentation/widgets/book_dropdown_selector.dart';
import '../../transaction/cubit/transaction_cubit.dart';
import '../../transaction/domain/models/transaction_model.dart';

class HomeScreen extends StatefulWidget {
  final GoogleDriveService driveService;
  final LocalStorageService storage;

  const HomeScreen({
    super.key,
    required this.driveService,
    required this.storage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBalance = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final activeBook = context.read<BookCubit>().activeBook;
    context.read<TransactionCubit>().loadTransactions(activeBook?.id);
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      final success = await widget.driveService.syncWithDrive(widget.storage);
      if (mounted) {
        _refreshData();
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
          SnackBar(
            content: Text('Sinkronisasi gagal: $e'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'salary':
      case 'in_salary':
        return Icons.account_balance_wallet_rounded;
      case 'business':
      case 'in_business':
        return Icons.storefront_rounded;
      case 'investment':
      case 'in_invest':
        return Icons.trending_up_rounded;
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'food':
      case 'ex_food':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'ex_transport':
        return Icons.directions_car_rounded;
      case 'shopping':
      case 'ex_shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
      case 'ex_bills':
        return Icons.receipt_long_rounded;
      case 'health':
      case 'ex_health':
        return Icons.medical_services_rounded;
      case 'entertainment':
      case 'ex_entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.monetization_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<BookCubit, BookState>(
      listener: (context, state) {
        if (state is BookLoaded) {
          context.read<TransactionCubit>().loadTransactions(state.activeBookId);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _refreshData();
            },
            color: AppColors.primary500,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo & App Name
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Cashbook',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.gray900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      // Actions: Sync to Google Drive
                      Row(
                        children: [
                          IconButton(
                            onPressed: _isSyncing ? null : _handleSync,
                            icon: _isSyncing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_sync_outlined),
                            tooltip: 'Sinkronkan ke Google Drive',
                          ),
                          IconButton(
                            onPressed: () => context.push('/trash'),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Sampah (Trash)',
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 2. BOOKS DROPDOWN SWITCHER (Immediately Below Logo)
                  const SizedBox(height: 12),
                  const BookDropdownSelector(),
                  const SizedBox(height: 16),

                  // Read-Only Banner if active book is read-only
                  BlocBuilder<BookCubit, BookState>(
                    builder: (context, state) {
                      if (state is BookLoaded && state.activeBook?.isReadOnly == true) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.amber500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.amber500.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded,
                                  color: AppColors.amber500, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Buku ini bersifat Read-Only (Hanya Baca). Anda tidak dapat menambah atau mengubah transaksi.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.amber[200] : Colors.amber[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // 3. BALANCE CARD
                  BlocBuilder<TransactionCubit, TransactionState>(
                    builder: (context, state) {
                      double balance = 0;
                      double income = 0;
                      double expense = 0;
                      if (state is TransactionLoaded) {
                        balance = state.balance;
                        income = state.totalIncome;
                        expense = state.totalExpense;
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF047857), // Emerald 700
                              Color(0xFF10B981), // Emerald 500
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary500.withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Saldo Kas',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showBalance = !_showBalance;
                                    });
                                  },
                                  child: Icon(
                                    _showBalance
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showBalance
                                  ? CurrencyFormatter.formatRupiah(balance)
                                  : 'Rp ••••••••',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_downward_rounded,
                                              size: 14, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Masuk',
                                                  style: TextStyle(
                                                      color: Colors.white70, fontSize: 11)),
                                              Text(
                                                _showBalance
                                                    ? CurrencyFormatter.formatRupiah(income)
                                                    : '••••',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: Colors.white.withValues(alpha: 0.2),
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_upward_rounded,
                                              size: 14, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Keluar',
                                                  style: TextStyle(
                                                      color: Colors.white70, fontSize: 11)),
                                              Text(
                                                _showBalance
                                                    ? CurrencyFormatter.formatRupiah(expense)
                                                    : '••••',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 4. QUICK ACTIONS
                  BlocBuilder<BookCubit, BookState>(
                    builder: (context, state) {
                      final isReadOnly =
                          state is BookLoaded && state.activeBook?.isReadOnly == true;

                      return Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              title: 'Pemasukan',
                              icon: Icons.add_rounded,
                              bgColor: AppColors.incomeGreen.withValues(alpha: 0.12),
                              iconColor: AppColors.incomeGreen,
                              onTap: isReadOnly
                                  ? () => _showReadOnlyToast()
                                  : () => context.push('/add-income'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              title: 'Pengeluaran',
                              icon: Icons.remove_rounded,
                              bgColor: AppColors.expenseRed.withValues(alpha: 0.12),
                              iconColor: AppColors.expenseRed,
                              onTap: isReadOnly
                                  ? () => _showReadOnlyToast()
                                  : () => context.push('/add-expense'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              title: 'Kelola Buku',
                              icon: Icons.menu_book_rounded,
                              bgColor: AppColors.blue500.withValues(alpha: 0.12),
                              iconColor: AppColors.blue500,
                              onTap: () => context.push('/manage-books'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // 5. TRANSAKSI TERBARU
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaksi Terakhir',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/transactions'),
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  BlocBuilder<TransactionCubit, TransactionState>(
                    builder: (context, state) {
                      if (state is TransactionLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (state is TransactionLoaded) {
                        final transactions = state.transactions;
                        if (transactions.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_outlined,
                                    size: 48,
                                    color: isDark ? AppColors.gray600 : AppColors.gray300),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada transaksi di buku ini',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.gray300 : AppColors.gray700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tekan Pemasukan atau Pengeluaran untuk mencatat transaksi',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.gray500 : AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final recent = transactions.take(6).toList();
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recent.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final tx = recent[index];
                            return _buildTransactionTile(context, tx, isDark);
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReadOnlyToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buku ini Read-Only. Tidak dapat menambah transaksi.'),
        backgroundColor: AppColors.amber500,
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.gray800 : AppColors.gray100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.gray800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel tx, bool isDark) {
    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return InkWell(
      onTap: () => context.push('/transaction-detail/${tx.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getCategoryIcon(tx.categoryId), color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.categoryName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.note.isNotEmpty
                        ? tx.note
                        : DateFormatter.formatIndonesian(tx.transactionDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatRupiah(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../cubit/transaction_cubit.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;
  final LocalStorageService storage;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = storage.getTransactionById(transactionId);

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const Center(child: Text('Transaksi tidak ditemukan')),
      );
    }

    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    final activeBook = context.read<BookCubit>().activeBook;
    final isReadOnly = activeBook?.isReadOnly ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed),
              tooltip: 'Hapus ke Sampah',
              onPressed: () {
                _confirmDelete(context);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isIncome ? 'Pemasukan' : 'Pengeluaran',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatRupiah(tx.amount)}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.formatIndonesian(tx.transactionDate),
                    style: TextStyle(
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detail Fields
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context: context,
                    icon: Icons.category_outlined,
                    label: 'Kategori',
                    value: tx.categoryName,
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context: context,
                    icon: Icons.notes_rounded,
                    label: 'Catatan',
                    value: tx.note.isNotEmpty ? tx.note : '-',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Waktu Pencatatan',
                    value:
                        '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year} ${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text(
          'Transaksi ini akan dipindahkan ke Sampah (Trash) dan dapat dipulihkan kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionCubit>().softDeleteTransaction(transactionId);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: const Text('Pindahkan ke Sampah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.gray400 : AppColors.gray500),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.gray400 : AppColors.gray600,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.gray900,
            ),
          ),
        ),
      ],
    );
  }
}

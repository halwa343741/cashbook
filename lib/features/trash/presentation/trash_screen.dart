import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../../transaction/cubit/transaction_cubit.dart';

class TrashScreen extends StatefulWidget {
  final LocalStorageService storage;

  const TrashScreen({
    super.key,
    required this.storage,
  });

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _restoreBook(String id) {
    context.read<BookCubit>().restoreBook(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buku kas berhasil dipulihkan')),
    );
  }

  void _purgeBook(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: const Text(
          'Buku kas beserta seluruh transaksinya akan dihapus secara permanen dan tidak dapat dipulihkan kembali.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BookCubit>().purgeBook(id);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _restoreTransaction(String id) {
    context.read<TransactionCubit>().restoreTransaction(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil dipulihkan')),
    );
  }

  void _purgeTransaction(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: const Text(
          'Transaksi ini akan dihapus secara permanen dari database.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionCubit>().purgeTransaction(id);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedBooks(bool isDark) {
    final deletedBooks = widget.storage.getDeletedBooks();

    if (deletedBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_outlined,
                size: 64, color: isDark ? AppColors.gray600 : AppColors.gray400),
            const SizedBox(height: 12),
            Text(
              'Sampah buku kas kosong',
              style: TextStyle(
                color: isDark ? AppColors.gray400 : AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: deletedBooks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = deletedBooks[index];
        final color = Color(int.parse(book.color.replaceFirst('#', '0xFF')));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.gray800 : AppColors.gray200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: color, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      book.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.gray900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (book.deletedAt != null)
                Text(
                  'Dihapus pada: ${DateFormatter.formatIndonesian(book.deletedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.gray400 : AppColors.gray500,
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _purgeBook(book.id),
                    icon: const Icon(Icons.delete_forever_rounded,
                        size: 16, color: AppColors.expenseRed),
                    label: const Text('Hapus Permanen',
                        style: TextStyle(color: AppColors.expenseRed, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _restoreBook(book.id),
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Pulihkan', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeletedTransactions(bool isDark) {
    final deletedTx = widget.storage.getDeletedTransactions();

    if (deletedTx.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_outlined,
                size: 64, color: isDark ? AppColors.gray600 : AppColors.gray400),
            const SizedBox(height: 12),
            Text(
              'Sampah transaksi kosong',
              style: TextStyle(
                color: isDark ? AppColors.gray400 : AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: deletedTx.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = deletedTx[index];
        final isIncome = tx.isIncome;
        final color = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.gray800 : AppColors.gray200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tx.categoryName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.gray900,
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatRupiah(tx.amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              if (tx.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  tx.note,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.gray300 : AppColors.gray700,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              if (tx.deletedAt != null)
                Text(
                  'Dihapus: ${DateFormatter.formatIndonesian(tx.deletedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.gray500 : AppColors.gray400,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _purgeTransaction(tx.id),
                    icon: const Icon(Icons.delete_forever_rounded,
                        size: 16, color: AppColors.expenseRed),
                    label: const Text('Hapus Permanen',
                        style: TextStyle(color: AppColors.expenseRed, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _restoreTransaction(tx.id),
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Pulihkan', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Sampah (Trash)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary500,
          labelColor: AppColors.primary500,
          unselectedLabelColor: isDark ? AppColors.gray400 : AppColors.gray600,
          tabs: const [
            Tab(text: 'Buku Kas'),
            Tab(text: 'Transaksi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeletedBooks(isDark),
          _buildDeletedTransactions(isDark),
        ],
      ),
    );
  }
}

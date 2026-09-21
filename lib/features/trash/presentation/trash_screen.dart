import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
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

  void _restoreBook(String id, AppLocalizations loc) {
    context.read<BookCubit>().restoreBook(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.tr('restore_success'))),
    );
  }

  void _purgeBook(String id, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('delete_permanent')),
        content: Text(loc.tr('delete_permanent_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BookCubit>().purgeBook(id);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: Text(loc.tr('delete_permanent'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _restoreTransaction(String id, AppLocalizations loc) {
    context.read<TransactionCubit>().restoreTransaction(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.tr('restore_success'))),
    );
  }

  void _purgeTransaction(String id, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('delete_permanent')),
        content: Text(loc.tr('delete_permanent_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionCubit>().purgeTransaction(id);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: Text(loc.tr('delete_permanent'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _emptyTrash(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('empty_trash')),
        content: Text(loc.tr('empty_trash_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final bookCubit = context.read<BookCubit>();
              final txCubit = context.read<TransactionCubit>();
              final messenger = ScaffoldMessenger.of(context);
              await bookCubit.emptyTrash();
              await txCubit.emptyTrash();
              if (mounted) {
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(content: Text(loc.tr('empty_trash_success'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: Text(loc.tr('empty_trash'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedBooks(bool isDark, AppLocalizations loc, String localeCode) {
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
              loc.tr('empty_trash_cashbooks'),
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
                  DateFormatter.formatWithTime(book.deletedAt!, localeCode),
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
                    onPressed: () => _purgeBook(book.id, loc),
                    icon: const Icon(Icons.delete_forever_rounded,
                        size: 16, color: AppColors.expenseRed),
                    label: Text(loc.tr('delete_permanent'),
                        style: const TextStyle(color: AppColors.expenseRed, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.expenseRed.withValues(alpha: 0.35),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _restoreBook(book.id, loc),
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: Text(loc.tr('restore'), style: const TextStyle(fontSize: 12)),
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

  Widget _buildDeletedTransactions(bool isDark, AppLocalizations loc, String localeCode) {
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
              loc.tr('empty_trash_transactions'),
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
                    CurrencyFormatter.format(
                      tx.amount,
                      showSign: true,
                      isExpense: !isIncome,
                      localeCode: localeCode,
                    ),
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
                  DateFormatter.formatWithTime(tx.deletedAt!, localeCode),
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
                    onPressed: () => _purgeTransaction(tx.id, loc),
                    icon: const Icon(Icons.delete_forever_rounded,
                        size: 16, color: AppColors.expenseRed),
                    label: Text(loc.tr('delete_permanent'),
                        style: const TextStyle(color: AppColors.expenseRed, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.expenseRed.withValues(alpha: 0.35),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _restoreTransaction(tx.id, loc),
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: Text(loc.tr('restore'), style: const TextStyle(fontSize: 12)),
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
    final loc = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(loc.tr('trash_menu')),
        actions: [
          if (widget.storage.getDeletedBooks().isNotEmpty ||
              widget.storage.getDeletedTransactions().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => _emptyTrash(loc),
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.expenseRed, size: 18),
                label: Text(
                  loc.tr('empty_trash'),
                  style: const TextStyle(
                    color: AppColors.expenseRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary500,
          labelColor: AppColors.primary500,
          unselectedLabelColor: isDark ? AppColors.gray400 : AppColors.gray600,
          tabs: [
            Tab(text: loc.tr('tab_cashbooks')),
            Tab(text: loc.tr('tab_transactions')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeletedBooks(isDark, loc, localeCode),
          _buildDeletedTransactions(isDark, loc, localeCode),
        ],
      ),
    );
  }
}

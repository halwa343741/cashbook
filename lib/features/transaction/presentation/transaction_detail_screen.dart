import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../cubit/transaction_cubit.dart';
import '../domain/models/transaction_model.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  final LocalStorageService storage;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    required this.storage,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Future<void> _editTransaction(BuildContext context, TransactionModel tx) async {
    final route = tx.isIncome ? '/add-income' : '/add-expense';
    final result = await context.push(route, extra: tx);
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _confirmDelete(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('delete_to_trash')),
        content: Text(loc.tr('delete_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionCubit>().softDeleteTransaction(widget.transactionId);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: Text(loc.tr('delete_to_trash'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final tx = widget.storage.getTransactionById(widget.transactionId);

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.tr('detail_transaction'))),
        body: Center(child: Text(loc.tr('no_transactions_found'))),
      );
    }

    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    final activeBook = context.read<BookCubit>().activeBook;
    final isReadOnly = activeBook?.isReadOnly ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(loc.tr('detail_transaction')),
        actions: [
          if (!isReadOnly) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: loc.tr('edit'),
              onPressed: () => _editTransaction(context, tx),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed),
              tooltip: loc.tr('delete_to_trash'),
              onPressed: () => _confirmDelete(context, loc),
            ),
          ],
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
                      isIncome ? loc.tr('cash_in') : loc.tr('cash_out'),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    CurrencyFormatter.format(
                      tx.amount,
                      showSign: true,
                      isExpense: !isIncome,
                      localeCode: localeCode,
                    ),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.format(tx.transactionDate, localeCode),
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
                    label: loc.tr('category'),
                    value: tx.categoryName,
                    isDark: isDark,
                  ),
                  Divider(height: 24, color: Theme.of(context).dividerColor),
                  _buildDetailRow(
                    context: context,
                    icon: Icons.notes_rounded,
                    label: loc.tr('notes'),
                    value: tx.note.isNotEmpty ? tx.note : '-',
                    isDark: isDark,
                  ),
                  Divider(height: 24, color: Theme.of(context).dividerColor),
                  _buildDetailRow(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: loc.tr('transaction_date'),
                    value: DateFormatter.formatWithTime(tx.transactionDate, localeCode),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (!isReadOnly)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editTransaction(context, tx),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(loc.tr('edit')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDelete(context, loc),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(loc.tr('delete')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expenseRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
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

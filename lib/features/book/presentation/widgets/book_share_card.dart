import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/book_model.dart';
import '../../../transaction/domain/models/transaction_model.dart';

class BookShareCard extends StatelessWidget {
  final BookModel book;
  final List<TransactionModel> transactions;
  final double balance;
  final bool isDark;
  final String localeCode;

  const BookShareCard({
    super.key,
    required this.book,
    required this.transactions,
    required this.balance,
    required this.isDark,
    required this.localeCode,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'briefcase':
        return Icons.work_rounded;
      case 'store':
        return Icons.storefront_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Locale(localeCode));
    final isRtl = localeCode == 'ar';

    // Compute Income & Expense
    final incomeTx = transactions.where((t) => t.type == TransactionType.income).toList();
    final expenseTx = transactions.where((t) => t.type == TransactionType.expense).toList();

    final totalIncome = incomeTx.fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = expenseTx.fold<double>(0, (sum, t) => sum + t.amount);

    // Group by Description (categoryName) using localized 'Others'
    final incomeGrouped = _groupByDescription(incomeTx, loc);
    final expenseGrouped = _groupByDescription(expenseTx, loc);

    // Theme Colors
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final bookColor = Color(int.parse(book.color.replaceFirst('#', '0xFF')));

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER (Logo + Book Name + Date)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cashbook',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(_getIconData(book.icon), size: 12, color: bookColor),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Text(
                                book.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 11, color: textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        DateFormatter.format(DateTime.now(), localeCode),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 2. HERO TOTAL SALDO CARD
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Text(
                    loc.tr('total_balance').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(balance, localeCode: localeCode),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. TOTAL PEMASUKAN & PENGELUARAN (Side-by-Side Cards)
            Row(
              children: [
                // Pemasukan
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.incomeGreen.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.incomeGreen),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  loc.tr('total_income'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '+ ${CurrencyFormatter.format(totalIncome, localeCode: localeCode)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.incomeGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Pengeluaran
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.25) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.4) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.expenseRed.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.expenseRed),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  loc.tr('total_expense'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '- ${CurrencyFormatter.format(totalExpense, localeCode: localeCode)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.expenseRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. PEMASUKAN PER DESKRIPSI
            _buildGroupedSection(
              title: loc.tr('income_by_category'),
              accentColor: AppColors.incomeGreen,
              items: incomeGrouped,
              totalAmount: totalIncome,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              emptyMessage: loc.tr('no_income_records'),
              isRtl: isRtl,
            ),

            const SizedBox(height: 14),

            // 5. PENGELUARAN PER DESKRIPSI
            _buildGroupedSection(
              title: loc.tr('expense_by_category'),
              accentColor: AppColors.expenseRed,
              items: expenseGrouped,
              totalAmount: totalExpense,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              emptyMessage: loc.tr('no_expense_records'),
              isRtl: isRtl,
            ),

            const SizedBox(height: 16),

            // 6. FOOTER
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: AppColors.primary500.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.tr('share_footer_badge'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedSection({
    required String title,
    required Color accentColor,
    required List<MapEntry<String, double>> items,
    required double totalAmount,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required String emptyMessage,
    required bool isRtl,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: textSecondary,
                ),
              ),
            )
          else
            ...items.map((entry) {
              final ratio = totalAmount > 0 ? (entry.value / totalAmount).clamp(0.0, 1.0) : 0.0;
              final percent = (ratio * 100).toStringAsFixed(0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.format(entry.value, localeCode: localeCode),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($percent%)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 5,
                        width: double.infinity,
                        color: accentColor.withValues(alpha: 0.15),
                        child: FractionallySizedBox(
                          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                          widthFactor: ratio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _groupByDescription(
    List<TransactionModel> txList,
    AppLocalizations loc,
  ) {
    if (txList.isEmpty) return [];

    final othersLabel = loc.tr('others');
    final map = <String, double>{};
    for (final tx in txList) {
      final desc = tx.categoryName.trim().isEmpty ? othersLabel : tx.categoryName.trim();
      map[desc] = (map[desc] ?? 0) + tx.amount;
    }

    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // If more than 5 categories, keep top 4 and aggregate the rest into 'Others'
    if (sorted.length > 5) {
      final top = sorted.take(4).toList();
      final restSum = sorted.skip(4).fold<double>(0, (sum, e) => sum + e.value);
      top.add(MapEntry('$othersLabel (${sorted.length - 4})', restSum));
      return top;
    }

    return sorted;
  }
}

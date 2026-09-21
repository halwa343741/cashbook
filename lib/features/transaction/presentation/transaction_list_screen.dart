import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../cubit/transaction_cubit.dart';
import '../domain/models/transaction_model.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final loc = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(loc.tr('history_transactions')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sticky Top Section: Search Bar, Add Buttons, Filter Tabs
          BlocBuilder<BookCubit, BookState>(
            builder: (context, bookState) {
              final isReadOnly = bookState is BookLoaded && bookState.activeBook?.isReadOnly == true;

              return Container(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: loc.tr('search_placeholder'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.gray800 : AppColors.gray200,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Add Income & Add Expense Buttons Below Search
                    if (!isReadOnly) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/add-income'),
                              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                              label: Text(
                                loc.tr('add_income'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.incomeGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/add-expense'),
                              icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                              label: Text(
                                loc.tr('add_expense'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.expenseRed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Filter Tabs
                    Row(
                      children: [
                        _buildFilterChip('all', loc.tr('all'), isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('income', loc.tr('cash_in'), isDark, AppColors.incomeGreen),
                        const SizedBox(width: 8),
                        _buildFilterChip('expense', loc.tr('cash_out'), isDark, AppColors.expenseRed),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Transactions List
          Expanded(
            child: BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TransactionLoaded) {
                  var list = state.transactions;

                  if (_selectedFilter == 'income') {
                    list = list.where((t) => t.isIncome).toList();
                  } else if (_selectedFilter == 'expense') {
                    list = list.where((t) => t.isExpense).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    list = list.where((t) {
                      return t.categoryName.toLowerCase().contains(_searchQuery) ||
                          t.note.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 56,
                              color: isDark ? AppColors.gray600 : AppColors.gray400),
                          const SizedBox(height: 12),
                          Text(
                            loc.tr('no_transactions_found'),
                            style: TextStyle(
                              color: isDark ? AppColors.gray400 : AppColors.gray600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by formatted date
                  final Map<String, List<TransactionModel>> grouped = {};
                  for (final tx in list) {
                    final key = DateFormatter.formatGroupHeader(tx.transactionDate, localeCode);
                    grouped.putIfAbsent(key, () => []).add(tx);
                  }

                  // Sort transactions within each group by ID descending
                  for (final txList in grouped.values) {
                    txList.sort((a, b) => b.id.compareTo(a.id));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final txList = grouped[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Text(
                              dateKey,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.gray400 : AppColors.gray600,
                              ),
                            ),
                          ),
                          ...txList.map((tx) => _buildTransactionCard(context, tx, isDark, localeCode)),
                        ],
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark, [Color? activeColor]) {
    final isSelected = _selectedFilter == key;
    final color = activeColor ?? AppColors.primary500;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = key);
      },
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.15),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      side: BorderSide(
        color: isSelected
            ? color
            : (isDark ? AppColors.gray800 : AppColors.gray200),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? color : (isDark ? AppColors.gray400 : AppColors.gray600),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx, bool isDark, String localeCode) {
    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.gray800 : AppColors.gray100,
        ),
      ),
      child: ListTile(
        onTap: () => context.push('/transaction-detail/${tx.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getCategoryIcon(tx.categoryId), color: color, size: 22),
        ),
        title: Text(
          tx.categoryName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.gray900,
          ),
        ),
        subtitle: tx.note.isNotEmpty
            ? Text(
                tx.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.gray400 : AppColors.gray500),
              )
            : null,
        trailing: Text(
          CurrencyFormatter.format(
            tx.amount,
            showSign: true,
            isExpense: !isIncome,
            localeCode: localeCode,
          ),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ),
    );
  }
}

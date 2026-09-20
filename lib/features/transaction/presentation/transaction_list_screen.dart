import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../../book/presentation/widgets/book_dropdown_selector.dart';
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: BookDropdownSelector(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Pills & Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari catatan atau kategori...',
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
                // Filter Tabs
                Row(
                  children: [
                    _buildFilterChip('all', 'Semua', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('income', 'Pemasukan', isDark, AppColors.incomeGreen),
                    const SizedBox(width: 8),
                    _buildFilterChip('expense', 'Pengeluaran', isDark, AppColors.expenseRed),
                  ],
                ),
              ],
            ),
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
                            'Tidak ada transaksi ditemukan',
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
                    final key = DateFormatter.formatIndonesian(tx.transactionDate);
                    grouped.putIfAbsent(key, () => []).add(tx);
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
                          ...txList.map((tx) => _buildTransactionCard(context, tx, isDark)),
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
      floatingActionButton: BlocBuilder<BookCubit, BookState>(
        builder: (context, state) {
          final isReadOnly = state is BookLoaded && state.activeBook?.isReadOnly == true;
          if (isReadOnly) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              _showAddOptions(context);
            },
            backgroundColor: AppColors.primary500,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Catat', style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.incomeGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.incomeGreen),
                  ),
                  title: const Text('Tambah Pemasukan',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Gaji, penjualan, dividen, dll'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/add-income');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expenseRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: AppColors.expenseRed),
                  ),
                  title: const Text('Tambah Pengeluaran',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Makan, tagihan, transportasi, belanja'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/add-expense');
                  },
                ),
              ],
            ),
          ),
        );
      },
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
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color : (isDark ? AppColors.gray400 : AppColors.gray700),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx, bool isDark) {
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
          '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatRupiah(tx.amount)}',
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

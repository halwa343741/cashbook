import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../../category/domain/models/category_model.dart';
import '../cubit/transaction_cubit.dart';
import '../domain/models/transaction_model.dart';

class AddIncomeScreen extends StatefulWidget {
  final LocalStorageService storage;

  const AddIncomeScreen({
    super.key,
    required this.storage,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  List<CategoryModel> _categories = [];
  String? _selectedBookId;

  final List<int> _quickAmounts = [50000, 100000, 500000, 1000000, 2500000, 5000000];

  @override
  void initState() {
    super.initState();
    _selectedBookId = context.read<BookCubit>().activeBook?.id;
    _categories = widget.storage.getCategories(type: 'income');
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onQuickAmountTap(int amount) {
    final localeCode = Localizations.localeOf(context).languageCode;
    _amountController.text = CurrencyFormatter.formatNumberOnly(amount.toDouble(), localeCode);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveIncome() {
    final loc = AppLocalizations.of(context);
    final amount = CurrencyFormatter.parseRupiah(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.tr('enter_valid_amount'))),
      );
      return;
    }

    if (_selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.tr('select_book'))),
      );
      return;
    }

    final tx = TransactionModel(
      id: const Uuid().v4(),
      bookId: _selectedBookId!,
      type: 'income',
      amount: amount,
      categoryId: _selectedCategory?.id ?? 'in_other',
      categoryName: _selectedCategory?.name ?? 'Lainnya',
      note: _noteController.text.trim(),
      transactionDate: _selectedDate,
      createdAt: DateTime.now(),
    );

    context.read<TransactionCubit>().addTransaction(tx);
    context.pop();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'briefcase':
        return Icons.work_rounded;
      case 'trending-up':
        return Icons.trending_up_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'coin':
      default:
        return Icons.monetization_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final books = widget.storage.getBooks().where((b) => !b.isReadOnly).toList();
    final loc = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(loc.tr('add_income')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Book Selector
              Text(
                loc.tr('book_name'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.gray700 : AppColors.gray200,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedBookId,
                    items: books.map((b) {
                      return DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBookId = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Nominal Input
              Text(
                loc.tr('nominal_income'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.incomeGreen, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(
                      CurrencyFormatter.getCurrencySymbol(localeCode),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.incomeGreen,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Quick Amount Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickAmounts.map((amt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text('+${CurrencyFormatter.format(amt.toDouble(), localeCode: localeCode)}'),
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.gray100,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.gray300 : AppColors.gray700,
                        ),
                        onPressed: () => _onQuickAmountTap(amt),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Kategori
              Text(
                loc.tr('category'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory?.id == cat.id;
                  final catColor = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));

                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.incomeGreen.withValues(alpha: 0.15)
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.incomeGreen
                              : (isDark ? AppColors.gray800 : AppColors.gray200),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getIconData(cat.icon), size: 18, color: catColor),
                          const SizedBox(width: 8),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isDark ? Colors.white : AppColors.gray800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 4. Tanggal
              Text(
                loc.tr('transaction_date'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.gray700 : AppColors.gray200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.format(_selectedDate, localeCode),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.incomeGreen),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Catatan
              Text(
                loc.tr('notes_optional'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: loc.tr('notes_hint_income'),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.gray700 : AppColors.gray200,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Simpan Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.incomeGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    loc.tr('save_transaction'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

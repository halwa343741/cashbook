import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../../category/domain/models/category_model.dart';
import '../cubit/transaction_cubit.dart';
import '../domain/models/transaction_model.dart';
import 'widgets/category_suggest_field.dart';

class AddIncomeScreen extends StatefulWidget {
  final LocalStorageService storage;
  final TransactionModel? initialTransaction;

  const AddIncomeScreen({
    super.key,
    required this.storage,
    this.initialTransaction,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<CategoryModel> _categories = [];
  String? _selectedBookId;

  final List<int> _quickAmounts = [50000, 100000, 500000, 1000000, 2500000, 5000000];

  bool get _isEdit => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.initialTransaction?.bookId ??
        context.read<BookCubit>().activeBook?.id ??
        widget.storage.activeBookId ??
        widget.storage.getBooks().firstOrNull?.id;

    final rawCats = List<CategoryModel>.from(
      widget.storage.getCategories(),
    );
    final lastUsedId = widget.storage.getLastUsedCategoryId('income');
    if (lastUsedId != null) {
      final index = rawCats.indexWhere((c) => c.id == lastUsedId);
      if (index > 0) {
        final lastCat = rawCats.removeAt(index);
        rawCats.insert(0, lastCat);
      }
    }
    _categories = rawCats;

    if (_isEdit) {
      final tx = widget.initialTransaction!;
      _amountController.text = CurrencyFormatter.formatNumberOnly(tx.amount, 'id');
      _selectedDate = tx.transactionDate;
      _noteController.text = tx.note;
      _categoryController.text = tx.categoryName;
    } else if (_categories.isNotEmpty) {
      _categoryController.text = _categories.first.name;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
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

  Future<void> _saveIncome() async {
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

    final catName = _categoryController.text.trim();
    if (catName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.tr('please_select_category'))),
      );
      return;
    }

    final capitalizedCatName = CategoryModel.capitalizeWords(catName);

    // Upsert category globally to prevent any duplication and enforce capitalization
    final matchedCategory = await widget.storage.upsertCategory(
      CategoryModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: capitalizedCatName,
        type: CategoryType.income,
        icon: 'tag',
        colorValue: 0xFF16A34A,
      ),
    );

    await widget.storage.setLastUsedCategoryId('income', matchedCategory.id);

    if (_isEdit) {
      final updatedTx = widget.initialTransaction!.copyWith(
        amount: amount,
        bookId: _selectedBookId,
        categoryId: matchedCategory.id,
        categoryName: matchedCategory.name,
        note: _noteController.text.trim(),
        date: _selectedDate,
        updatedAt: DateTime.now(),
      );

      if (!mounted) return;
      await context.read<TransactionCubit>().updateTransaction(updatedTx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.tr('transaction_saved'))),
        );
        context.pop(true);
      }
    } else {
      final tx = TransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        bookId: _selectedBookId!,
        type: 'income',
        amount: amount,
        categoryId: matchedCategory.id,
        categoryName: matchedCategory.name,
        note: _noteController.text.trim(),
        transactionDate: _selectedDate,
        createdAt: DateTime.now(),
      );

      if (!mounted) return;
      await context.read<TransactionCubit>().addTransaction(tx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.tr('transaction_saved'))),
        );
        context.pop(true);
      }
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
        title: Text(_isEdit ? loc.tr('edit_transaction') : loc.tr('add_income')),
        centerTitle: true,
        actions: [
          // Save Transaction Button at the TOP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _saveIncome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.incomeGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                _isEdit ? loc.tr('update') : loc.tr('save'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Nominal Input
              Text(
                loc.tr('nominal_income'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.gray900,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.gray800 : AppColors.gray200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.gray800 : AppColors.gray200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.incomeGreen,
                      width: 1.5,
                    ),
                  ),
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
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        side: BorderSide(
                          color: isDark ? AppColors.gray800 : AppColors.gray200,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

              // 2. Kategori (Semi-Dropdown / Combobox Suggestion Input)
              Text(
                loc.tr('category'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 8),
              CategorySuggestField(
                controller: _categoryController,
                categories: _categories,
                isDark: isDark,
                accentColor: AppColors.incomeGreen,
                hintText: loc.tr('choose_income_category'),
              ),

              const SizedBox(height: 24),

              // 3. Tanggal
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

              // 4. Catatan
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
            ],
          ),
        ),
      ),
    );
  }
}

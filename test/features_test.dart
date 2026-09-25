import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cashbook/core/localization/app_localizations.dart';
import 'package:cashbook/core/utils/date_formatter.dart';
import 'package:cashbook/features/category/domain/models/category_model.dart';
import 'package:cashbook/features/transaction/domain/models/transaction_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('Transaction & Trash Logic Unit Tests', () {
    test('Transactions in a date group are sorted by ID descending', () {
      final t1 = TransactionModel(
        id: 'tx_1001',
        bookId: 'book_1',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'cat_1',
        title: 'Makan',
        createdAt: DateTime(2026, 9, 21, 10, 0),
      );

      final t2 = TransactionModel(
        id: 'tx_1003',
        bookId: 'book_1',
        amount: 25000,
        type: TransactionType.expense,
        categoryId: 'cat_1',
        title: 'Kopi',
        createdAt: DateTime(2026, 9, 21, 11, 0),
      );

      final t3 = TransactionModel(
        id: 'tx_1002',
        bookId: 'book_1',
        amount: 15000,
        type: TransactionType.expense,
        categoryId: 'cat_2',
        title: 'Parkir',
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      final list = [t1, t2, t3];
      list.sort((a, b) => b.id.compareTo(a.id));

      expect(list.map((e) => e.id).toList(), ['tx_1003', 'tx_1002', 'tx_1001']);
    });

    test('TransactionModel copyWith updates fields properly for editing', () {
      final initial = TransactionModel(
        id: 'tx_1',
        bookId: 'book_1',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        title: 'Makan',
        note: 'Salah ketik',
        createdAt: DateTime(2026, 9, 21),
      );

      final updated = initial.copyWith(
        amount: 75000,
        note: 'Koreksi nominal makan siang',
        categoryName: 'Makan Siang',
      );

      expect(updated.id, 'tx_1');
      expect(updated.amount, 75000);
      expect(updated.note, 'Koreksi nominal makan siang');
      expect(updated.categoryName, 'Makan Siang');
    });

    test('Category matching and new category creation', () {
      final existingCategories = [
        CategoryModel(id: 'cat_1', name: 'Makan & Minum', type: CategoryType.expense, icon: 'utensils'),
        CategoryModel(id: 'cat_2', name: 'Transportasi', type: CategoryType.expense, icon: 'car'),
      ];

      // Exact match (case insensitive)
      const inputExisting = 'makan & minum';
      final match = existingCategories.where(
        (c) => c.name.trim().toLowerCase() == inputExisting.trim().toLowerCase(),
      ).firstOrNull;
      expect(match != null, true);
      expect(match!.id, 'cat_1');

      // New category
      const inputNew = 'Servis AC';
      final noMatch = existingCategories.where(
        (c) => c.name.trim().toLowerCase() == inputNew.trim().toLowerCase(),
      ).firstOrNull;
      expect(noMatch, isNull);

      final newCat = CategoryModel(
        id: 'cat_new_1',
        name: inputNew,
        type: CategoryType.expense,
        icon: 'tag',
        colorValue: 0xFFEF4444,
      );
      expect(newCat.name, 'Servis AC');
      expect(newCat.type, CategoryType.expense);
    });

    test('CategoryModel.capitalizeWords automatically capitalizes first letter of each word', () {
      expect(CategoryModel.capitalizeWords('makan siang'), 'Makan Siang');
      expect(CategoryModel.capitalizeWords('beli pulsa & paket data'), 'Beli Pulsa & Paket Data');
      expect(CategoryModel.capitalizeWords('gaji bulanan'), 'Gaji Bulanan');
      expect(CategoryModel.capitalizeWords('THR lebaran'), 'THR Lebaran');
      expect(CategoryModel.capitalizeWords('BCA transfer'), 'BCA Transfer');
      expect(CategoryModel.capitalizeWords('  gaji pokok bulanan  '), 'Gaji Pokok Bulanan');
      expect(CategoryModel.capitalizeWords(''), '');
    });

    test('CategoryModel constructor automatically capitalizes category name', () {
      final cat = CategoryModel(
        id: 'cat_test',
        name: 'makan siang dan malam',
        icon: 'utensils',
      );
      expect(cat.name, 'Makan Siang Dan Malam');
    });

    test('DateFormatter.formatWithDay formats date with day name in specified locale', () {
      final sampleDate = DateTime(2026, 9, 25); // Friday

      final formattedId = DateFormatter.formatWithDay(sampleDate, 'id');
      expect(formattedId.toLowerCase().contains('jumat'), isTrue);

      final formattedEn = DateFormatter.formatWithDay(sampleDate, 'en');
      expect(formattedEn.toLowerCase().contains('friday'), isTrue);

      final formattedEs = DateFormatter.formatWithDay(sampleDate, 'es');
      expect(formattedEs.toLowerCase().contains('viernes'), isTrue);

      final formattedZh = DateFormatter.formatWithDay(sampleDate, 'zh');
      expect(formattedZh.contains('星期五'), isTrue);
    });

    test('DateFormatter.formatGroupHeader includes day name for today and older dates', () {
      final now = DateTime.now();
      final headerToday = DateFormatter.formatGroupHeader(now, 'id');
      expect(headerToday.startsWith('Hari Ini,'), isTrue);

      final pastDate = DateTime(2026, 1, 5); // Monday
      final headerPastId = DateFormatter.formatGroupHeader(pastDate, 'id');
      expect(headerPastId.toLowerCase().contains('senin'), isTrue);

      final headerPastEn = DateFormatter.formatGroupHeader(pastDate, 'en');
      expect(headerPastEn.toLowerCase().contains('monday'), isTrue);
    });

    test('Localization verifies category renamed to description across locales', () {
      final locId = AppLocalizations(const Locale('id'));
      expect(locId.tr('category'), 'Deskripsi');
      expect(locId.tr('choose_category'), 'Pilih Deskripsi');
      expect(locId.tr('manage_categories'), 'Kelola Deskripsi');

      final locEn = AppLocalizations(const Locale('en'));
      expect(locEn.tr('category'), 'Description');
      expect(locEn.tr('choose_category'), 'Choose Description');
      expect(locEn.tr('manage_categories'), 'Manage Descriptions');

      final locEs = AppLocalizations(const Locale('es'));
      expect(locEs.tr('category'), 'Descripción');

      final locZh = AppLocalizations(const Locale('zh'));
      expect(locZh.tr('category'), '描述');

      final locAr = AppLocalizations(const Locale('ar'));
      expect(locAr.tr('category'), 'الوصف');
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/book/domain/models/book_model.dart';
import '../../features/category/domain/models/category_model.dart';
import '../../features/transaction/domain/models/transaction_model.dart';

class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._internal();
  LocalStorageService._internal();

  factory LocalStorageService() => instance;

  Future<void> init() async => await initialize();

  static const String _fileName = 'data.cashbook';
  static const String _prefActiveBookKey = 'active_book_id';

  List<BookModel> _books = [];
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  String? _activeBookId;
  Map<String, dynamic> _settings = {
    'theme': 'system',
    'currency': 'IDR',
    'hideBalance': false,
    'security': {
      'pinEnabled': false,
      'biometricEnabled': false,
    }
  };

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        _parseData(data);
      } else {
        _initializeDefaultData();
        await saveToFile();
      }
    } catch (e) {
      _initializeDefaultData();
    }

    final prefs = await SharedPreferences.getInstance();
    final savedActive = prefs.getString(_prefActiveBookKey);
    if (savedActive != null && _books.any((b) => b.id == savedActive && !b.isDeleted)) {
      _activeBookId = savedActive;
    } else {
      final activeBooks = _books.where((b) => !b.isDeleted).toList();
      _activeBookId = activeBooks.isNotEmpty ? activeBooks.first.id : null;
    }

    _isInitialized = true;
  }

  void _initializeDefaultData() {
    _categories = [];
    _books = [];
    _transactions = [];
  }

  void _parseData(Map<String, dynamic> data) {
    if (data['settings'] != null) {
      _settings = Map<String, dynamic>.from(data['settings']);
    }

    if (data['categories'] != null) {
      final rawList = (data['categories'] as List)
          .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
          .toList();
      final Map<String, CategoryModel> unique = {};
      for (final cat in rawList) {
        final capName = CategoryModel.capitalizeWords(cat.name);
        final key = capName.toLowerCase();
        if (!unique.containsKey(key)) {
          unique[key] = cat.copyWith(name: capName);
        }
      }
      _categories = unique.values.toList();
    } else {
      _categories = [];
    }

    if (data['books'] != null) {
      _books = (data['books'] as List)
          .map((b) => BookModel.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    if (data['transactions'] != null) {
      _transactions = (data['transactions'] as List)
          .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    if (data['activeBookId'] != null) {
      _activeBookId = data['activeBookId'] as String;
    }
  }

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> saveToFile() async {
    final file = await _getLocalFile();
    final fullData = {
      'version': 1,
      'lastSyncedAt': DateTime.now().toIso8601String(),
      'activeBookId': _activeBookId,
      'settings': _settings,
      'books': _books.map((b) => b.toJson()).toList(),
      'categories': _categories.map((c) => c.toJson()).toList(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
    };

    await file.writeAsString(jsonEncode(fullData));

    if (_activeBookId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefActiveBookKey, _activeBookId!);
    }
  }

  /// Kembalikan File objek data.cashbook untuk keperluan backup.
  Future<File> getDataFile() => _getLocalFile();

  /// Restore data dari file backup eksternal (path dari file picker).
  Future<bool> restoreFromFile(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) return false;
      final content = await sourceFile.readAsString();
      // Validasi JSON
      final Map<String, dynamic> data = jsonDecode(content);
      // Tulis ke file lokal
      final localFile = await _getLocalFile();
      await localFile.writeAsString(jsonEncode(data));
      // Reload data ke memori
      _isInitialized = false;
      await initialize();
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Books Management ---
  List<BookModel> getBooks({bool includeDeleted = false}) {
    if (includeDeleted) return List.unmodifiable(_books);
    return List.unmodifiable(_books.where((b) => !b.isDeleted));
  }

  List<BookModel> getDeletedBooks() {
    return List.unmodifiable(_books.where((b) => b.isDeleted));
  }

  BookModel? getActiveBook() {
    if (_activeBookId == null) return null;
    final found = _books.where((b) => b.id == _activeBookId && !b.isDeleted).toList();
    return found.isNotEmpty ? found.first : null;
  }

  String? get activeBookId => _activeBookId;

  Future<void> setActiveBook(String bookId) async {
    _activeBookId = bookId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveBookKey, bookId);
    await saveToFile();
  }

  Future<void> addBook(BookModel book) async {
    _books.add(book);
    _activeBookId = book.id;
    await saveToFile();
  }

  Future<void> updateBook(BookModel updated) async {
    final idx = _books.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      _books[idx] = updated.copyWith(updatedAt: DateTime.now());
      await saveToFile();
    }
  }

  Future<void> softDeleteBook(String bookId) async {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx != -1) {
      _books[idx] = _books[idx].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // If active book was deleted, pick another active book
      if (_activeBookId == bookId) {
        final remaining = _books.where((b) => !b.isDeleted).toList();
        _activeBookId = remaining.isNotEmpty ? remaining.first.id : null;
      }
      await saveToFile();
    }
  }

  Future<void> restoreBook(String bookId) async {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx != -1) {
      _books[idx] = _books[idx].copyWith(
        isDeleted: false,
        deletedAt: null,
        updatedAt: DateTime.now(),
      );
      _activeBookId ??= bookId;
      await saveToFile();
    }
  }



  Future<void> purgeBook(String bookId) async {
    _books.removeWhere((b) => b.id == bookId);
    _transactions.removeWhere((t) => t.bookId == bookId);
    if (_activeBookId == bookId) {
      final remaining = _books.where((b) => !b.isDeleted).toList();
      _activeBookId = remaining.isNotEmpty ? remaining.first.id : null;
    }
    await saveToFile();
  }

  // --- Transactions Management ---
  List<TransactionModel> getTransactions({
    String? bookId,
    bool includeDeleted = false,
    dynamic type,
  }) {
    final targetBook = bookId ?? _activeBookId;
    final txType = type is TransactionType
        ? type
        : (type == 'income'
            ? TransactionType.income
            : (type == 'expense'
                ? TransactionType.expense
                : (type == 'transfer' ? TransactionType.transfer : null)));

    return _transactions.where((t) {
      if (t.isDeleted && !includeDeleted) return false;
      if (targetBook != null && t.bookId != targetBook) return false;
      if (txType != null && t.type != txType) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  TransactionModel? getTransactionById(String id) {
    final found = _transactions.where((t) => t.id == id).toList();
    return found.isNotEmpty ? found.first : null;
  }

  List<TransactionModel> getDeletedTransactions() {
    return _transactions.where((t) => t.isDeleted).toList()
      ..sort((a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
  }

  Future<void> addTransaction(TransactionModel tx) async {
    _transactions.add(tx);
    await saveToFile();
  }

  Future<void> updateTransaction(TransactionModel updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _transactions[idx] = updated.copyWith(updatedAt: DateTime.now());
      await saveToFile();
    }
  }

  Future<void> softDeleteTransaction(String txId) async {
    final idx = _transactions.indexWhere((t) => t.id == txId);
    if (idx != -1) {
      _transactions[idx] = _transactions[idx].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveToFile();
    }
  }

  Future<void> restoreTransaction(String txId) async {
    final idx = _transactions.indexWhere((t) => t.id == txId);
    if (idx != -1) {
      _transactions[idx] = _transactions[idx].copyWith(
        isDeleted: false,
        deletedAt: null,
        updatedAt: DateTime.now(),
      );
      await saveToFile();
    }
  }

  Future<void> purgeTransaction(String txId) async {
    _transactions.removeWhere((t) => t.id == txId);
    await saveToFile();
  }

  Future<void> emptyTrash() async {
    _books.removeWhere((b) => b.isDeleted);
    _transactions.removeWhere((t) => t.isDeleted);
    await saveToFile();
  }

  // --- Summary & Calculation ---
  double getBalance(String? bookId) {
    final txs = getTransactions(bookId: bookId);
    final book = _books.where((b) => b.id == (bookId ?? _activeBookId)).firstOrNull;
    double balance = book?.initialBalance ?? 0.0;

    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        balance += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        balance -= tx.amount;
      } else if (tx.type == TransactionType.transfer) {
        if (tx.bookId == (bookId ?? _activeBookId)) {
          balance -= tx.amount;
        }
        if (tx.targetBookId == (bookId ?? _activeBookId)) {
          balance += tx.amount;
        }
      }
    }
    return balance;
  }

  Map<String, double> getSummary(String? bookId, {DateTime? startDate, DateTime? endDate}) {
    final txs = getTransactions(bookId: bookId).where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  // --- Categories ---
  List<CategoryModel> getCategories({dynamic type}) {
    // Categories are global across income and expense
    return List.unmodifiable(_categories);
  }

  Future<CategoryModel> upsertCategory(CategoryModel cat) async {
    final formattedName = CategoryModel.capitalizeWords(cat.name);
    final idx = _categories.indexWhere(
      (c) => c.name.trim().toLowerCase() == formattedName.trim().toLowerCase(),
    );

    if (idx != -1) {
      final existing = _categories[idx];
      final updated = existing.copyWith(
        name: formattedName,
        icon: cat.icon.isNotEmpty ? cat.icon : existing.icon,
        color: cat.color.isNotEmpty ? cat.color : existing.color,
      );
      _categories[idx] = updated;
      await saveToFile();
      return updated;
    } else {
      final newCat = cat.copyWith(
        name: formattedName,
      );
      _categories.add(newCat);
      await saveToFile();
      return newCat;
    }
  }

  Future<void> addCategory(CategoryModel cat) async {
    await upsertCategory(cat);
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await saveToFile();
  }

  // --- Settings ---
  Map<String, dynamic> get settings => _settings;

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings.addAll(newSettings);
    await saveToFile();
  }

  String? getLastUsedCategoryId(String type) {
    if (_settings['last_category_$type'] != null) {
      return _settings['last_category_$type'] as String;
    }
    final txs = getTransactions(type: type);
    return txs.firstOrNull?.categoryId;
  }

  Future<void> setLastUsedCategoryId(String type, String categoryId) async {
    _settings['last_category_$type'] = categoryId;
    await saveToFile();
  }
}

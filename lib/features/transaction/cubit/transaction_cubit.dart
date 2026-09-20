import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/local_storage_service.dart';
import '../domain/models/transaction_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final String? activeBookId;
  final String filterType; // 'all', 'income', 'expense'

  const TransactionLoaded({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.activeBookId,
    this.filterType = 'all',
  });

  @override
  List<Object?> get props => [
        transactions,
        totalIncome,
        totalExpense,
        balance,
        activeBookId,
        filterType,
      ];

  TransactionLoaded copyWith({
    List<TransactionModel>? transactions,
    double? totalIncome,
    double? totalExpense,
    double? balance,
    String? activeBookId,
    String? filterType,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      activeBookId: activeBookId ?? this.activeBookId,
      filterType: filterType ?? this.filterType,
    );
  }
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionCubit extends Cubit<TransactionState> {
  final LocalStorageService _storage;
  String? _currentBookId;
  String _currentFilter = 'all';

  TransactionCubit({required LocalStorageService storage})
      : _storage = storage,
        super(TransactionInitial());

  String? get currentBookId => _currentBookId;
  String get currentFilter => _currentFilter;

  void loadTransactions(String? bookId, {String filter = 'all'}) {
    _currentBookId = bookId;
    _currentFilter = filter;
    emit(TransactionLoading());

    try {
      final all = _storage.getTransactions(bookId: bookId);
      final summary = _storage.getSummary(bookId);

      List<TransactionModel> filtered = all;
      if (filter == 'income') {
        filtered = all.where((t) => t.isIncome).toList();
      } else if (filter == 'expense') {
        filtered = all.where((t) => t.isExpense).toList();
      }

      emit(TransactionLoaded(
        transactions: filtered,
        totalIncome: summary['income'] ?? 0.0,
        totalExpense: summary['expense'] ?? 0.0,
        balance: summary['balance'] ?? 0.0,
        activeBookId: bookId,
        filterType: filter,
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  void setFilter(String filter) {
    if (_currentFilter == filter) return;
    loadTransactions(_currentBookId, filter: filter);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _storage.addTransaction(transaction);
      loadTransactions(_currentBookId, filter: _currentFilter);
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _storage.updateTransaction(transaction);
      loadTransactions(_currentBookId, filter: _currentFilter);
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> softDeleteTransaction(String id) async {
    try {
      await _storage.softDeleteTransaction(id);
      loadTransactions(_currentBookId, filter: _currentFilter);
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> restoreTransaction(String id) async {
    try {
      await _storage.restoreTransaction(id);
      loadTransactions(_currentBookId, filter: _currentFilter);
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> purgeTransaction(String id) async {
    try {
      await _storage.purgeTransaction(id);
      loadTransactions(_currentBookId, filter: _currentFilter);
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../book/domain/models/book_model.dart';
import '../../../core/database/local_storage_service.dart';

class BookState extends Equatable {
  final List<BookModel> books;
  final List<BookModel> deletedBooks;
  final BookModel? activeBook;
  final bool isLoading;
  final String? errorMessage;

  const BookState({
    this.books = const [],
    this.deletedBooks = const [],
    this.activeBook,
    this.isLoading = false,
    this.errorMessage,
  });

  String? get activeBookId => activeBook?.id;

  BookState copyWith({
    List<BookModel>? books,
    List<BookModel>? deletedBooks,
    BookModel? activeBook,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BookState(
      books: books ?? this.books,
      deletedBooks: deletedBooks ?? this.deletedBooks,
      activeBook: activeBook ?? this.activeBook,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [books, deletedBooks, activeBook, isLoading, errorMessage];
}

class BookLoading extends BookState {
  const BookLoading() : super(isLoading: true);
}

class BookLoaded extends BookState {
  const BookLoaded({
    super.books,
    super.deletedBooks,
    super.activeBook,
    super.isLoading = false,
    super.errorMessage,
  });
}

class BookCubit extends Cubit<BookState> {
  final LocalStorageService _storage;

  BookCubit({LocalStorageService? storage})
      : _storage = storage ?? LocalStorageService.instance,
        super(const BookLoading()) {
    loadBooks();
  }

  BookModel? get activeBook => state.activeBook;

  void loadBooks() {
    emit(const BookLoading());
    try {
      final books = _storage.getBooks();
      final deleted = _storage.getDeletedBooks();
      final active = _storage.getActiveBook();
      emit(BookLoaded(
        books: books,
        deletedBooks: deleted,
        activeBook: active,
        isLoading: false,
      ));
    } catch (e) {
      emit(BookLoaded(
        books: const [],
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> selectActiveBook(String bookId) async {
    await _storage.setActiveBook(bookId);
    final active = _storage.getActiveBook();
    emit(BookLoaded(
      books: state.books,
      deletedBooks: state.deletedBooks,
      activeBook: active,
    ));
  }

  Future<void> selectBook(String bookId) => selectActiveBook(bookId);

  Future<void> addBook(BookModel book) async {
    await _storage.addBook(book);
    loadBooks();
  }

  Future<void> createBook({
    required String name,
    required String icon,
    required int colorValue,
    String? description,
    double initialBalance = 0.0,
  }) async {
    final newBook = BookModel(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon,
      colorValue: colorValue,
      description: description,
      initialBalance: initialBalance,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.addBook(newBook);
    loadBooks();
  }

  Future<void> updateBook(BookModel book) async {
    await _storage.updateBook(book);
    loadBooks();
  }

  Future<void> softDeleteBook(String bookId) async {
    await _storage.softDeleteBook(bookId);
    loadBooks();
  }

  Future<void> restoreBook(String bookId) async {
    await _storage.restoreBook(bookId);
    loadBooks();
  }

  Future<void> purgeBook(String bookId) async {
    await _storage.purgeBook(bookId);
    loadBooks();
  }

  Future<void> importSharedBook(String jsonContent, {String? senderName}) async {
    await _storage.importSharedBook(jsonContent, senderName: senderName);
    loadBooks();
  }
}

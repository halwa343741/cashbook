enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final String bookId;
  final String? targetBookId; // Used when type == TransactionType.transfer
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String note;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.bookId,
    this.targetBookId,
    String? title,
    String? categoryName,
    required this.amount,
    dynamic type,
    required this.categoryId,
    DateTime? date,
    DateTime? transactionDate,
    String? note,
    this.isSynced = false,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    DateTime? updatedAt,
  })  : title = title ?? categoryName ?? 'Transaksi',
        type = type is TransactionType
            ? type
            : (type == 'income'
                ? TransactionType.income
                : (type == 'transfer' ? TransactionType.transfer : TransactionType.expense)),
        date = date ?? transactionDate ?? DateTime.now(),
        note = note ?? '',
        updatedAt = updatedAt ?? createdAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;
  DateTime get transactionDate => date;
  String get categoryName => title;

  TransactionModel copyWith({
    String? id,
    String? bookId,
    String? targetBookId,
    String? title,
    String? categoryName,
    double? amount,
    dynamic type,
    String? categoryId,
    DateTime? date,
    DateTime? transactionDate,
    String? note,
    bool? isSynced,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      targetBookId: targetBookId ?? this.targetBookId,
      title: title ?? categoryName ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? transactionDate ?? this.date,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'targetBookId': targetBookId,
      'title': title,
      'categoryName': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'transactionDate': date.toIso8601String(),
      'note': note,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    TransactionType txType;
    final typeStr = json['type'] as String? ?? 'expense';
    if (typeStr == 'income') {
      txType = TransactionType.income;
    } else if (typeStr == 'transfer') {
      txType = TransactionType.transfer;
    } else {
      txType = TransactionType.expense;
    }

    return TransactionModel(
      id: json['id'] as String,
      bookId: json['bookId'] as String? ?? 'book_default',
      targetBookId: json['targetBookId'] as String?,
      title: (json['title'] ?? json['categoryName'] ?? 'Transaksi') as String,
      amount: (json['amount'] as num).toDouble(),
      type: txType,
      categoryId: json['categoryId'] as String? ?? 'cat_ex_lainnya',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : (json['transactionDate'] != null
              ? DateTime.parse(json['transactionDate'] as String)
              : DateTime.now()),
      note: json['note'] as String? ?? '',
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}

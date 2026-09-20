class BookModel {
  final String id;
  final String name;
  final String icon; // e.g. wallet, store, home, savings, briefcase
  final int colorValue; // Hex ARGB
  final String? description;
  final double initialBalance;
  final bool isReadOnly;
  final String? sharedBy;
  final bool isClosed;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  BookModel({
    required this.id,
    required this.name,
    required this.icon,
    int? colorValue,
    String? color,
    this.description,
    this.initialBalance = 0.0,
    this.isReadOnly = false,
    this.sharedBy,
    this.isClosed = false,
    this.closedAt,
    required this.createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  })  : colorValue = colorValue ??
            (color != null
                ? int.tryParse(color.replaceFirst('#', '0xFF')) ?? 0xFF15803D
                : 0xFF15803D),
        updatedAt = updatedAt ?? createdAt;

  String get color =>
      '#${(colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  BookModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorValue,
    String? color,
    String? description,
    double? initialBalance,
    bool? isReadOnly,
    String? sharedBy,
    bool? isClosed,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ??
          (color != null
              ? int.tryParse(color.replaceFirst('#', '0xFF')) ?? this.colorValue
              : this.colorValue),
      description: description ?? this.description,
      initialBalance: initialBalance ?? this.initialBalance,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      sharedBy: sharedBy ?? this.sharedBy,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'color': color,
      'description': description,
      'initialBalance': initialBalance,
      'isReadOnly': isReadOnly,
      'sharedBy': sharedBy,
      'isClosed': isClosed,
      'closedAt': closedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'wallet',
      colorValue: json['colorValue'] is int
          ? json['colorValue'] as int
          : (json['color'] != null
              ? int.tryParse(json['color'].toString().replaceAll('#', '0xFF')) ?? 0xFF15803D
              : 0xFF15803D),
      description: json['description'] as String?,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      sharedBy: json['sharedBy'] as String?,
      isClosed: json['isClosed'] as bool? ?? false,
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }
}

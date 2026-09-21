import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String name;
  final CategoryType type;
  final String icon;
  final int colorValue;

  CategoryModel({
    required this.id,
    required String name,
    dynamic type,
    required this.icon,
    int? colorValue,
    String? color,
  })  : name = capitalizeWords(name),
        type = type is CategoryType
            ? type
            : (type == 'income' ? CategoryType.income : CategoryType.expense),
        colorValue = colorValue ??
            (color != null
                ? int.tryParse(color.replaceFirst('#', '0xFF')) ?? 0xFF15803D
                : 0xFF15803D);

  String get color =>
      '#${(colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String capitalizeWords(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : '');
    }).join(' ');
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    dynamic type,
    String? icon,
    int? colorValue,
    String? color,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name != null ? CategoryModel.capitalizeWords(name) : this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      color: color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'icon': icon,
      'colorValue': colorValue,
      'color': color,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      icon: json['icon'] as String? ?? 'tag',
      colorValue: json['colorValue'] is int
          ? json['colorValue'] as int
          : (json['color'] != null
              ? int.tryParse(json['color'].toString().replaceAll('#', '0xFF')) ?? 0xFF15803D
              : 0xFF15803D),
    );
  }

  static List<CategoryModel> defaultCategories() {
    return [
      // Income
      CategoryModel(id: 'cat_gaji', name: 'Gaji', type: CategoryType.income, icon: 'wallet', colorValue: 0xFF16A34A),
      CategoryModel(id: 'cat_penjualan', name: 'Penjualan', type: CategoryType.income, icon: 'store', colorValue: 0xFF10B981),
      CategoryModel(id: 'cat_bonus', name: 'Bonus & THR', type: CategoryType.income, icon: 'gift', colorValue: 0xFF059669),
      CategoryModel(id: 'cat_investasi', name: 'Investasi', type: CategoryType.income, icon: 'trending-up', colorValue: 0xFF0D9488),
      CategoryModel(id: 'cat_in_lainnya', name: 'Pemasukan Lain', type: CategoryType.income, icon: 'plus-circle', colorValue: 0xFF0284C7),

      // Expense
      CategoryModel(id: 'cat_makan', name: 'Makan & Minum', type: CategoryType.expense, icon: 'utensils', colorValue: 0xFFEF4444),
      CategoryModel(id: 'cat_transport', name: 'Transportasi', type: CategoryType.expense, icon: 'car', colorValue: 0xFFF97316),
      CategoryModel(id: 'cat_belanja', name: 'Belanja', type: CategoryType.expense, icon: 'shopping-cart', colorValue: 0xFFF59E0B),
      CategoryModel(id: 'cat_kesehatan', name: 'Kesehatan', type: CategoryType.expense, icon: 'heart', colorValue: 0xFF3B82F6),
      CategoryModel(id: 'cat_pendidikan', name: 'Pendidikan', type: CategoryType.expense, icon: 'book', colorValue: 0xFF6366F1),
      CategoryModel(id: 'cat_pulsa', name: 'Hiburan & Pulsa', type: CategoryType.expense, icon: 'smartphone', colorValue: 0xFFEC4899),
      CategoryModel(id: 'cat_ex_lainnya', name: 'Lainnya', type: CategoryType.expense, icon: 'more-horizontal', colorValue: 0xFF64748B),
    ];
  }

  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'briefcase':
        return Icons.work_rounded;
      case 'shopping-bag':
        return Icons.shopping_bag_rounded;
      case 'shopping-cart':
        return Icons.shopping_cart_rounded;
      case 'food':
      case 'utensils':
        return Icons.restaurant_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'medical':
      case 'heart':
      case 'heart-pulse':
        return Icons.medical_services_rounded;
      case 'graduation-cap':
      case 'book':
        return Icons.school_rounded;
      case 'trending-up':
        return Icons.trending_up_rounded;
      case 'store':
        return Icons.store_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'smartphone':
        return Icons.phone_android_rounded;
      case 'receipt':
      case 'file-text':
        return Icons.receipt_long_rounded;
      case 'film':
        return Icons.movie_rounded;
      case 'coin':
        return Icons.monetization_on_rounded;
      case 'plus-circle':
        return Icons.add_circle_outline_rounded;
      case 'tag':
      default:
        return Icons.label_rounded;
    }
  }
}

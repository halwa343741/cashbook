import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../cubit/book_cubit.dart';
import '../domain/models/book_model.dart';
import '../../transaction/cubit/transaction_cubit.dart';

class CreateInitialBookScreen extends StatefulWidget {
  const CreateInitialBookScreen({super.key});

  @override
  State<CreateInitialBookScreen> createState() => _CreateInitialBookScreenState();
}

class _CreateInitialBookScreenState extends State<CreateInitialBookScreen> {
  final _nameController = TextEditingController(text: 'Cashbook');
  String _selectedIcon = 'briefcase';
  String _selectedColor = '#10B981';

  final List<Map<String, dynamic>> _icons = [
    {'name': 'briefcase', 'icon': Icons.work_rounded},
    {'name': 'store', 'icon': Icons.storefront_rounded},
    {'name': 'home', 'icon': Icons.home_rounded},
    {'name': 'savings', 'icon': Icons.savings_rounded},
    {'name': 'payments', 'icon': Icons.payments_rounded},
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded},
  ];

  final List<String> _colors = [
    '#10B981', // Emerald
    '#3B82F6', // Blue
    '#6366F1', // Indigo
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final newBook = BookModel(
      id: const Uuid().v4(),
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
      createdAt: DateTime.now(),
    );

    context.read<BookCubit>().addBook(newBook);
    context.read<BookCubit>().selectBook(newBook.id);
    context.read<TransactionCubit>().loadTransactions(newBook.id);

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                loc.tr('create_first_book'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.tr('create_first_book_desc'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 32),
              // Nama Buku
              Text(
                loc.tr('book_name'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.gray800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: loc.tr('book_name'),
                  prefixIcon: const Icon(Icons.menu_book_rounded),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.gray700 : AppColors.gray300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Ikon
              Text(
                loc.tr('select_icon'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.gray800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((item) {
                  final isSelected = _selectedIcon == item['name'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = item['name'] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary500.withValues(alpha: 0.15)
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary500
                              : (isDark ? AppColors.gray700 : AppColors.gray200),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? AppColors.primary500
                            : (isDark ? AppColors.gray400 : AppColors.gray600),
                        size: 26,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Warna
              Text(
                loc.tr('select_color'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.gray800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _colors.map((hex) {
                  final isSelected = _selectedColor == hex;
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = hex;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 14),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    loc.tr('start_now'),
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

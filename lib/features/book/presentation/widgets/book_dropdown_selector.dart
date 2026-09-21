import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../cubit/book_cubit.dart';
import '../../domain/models/book_model.dart';
import '../../../transaction/cubit/transaction_cubit.dart';

class BookDropdownSelector extends StatelessWidget {
  const BookDropdownSelector({super.key});

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'briefcase':
        return Icons.work_rounded;
      case 'store':
        return Icons.storefront_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  void _showBookPicker(BuildContext context, List<BookModel> books, String? activeId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.tr('select_book'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/manage-books');
                        },
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: Text(loc.tr('manage')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: books.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final isSelected = book.id == activeId;
                      final color = Color(int.parse(book.color.replaceFirst('#', '0xFF')));

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getIconData(book.icon), color: color, size: 22),
                        ),
                        title: Text(
                          book.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.gray900,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary500)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          ctx.read<BookCubit>().selectBook(book.id);
                          ctx.read<TransactionCubit>().loadTransactions(book.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<BookCubit, BookState>(
      builder: (context, state) {
        if (state is BookLoaded) {
          final books = state.books;
          final activeBook = state.activeBook;
          if (activeBook == null) return const SizedBox.shrink();

          final color = Color(int.parse(activeBook.color.replaceFirst('#', '0xFF')));

          return InkWell(
            onTap: () => _showBookPicker(context, books, activeBook.id),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.gray700 : AppColors.gray200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIconData(activeBook.icon), size: 18, color: color),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      activeBook.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.gray900,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

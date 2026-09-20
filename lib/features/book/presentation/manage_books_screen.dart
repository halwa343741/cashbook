import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/share_service.dart';
import '../cubit/book_cubit.dart';
import '../domain/models/book_model.dart';
import '../../transaction/cubit/transaction_cubit.dart';

class ManageBooksScreen extends StatefulWidget {
  final ShareService shareService;

  const ManageBooksScreen({
    super.key,
    required this.shareService,
  });

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  void _openAddEditBookDialog([BookModel? bookToEdit]) {
    final nameController = TextEditingController(text: bookToEdit?.name ?? '');
    String selectedIcon = bookToEdit?.icon ?? 'briefcase';
    String selectedColor = bookToEdit?.color ?? '#10B981';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final icons = [
      {'name': 'briefcase', 'icon': Icons.work_rounded},
      {'name': 'store', 'icon': Icons.storefront_rounded},
      {'name': 'home', 'icon': Icons.home_rounded},
      {'name': 'savings', 'icon': Icons.savings_rounded},
      {'name': 'payments', 'icon': Icons.payments_rounded},
      {'name': 'restaurant', 'icon': Icons.restaurant_rounded},
    ];

    final colors = [
      '#10B981',
      '#3B82F6',
      '#6366F1',
      '#F59E0B',
      '#EF4444',
      '#8B5CF6',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bookToEdit == null ? 'Tambah Buku Kas' : 'Ubah Buku Kas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Nama Buku Kas',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.gray50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Ikon:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: icons.map((item) {
                      final isSelected = selectedIcon == item['name'];
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedIcon = item['name'] as String;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary500.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary500 : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isSelected ? AppColors.primary500 : AppColors.gray500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Warna:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: colors.map((hex) {
                      final isSelected = selectedColor == hex;
                      final c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedColor = hex;
                          });
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: c,
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        if (bookToEdit == null) {
                          final newBook = BookModel(
                            id: const Uuid().v4(),
                            name: name,
                            icon: selectedIcon,
                            color: selectedColor,
                            createdAt: DateTime.now(),
                          );
                          context.read<BookCubit>().addBook(newBook);
                        } else {
                          final updated = bookToEdit.copyWith(
                            name: name,
                            icon: selectedIcon,
                            color: selectedColor,
                          );
                          context.read<BookCubit>().updateBook(updated);
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(bookToEdit == null ? 'Simpan' : 'Perbarui'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _shareBook(BookModel book) {
    widget.shareService.shareBookAsFile(book);
  }

  void _deleteBook(BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Buku Kas?'),
        content: Text(
          'Buku kas "${book.name}" beserta transaksinya akan dipindahkan ke Sampah (Trash) dan dapat dipulihkan kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BookCubit>().softDeleteBook(book.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: const Text('Hapus ke Sampah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Kelola Buku Kas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Buku',
            onPressed: () => _openAddEditBookDialog(),
          ),
        ],
      ),
      body: BlocBuilder<BookCubit, BookState>(
        builder: (context, state) {
          if (state is BookLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BookLoaded) {
            final books = state.books;
            final activeId = state.activeBookId;

            if (books.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.book_outlined, size: 64, color: AppColors.gray400),
                    const SizedBox(height: 12),
                    const Text('Belum ada buku kas aktif'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _openAddEditBookDialog(),
                      child: const Text('Buat Buku Kas'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final book = books[index];
                final isActive = book.id == activeId;
                final color = Color(int.parse(book.color.replaceFirst('#', '0xFF')));

                return Card(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isActive
                          ? AppColors.primary500
                          : (isDark ? AppColors.gray800 : AppColors.gray200),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIconData(book.icon), color: color),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            book.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.gray900,
                            ),
                          ),
                        ),
                        if (book.isReadOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amber500.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Read Only',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amber500,
                              ),
                            ),
                          ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary500.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      book.sharedBy != null
                          ? 'Dibagikan oleh: ${book.sharedBy}'
                          : 'Dibuat: ${book.createdAt.day}/${book.createdAt.month}/${book.createdAt.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      context.read<BookCubit>().selectBook(book.id);
                      context.read<TransactionCubit>().loadTransactions(book.id);
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'select') {
                          context.read<BookCubit>().selectBook(book.id);
                          context.read<TransactionCubit>().loadTransactions(book.id);
                        } else if (val == 'edit') {
                          _openAddEditBookDialog(book);
                        } else if (val == 'share') {
                          _shareBook(book);
                        } else if (val == 'delete') {
                          _deleteBook(book);
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isActive)
                          const PopupMenuItem(
                            value: 'select',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Pilih Buku'),
                              ],
                            ),
                          ),
                        if (!book.isReadOnly)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Ubah'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Bagikan (.cbshare)'),
                            ],
                          ),
                        ),
                        if (books.length > 1)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                SizedBox(width: 8),
                                Text('Hapus ke Sampah',
                                    style: TextStyle(color: AppColors.expenseRed)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

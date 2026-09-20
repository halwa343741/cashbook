import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../domain/models/category_model.dart';

class CategoryListScreen extends StatefulWidget {
  final LocalStorageService storage;

  const CategoryListScreen({
    super.key,
    required this.storage,
  });

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(String type) {
    final nameController = TextEditingController();
    String selectedIcon = 'tag';
    String selectedColor = '#10B981';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final icons = [
      {'name': 'wallet', 'icon': Icons.account_balance_wallet_rounded},
      {'name': 'briefcase', 'icon': Icons.work_rounded},
      {'name': 'shopping-bag', 'icon': Icons.shopping_bag_rounded},
      {'name': 'utensils', 'icon': Icons.restaurant_rounded},
      {'name': 'car', 'icon': Icons.directions_car_rounded},
      {'name': 'receipt', 'icon': Icons.receipt_long_rounded},
      {'name': 'heart-pulse', 'icon': Icons.medical_services_rounded},
      {'name': 'film', 'icon': Icons.movie_rounded},
      {'name': 'tag', 'icon': Icons.label_rounded},
    ];

    final colors = [
      '#10B981',
      '#3B82F6',
      '#6366F1',
      '#F59E0B',
      '#EF4444',
      '#8B5CF6',
    ];

    final loc = AppLocalizations.of(context);

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
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loc.tr('add_category')} (${type == 'income' ? loc.tr('cash_in') : loc.tr('cash_out')})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: loc.tr('category_name'),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.gray50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${loc.tr('select_icon')}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: icons.map((item) {
                      final isSelected = selectedIcon == item['name'];
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedIcon = item['name'] as String;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary500.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary500 : Colors.transparent,
                            ),
                          ),
                          child: Icon(item['icon'] as IconData, size: 22),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('${loc.tr('select_color')}:', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                          radius: 14,
                          backgroundColor: c,
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
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
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final newCat = CategoryModel(
                          id: const Uuid().v4(),
                          name: name,
                          icon: selectedIcon,
                          color: selectedColor,
                          type: type,
                        );

                        final nav = Navigator.of(ctx);
                        await widget.storage.addCategory(newCat);
                        if (mounted) {
                          setState(() {});
                          nav.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(loc.tr('save')),
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'briefcase':
        return Icons.work_rounded;
      case 'shopping-bag':
        return Icons.shopping_bag_rounded;
      case 'utensils':
        return Icons.restaurant_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'heart-pulse':
        return Icons.medical_services_rounded;
      case 'film':
        return Icons.movie_rounded;
      default:
        return Icons.label_rounded;
    }
  }

  Widget _buildCategoryList(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = widget.storage.getCategories(type: type);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.gray800 : AppColors.gray100,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getIconData(cat.icon), color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.gray900,
                  ),
                ),
              ),
              if (cat.id.startsWith('custom_') || !cat.id.startsWith('in_') && !cat.id.startsWith('ex_'))
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.gray400),
                  onPressed: () async {
                    await widget.storage.deleteCategory(cat.id);
                    setState(() {});
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(loc.tr('manage_categories')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary500,
          labelColor: AppColors.primary500,
          unselectedLabelColor: isDark ? AppColors.gray400 : AppColors.gray600,
          tabs: [
            Tab(text: loc.tr('cash_in')),
            Tab(text: loc.tr('cash_out')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList('income'),
          _buildCategoryList('expense'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0 ? 'income' : 'expense';
          _showAddCategoryDialog(type);
        },
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

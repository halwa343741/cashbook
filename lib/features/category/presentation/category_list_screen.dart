import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../domain/models/category_model.dart';
import 'widgets/add_category_modal.dart';

class CategoryListScreen extends StatefulWidget {
  final LocalStorageService storage;

  const CategoryListScreen({
    super.key,
    required this.storage,
  });

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  Future<void> _showAddCategoryDialog() async {
    final newCat = await showAddCategoryModal(
      context,
      storage: widget.storage,
    );
    if (newCat != null && mounted) {
      setState(() {});
    }
  }

  IconData _getIconData(String iconName) => CategoryModel.getIconData(iconName);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final categories = widget.storage.getCategories();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(loc.tr('manage_categories')),
        centerTitle: true,
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: isDark ? AppColors.gray600 : AppColors.gray400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.tr('no_categories_yet'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray300 : AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.tr('tap_add_category_btn'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.gray500 : AppColors.gray400,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
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
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.gray400),
                        tooltip: loc.tr('delete'),
                        onPressed: () async {
                          await widget.storage.deleteCategory(cat.id);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

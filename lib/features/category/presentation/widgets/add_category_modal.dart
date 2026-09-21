import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/category_model.dart';

Future<CategoryModel?> showAddCategoryModal(
  BuildContext context, {
  required LocalStorageService storage,
  String? type,
}) {
  final nameController = TextEditingController();
  String selectedIcon = 'tag';
  String selectedColor = '#10B981';
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final icons = [
    {'name': 'wallet', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'briefcase', 'icon': Icons.work_rounded},
    {'name': 'shopping-bag', 'icon': Icons.shopping_bag_rounded},
    {'name': 'shopping-cart', 'icon': Icons.shopping_cart_rounded},
    {'name': 'utensils', 'icon': Icons.restaurant_rounded},
    {'name': 'car', 'icon': Icons.directions_car_rounded},
    {'name': 'receipt', 'icon': Icons.receipt_long_rounded},
    {'name': 'heart-pulse', 'icon': Icons.medical_services_rounded},
    {'name': 'film', 'icon': Icons.movie_rounded},
    {'name': 'smartphone', 'icon': Icons.phone_android_rounded},
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

  return showModalBottomSheet<CategoryModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.gray700 : AppColors.gray300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      loc.tr('add_category'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
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
                      runSpacing: 8,
                      children: icons.map((item) {
                        final isSelected = selectedIcon == item['name'];
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedIcon = item['name'] as String;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
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

                          final capitalizedName = CategoryModel.capitalizeWords(name);
                          final newCat = CategoryModel(
                            id: const Uuid().v4(),
                            name: capitalizedName,
                            icon: selectedIcon,
                            color: selectedColor,
                            type: type,
                          );

                          final savedCat = await storage.upsertCategory(newCat);
                          if (ctx.mounted) {
                            Navigator.pop(ctx, savedCat);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(loc.tr('save')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

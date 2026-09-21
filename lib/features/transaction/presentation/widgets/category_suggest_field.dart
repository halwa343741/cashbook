import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../category/domain/models/category_model.dart';

class CategorySuggestField extends StatefulWidget {
  final TextEditingController controller;
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel>? onCategorySelected;
  final bool isDark;
  final Color accentColor;
  final String hintText;

  const CategorySuggestField({
    super.key,
    required this.controller,
    required this.categories,
    this.onCategorySelected,
    required this.isDark,
    required this.accentColor,
    this.hintText = 'Pilih atau ketik kategori...',
  });

  @override
  State<CategorySuggestField> createState() => _CategorySuggestFieldState();
}

class _CategorySuggestFieldState extends State<CategorySuggestField> {
  final FocusNode _focusNode = FocusNode();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _isOpen = true);
      }
    });
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted && _focusNode.hasFocus && !_isOpen) {
      setState(() => _isOpen = true);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _selectCategory(CategoryModel category) {
    widget.controller.text = category.name;
    widget.onCategorySelected?.call(category);
    setState(() => _isOpen = false);
    _focusNode.unfocus();
  }

  Widget _buildCategoryTile(CategoryModel cat, bool isDark) {
    final isSelected = widget.controller.text.trim().toLowerCase() ==
        cat.name.trim().toLowerCase();
    final catColor = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));

    return InkWell(
      onTap: () => _selectCategory(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: isSelected
            ? widget.accentColor.withValues(alpha: 0.12)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CategoryModel.getIconData(cat.icon),
                size: 16,
                color: catColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.gray900,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                size: 18,
                color: widget.accentColor,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final query = widget.controller.text.trim().toLowerCase();
    final hasQuery = query.isNotEmpty;

    // Filter results matching user typing
    final filterResults = hasQuery
        ? widget.categories
            .where((c) => c.name.toLowerCase().contains(query))
            .toList()
        : <CategoryModel>[];

    // Other categories (excluding filter results) so they don't appear below separator
    final otherCategories = hasQuery
        ? widget.categories
            .where((c) => !c.name.toLowerCase().contains(query))
            .toList()
        : widget.categories;

    final isExactMatch = widget.categories.any(
      (c) => c.name.trim().toLowerCase() == query,
    );
    final showNewCategoryOption = hasQuery && !isExactMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Text Field
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.gray900,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(
              Icons.category_outlined,
              size: 20,
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.gray400 : AppColors.gray600,
              ),
              onPressed: () {
                setState(() {
                  _isOpen = !_isOpen;
                  if (_isOpen && !_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                });
              },
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.gray800 : AppColors.gray200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.gray800 : AppColors.gray200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: widget.accentColor,
                width: 1.5,
              ),
            ),
          ),
        ),

        // Semi-dropdown suggestions panel
        if (_isOpen) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.gray800 : AppColors.gray200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                children: [
                  // 1. Filter results & New category option AT THE TOP
                  if (hasQuery) ...[
                    if (showNewCategoryOption) ...[
                      InkWell(
                        onTap: () {
                          widget.controller.text = CategoryModel.capitalizeWords(widget.controller.text.trim());
                          setState(() => _isOpen = false);
                          _focusNode.unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          color: widget.accentColor.withValues(alpha: 0.08),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded,
                                  color: widget.accentColor, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CategoryModel.capitalizeWords(widget.controller.text.trim()),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : AppColors.gray900,
                                      ),
                                    ),
                                    Text(
                                      'Simpan sebagai kategori baru',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: widget.accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Baru',
                                  style: TextStyle(
                                    color: widget.accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Matched categories at the top
                    ...filterResults.map((cat) => _buildCategoryTile(cat, isDark)),

                    // Separator (soft / subtle divider)
                    if (otherCategories.isNotEmpty)
                      Divider(
                        height: 16,
                        thickness: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                  ],

                  // 2. All other categories below separator (filter results will NOT appear here)
                  if (otherCategories.isEmpty && filterResults.isEmpty && !showNewCategoryOption)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          loc.tr('no_categories_yet'),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.gray400 : AppColors.gray500,
                          ),
                        ),
                      ),
                    )
                  else
                    ...otherCategories.map((cat) => _buildCategoryTile(cat, isDark)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

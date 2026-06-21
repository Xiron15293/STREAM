import 'package:flutter/material.dart';

import '../design/stream_icon_library.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../theme.dart';

class CategorySubcategoryResolvedSelection {
  final Category category;
  final Subcategory? subcategory;

  const CategorySubcategoryResolvedSelection({
    required this.category,
    required this.subcategory,
  });

  String get label => subcategory == null
      ? category.name
      : '${category.name} / ${subcategory!.name}';

  String get iconKey => subcategory?.iconKey ?? category.iconKey;
  int get color => subcategory?.color ?? category.color;
}

(String?, String?) normalizeCategorySubcategorySelection({
  required List<Category> categories,
  required List<Subcategory> subcategories,
  required MovementType type,
  required String? categoryId,
  required String? subcategoryId,
  bool activeOnly = true,
}) {
  final resolved = resolveCategorySubcategorySelection(
    categories: categories,
    subcategories: subcategories,
    type: type,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    activeOnly: activeOnly,
  );
  return (resolved?.category.id, resolved?.subcategory?.id);
}

CategorySubcategoryResolvedSelection? resolveCategorySubcategorySelection({
  required List<Category> categories,
  required List<Subcategory> subcategories,
  required MovementType type,
  required String? categoryId,
  required String? subcategoryId,
  bool activeOnly = true,
}) {
  if (type == MovementType.transfer || categoryId == null) return null;

  final category = categories.where((c) => c.id == categoryId).firstOrNull;
  if (category == null || category.type != type) return null;
  if (activeOnly && category.archived) return null;

  Subcategory? subcategory;
  if (subcategoryId != null) {
    final candidate = subcategories
        .where((s) => s.id == subcategoryId)
        .firstOrNull;
    if (candidate != null &&
        candidate.categoryId == category.id &&
        (!activeOnly || !candidate.archived)) {
      subcategory = candidate;
    }
  }

  return CategorySubcategoryResolvedSelection(
    category: category,
    subcategory: subcategory,
  );
}

class CategorySubcategorySelector extends StatefulWidget {
  final List<Category> categories;
  final List<Subcategory> subcategories;
  final MovementType type;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final void Function(String categoryId, String? subcategoryId) onChanged;

  const CategorySubcategorySelector({
    super.key,
    required this.categories,
    required this.subcategories,
    required this.type,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.onChanged,
  });

  @override
  State<CategorySubcategorySelector> createState() =>
      _CategorySubcategorySelectorState();
}

class _CategorySubcategorySelectorState
    extends State<CategorySubcategorySelector> {
  Future<void> _openPicker() async {
    final selection = await showModalBottomSheet<_CategorySubcategoryChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategorySubcategoryPickerSheet(
        categories: widget.categories,
        subcategories: widget.subcategories,
        type: widget.type,
        selectedCategoryId: widget.selectedCategoryId,
        selectedSubcategoryId: widget.selectedSubcategoryId,
      ),
    );

    if (selection != null) {
      widget.onChanged(selection.categoryId, selection.subcategoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final surface = StreamSurfaceTokens.card(p, elevated: true);
    final resolved = resolveCategorySubcategorySelection(
      categories: widget.categories,
      subcategories: widget.subcategories,
      type: widget.type,
      categoryId: widget.selectedCategoryId,
      subcategoryId: widget.selectedSubcategoryId,
    );
    final iconKey = resolved?.iconKey ?? StreamIconLibrary.defaultCategoryIcon;
    final color = resolved?.color ?? p.textMuted.toARGB32();

    return InkWell(
      key: const Key('movement_category_subcategory_field'),
      onTap: _openPicker,
      borderRadius: BorderRadius.circular(StreamRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Categoria / Sottocategoria',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(StreamRadius.md)),
            borderSide: BorderSide(
              color: surface.border,
              width: surface.borderWidth,
            ),
          ),
          filled: true,
          fillColor: surface.background,
          suffixIcon: Icon(Icons.arrow_drop_down, color: p.textMuted),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(color),
                borderRadius: BorderRadius.circular(StreamRadius.sm),
              ),
              child: Icon(
                StreamIconLibrary.getIcon(iconKey),
                size: 12,
                color: StreamSurfaceTokens.onAccent(Color(color)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                resolved?.label ?? 'Seleziona categoria',
                style: resolved == null
                    ? StreamTypography.body.copyWith(color: p.textMuted)
                    : StreamTypography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySubcategoryChoice {
  final String categoryId;
  final String? subcategoryId;

  const _CategorySubcategoryChoice({
    required this.categoryId,
    required this.subcategoryId,
  });
}

class _CategorySubcategoryPickerSheet extends StatefulWidget {
  final List<Category> categories;
  final List<Subcategory> subcategories;
  final MovementType type;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;

  const _CategorySubcategoryPickerSheet({
    required this.categories,
    required this.subcategories,
    required this.type,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
  });

  @override
  State<_CategorySubcategoryPickerSheet> createState() =>
      _CategorySubcategoryPickerSheetState();
}

class _CategorySubcategoryPickerSheetState
    extends State<_CategorySubcategoryPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Category> get _activeCategories {
    final items =
        widget.categories
            .where((c) => c.type == widget.type && !c.archived)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  List<Subcategory> _activeSubcategoriesForCategory(String categoryId) {
    final items =
        widget.subcategories
            .where((s) => s.categoryId == categoryId && !s.archived)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  bool _matches(String value) {
    if (_searchQuery.isEmpty) return true;
    return value.toLowerCase().contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final tileSurface = StreamSurfaceTokens.card(p, elevated: true);
    return SafeArea(
      child: Material(
        color: p.canvas,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(StreamRadius.xl),
        ),
        child: KeyedSubtree(
          key: const Key('category_subcategory_picker'),
          child: Padding(
            padding: EdgeInsets.only(
              left: StreamSpacing.lg,
              right: StreamSpacing.lg,
              top: StreamSpacing.lg,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + StreamSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scegli categoria', style: StreamTypography.h3),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.sm),
                TextField(
                  key: const Key('category_subcategory_search_field'),
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cerca categoria o sottocategoria',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: p.textMuted,
                    ),
                    filled: true,
                    fillColor: tileSurface.background,
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim().toLowerCase()),
                ),
                const SizedBox(height: StreamSpacing.md),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final category in _activeCategories) ...[
                        ..._buildCategoryGroup(category),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryGroup(Category category) {
    final p = context.$palette;
    final subcategories = _activeSubcategoriesForCategory(category.id);
    final categoryMatches = _matches(category.name);
    final matchingSubcategories = subcategories
        .where((s) => _matches(s.name))
        .toList();

    if (!categoryMatches && matchingSubcategories.isEmpty) {
      return const <Widget>[];
    }

    final visibleSubcategories = _searchQuery.isEmpty || categoryMatches
        ? subcategories
        : matchingSubcategories;

    final isCategorySelected =
        widget.selectedCategoryId == category.id &&
        widget.selectedSubcategoryId == null;

    return [
      Material(
        color: Colors.transparent,
        child: ListTile(
          key: Key('category_option_${category.id}'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StreamRadius.md),
            side: BorderSide(color: isCategorySelected ? p.primary : p.divider),
          ),
          tileColor: isCategorySelected
              ? p.primary.withValues(alpha: 0.1)
              : p.surfaceElevated,
          leading: _IconSwatch(
            iconKey: category.iconKey,
            color: category.color,
          ),
          title: Text(category.name),
          trailing: isCategorySelected
              ? Icon(Icons.check, color: p.primary)
              : null,
          onTap: () => Navigator.of(context).pop(
            _CategorySubcategoryChoice(
              categoryId: category.id,
              subcategoryId: null,
            ),
          ),
        ),
      ),
      for (final subcategory in visibleSubcategories)
        Material(
          color: Colors.transparent,
          child: ListTile(
            key: Key('subcategory_option_${subcategory.id}'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StreamRadius.md),
              side: BorderSide(
                color: widget.selectedSubcategoryId == subcategory.id
                    ? p.primary
                    : p.divider.withValues(alpha: 0.55),
              ),
            ),
            tileColor: widget.selectedSubcategoryId == subcategory.id
                ? p.primary.withValues(alpha: 0.1)
                : p.surface,
            contentPadding: const EdgeInsets.only(left: 40, right: 8),
            leading: _IconSwatch(
              iconKey: subcategory.iconKey ?? category.iconKey,
              color: subcategory.color ?? category.color,
            ),
            title: Text(subcategory.name),
            trailing: widget.selectedSubcategoryId == subcategory.id
                ? Icon(Icons.check, color: p.primary)
                : null,
            onTap: () => Navigator.of(context).pop(
              _CategorySubcategoryChoice(
                categoryId: category.id,
                subcategoryId: subcategory.id,
              ),
            ),
          ),
        ),
      const SizedBox(height: 4),
    ];
  }
}

class _IconSwatch extends StatelessWidget {
  final String iconKey;
  final int color;

  const _IconSwatch({required this.iconKey, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(StreamRadius.sm),
      ),
      child: Icon(
        StreamIconLibrary.getIcon(iconKey),
        size: 12,
        color: StreamSurfaceTokens.onAccent(Color(color)),
      ),
    );
  }
}

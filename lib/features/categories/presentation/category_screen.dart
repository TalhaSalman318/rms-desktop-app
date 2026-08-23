import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../data/models/database_models.dart';
import '../../../shared/widgets/ui_components.dart';
import 'category_controller.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.controller});

  final CategoryController controller;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 32,
              20,
              compact ? 20 : 32,
              32,
            ),
            child: Column(
              children: [
                SectionHeader(
                  title: 'Category Management',
                  subtitle: 'Organize the menu into clear, reusable groups.',
                  action: PrimaryButton(
                    label: 'Add category',
                    icon: Icons.add_rounded,
                    onPressed: () => _showCategoryDialog(),
                  ),
                ),
                const SizedBox(height: 24),
                SearchField(
                  hint: 'Search categories',
                  width: double.infinity,
                  controller: _searchController,
                  onChanged: (value) => widget.controller.load(search: value),
                ),
                const SizedBox(height: 18),
                Expanded(child: _content(compact)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _content(bool compact) {
    if (widget.controller.isLoading) {
      return const Center(child: LoadingState(label: 'Loading categories'));
    }
    if (widget.controller.errorMessage != null) {
      return Center(
        child: EmptyState(
          title: 'Something went wrong',
          message: widget.controller.errorMessage!,
          icon: Icons.error_outline_rounded,
        ),
      );
    }
    if (widget.controller.categories.isEmpty) {
      final searching = _searchController.text.trim().isNotEmpty;
      return AppCard(
        child: EmptyState(
          title: searching ? 'No matches found' : 'No categories yet',
          message: searching
              ? 'Try a different search term.'
              : 'Add your first menu category to get started.',
          icon: Icons.category_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: compact ? _compactList() : _table(),
    );
  }

  Widget _table() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(flex: 1, child: Text('ID', style: _headerStyle)),
              Expanded(
                flex: 4,
                child: Text('Category name', style: _headerStyle),
              ),
              Expanded(
                flex: 3,
                child: Text('Created date', style: _headerStyle),
              ),
              SizedBox(width: 110, child: Text('Actions', style: _headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: ListView.separated(
            itemCount: widget.controller.categories.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) =>
                _tableRow(widget.controller.categories[index]),
          ),
        ),
      ],
    );
  }

  Widget _tableRow(Category category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('${category.id}')),
          Expanded(
            flex: 4,
            child: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(_formatDate(category.createdAt))),
          SizedBox(
            width: 110,
            child: Row(
              children: [
                _actionButton(
                  Icons.edit_outlined,
                  'Edit category',
                  () => _showCategoryDialog(category),
                ),
                _actionButton(
                  Icons.delete_outline_rounded,
                  'Delete category',
                  () => _delete(category),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactList() => ListView.separated(
    itemCount: widget.controller.categories.length,
    separatorBuilder: (_, _) =>
        const Divider(height: 1, color: AppTheme.border),
    itemBuilder: (context, index) {
      final category = widget.controller.categories[index];
      return ListTile(
        title: Text(category.name),
        subtitle: Text(
          'ID ${category.id}  •  ${_formatDate(category.createdAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(
              Icons.edit_outlined,
              'Edit category',
              () => _showCategoryDialog(category),
            ),
            _actionButton(
              Icons.delete_outline_rounded,
              'Delete category',
              () => _delete(category),
            ),
          ],
        ),
      );
    },
  );

  Widget _actionButton(IconData icon, String tooltip, VoidCallback onPressed) =>
      IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 19, color: AppTheme.textSecondary),
      );

  Future<void> _showCategoryDialog([Category? category]) async {
    final nameController = TextEditingController(text: category?.name);
    final formKey = GlobalKey<FormState>();
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Add category' : 'Edit category'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a category name.'
                        : null,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error!,
                        style: const TextStyle(color: AppTheme.accent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context, false),
            ),
            PrimaryButton(
              label: 'Save',
              icon: Icons.check_rounded,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final result = await widget.controller.save(
                  category: category,
                  name: nameController.text,
                );
                if (result != null) {
                  setDialogState(() => error = result);
                } else if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null
                ? 'Category added successfully.'
                : 'Category updated successfully.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete ${category.name}?',
      message: 'Are you sure you want to delete this category?',
    );
    if (!confirmed || !mounted) return;
    final result = await widget.controller.remove(category);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result ?? 'Category deleted successfully.')),
    );
  }

  static String _formatDate(String? value) =>
      value == null ? 'Unknown' : value.split(' ').first;
}

const _headerStyle = TextStyle(
  color: AppTheme.textSecondary,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);

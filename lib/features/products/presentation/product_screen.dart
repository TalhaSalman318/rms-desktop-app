import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../data/models/database_models.dart';
import '../../../shared/widgets/ui_components.dart';
import 'product_controller.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.controller});
  final ProductController controller;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
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
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
        child: Column(
          children: [
            SectionHeader(
              title: 'Product Management',
              subtitle: 'Manage your active menu and pricing.',
              action: PrimaryButton(
                label: 'Add product',
                icon: Icons.add_rounded,
                onPressed: _showDialog,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchController,
                    hint: 'Search products',
                    onChanged: (value) => widget.controller.load(search: value),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int>(
                    initialValue: widget.controller.categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem<int>(
                        child: Text('All categories'),
                      ),
                      ...widget.controller.categories.map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        widget.controller.load(categoryId: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (widget.controller.loading) {
      return const Center(child: LoadingState(label: 'Loading products'));
    }
    if (widget.controller.error != null) {
      return Center(
        child: EmptyState(
          title: 'Unable to load products',
          message: widget.controller.error!,
        ),
      );
    }
    if (widget.controller.products.isEmpty) {
      return const AppCard(
        child: EmptyState(
          title: 'No products yet',
          message: 'Add a product after creating categories.',
          icon: Icons.restaurant_menu_rounded,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: widget.controller.products.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppTheme.border),
        itemBuilder: (context, index) {
          final product = widget.controller.products[index];
          return ListTile(
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'ID ${product.id}  •  ${product.description.isEmpty ? 'No description' : product.description}',
            ),
            leading: StatusBadge(
              label: product.isActive ? 'Active' : 'Inactive',
              color: product.isActive ? Colors.greenAccent : Colors.grey,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Rs. ${product.price.toStringAsFixed(2)}'),
                IconButton(
                  tooltip: 'Edit product',
                  onPressed: () => _showDialog(product),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: product.isActive
                      ? 'Deactivate product'
                      : 'Activate product',
                  onPressed: () => widget.controller.toggle(product),
                  icon: Icon(
                    product.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete product',
                  onPressed: () => _delete(product),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDialog([Product? product]) async {
    if (widget.controller.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a category before adding products.'),
        ),
      );
      return;
    }
    final name = TextEditingController(text: product?.name);
    final price = TextEditingController(text: product?.price.toString());
    final description = TextEditingController(text: product?.description);
    final formKey = GlobalKey<FormState>();
    var categoryId =
        product?.categoryId ?? widget.controller.categories.first.id;
    var active = product?.isActive ?? true;
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Add product' : 'Edit product'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a name.'
                        : null,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: widget.controller.categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => categoryId = value),
                    validator: (value) =>
                        value == null ? 'Select a category.' : null,
                  ),
                  TextFormField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Price'),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      return parsed == null || parsed <= 0
                          ? 'Enter a price greater than zero.'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: description,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(color: AppTheme.accent),
                    ),
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
              icon: Icons.check,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final result = await widget.controller.save(
                  product: product,
                  name: name.text,
                  categoryId: categoryId!,
                  price: double.parse(price.text),
                  description: description.text,
                  active: active,
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
    name.dispose();
    price.dispose();
    description.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null ? 'Product added.' : 'Product updated.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(Product product) async {
    if (!await showConfirmationDialog(
      context,
      title: 'Delete ${product.name}?',
      message: 'Products used in orders cannot be deleted.',
    )) {
      return;
    }
    final result = await widget.controller.remove(product);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result ?? 'Product deleted.')));
    }
  }
}

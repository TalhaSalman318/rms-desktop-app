import 'package:flutter/material.dart';

import '../../../data/models/database_models.dart';
import '../../../shared/widgets/ui_components.dart';
import '../data/deal_repository.dart';
import '../../products/data/product_repository.dart';

class DealScreen extends StatefulWidget {
  const DealScreen({
    super.key,
    required this.repository,
    required this.products,
  });
  final DealRepository repository;
  final ProductRepository products;
  @override
  State<DealScreen> createState() => _DealScreenState();
}

class _DealScreenState extends State<DealScreen> {
  List<Deal> deals = [];
  List<Product> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    deals = await widget.repository.getDeals();
    products = await widget.products.getProducts(activeOnly: true);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: LoadingState(label: 'Loading deals'));
    } else if (deals.isEmpty) {
      body = const AppCard(
        child: EmptyState(
          title: 'No deals yet',
          message: 'Add a deal using active products.',
          icon: Icons.local_offer_outlined,
        ),
      );
    } else {
      body = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: deals.length,
        itemBuilder: (context, index) => _tile(deals[index]),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsivePageInset(context),
        20,
        responsivePageInset(context),
        32,
      ),
      child: Column(
        children: [
          SectionHeader(
            title: 'Deals',
            subtitle: 'Build bundles from active products.',
            action: PrimaryButton(
              label: 'Add deal',
              icon: Icons.add,
              onPressed: _edit,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: SingleChildScrollView(child: body)),
        ],
      ),
    );
  }

  Widget _tile(Deal deal) {
    return AppCard(
      child: ListTile(
        title: Text(
          deal.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Savings: Rs. ${(deal.normalPrice - deal.dealPrice).toStringAsFixed(2)}',
        ),
        trailing: MediaQuery.sizeOf(context).width < 600
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'toggle') {
                    await widget.repository.setActive(deal, !deal.isActive);
                    load();
                  } else if (value == 'edit') {
                    _edit(deal);
                  } else {
                    _delete(deal);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      deal.isActive ? 'Deactivate deal' : 'Activate deal',
                    ),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit deal')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete deal'),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rs. ${deal.dealPrice.toStringAsFixed(2)}'),
                  IconButton(
                    onPressed: () async {
                      await widget.repository.setActive(deal, !deal.isActive);
                      load();
                    },
                    icon: Icon(
                      deal.isActive
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _edit(deal),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete deal',
                    onPressed: () => _delete(deal),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _edit([Deal? existing]) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create active products first.')),
      );
      return;
    }
    final name = TextEditingController(text: existing?.name);
    final normal = TextEditingController(
      text: existing?.normalPrice.toString(),
    );
    final price = TextEditingController(text: existing?.dealPrice.toString());
    final selected = <int, int>{};
    if (existing != null) {
      for (final item in await widget.repository.items(existing.id!)) {
        selected[item.productId] = item.quantity;
      }
    }
    if (!mounted) return;
    String? validationError;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add deal' : 'Edit deal'),
            content: SizedBox(
              width: responsiveDialogWidth(context, 520),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Deal name'),
                    ),
                    TextField(
                      controller: normal,
                      decoration: const InputDecoration(
                        labelText: 'Normal price',
                      ),
                    ),
                    TextField(
                      controller: price,
                      decoration: const InputDecoration(
                        labelText: 'Deal price',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Select products'),
                    ),
                    ...products.map((product) {
                      final quantity = selected[product.id] ?? 0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Checkbox(
                          value: quantity > 0,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selected[product.id!] = quantity == 0
                                    ? 1
                                    : quantity;
                              } else {
                                selected.remove(product.id);
                              }
                            });
                          },
                        ),
                        title: Text(product.name),
                        trailing: quantity == 0
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => setDialogState(() {
                                      if (quantity <= 1) {
                                        selected.remove(product.id);
                                      } else {
                                        selected[product.id!] = quantity - 1;
                                      }
                                    }),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text('$quantity'),
                                  IconButton(
                                    onPressed: () => setDialogState(() {
                                      selected[product.id!] = quantity + 1;
                                    }),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                      );
                    }),
                    if (validationError != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          validationError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              SecondaryButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              PrimaryButton(
                label: 'Save',
                onPressed: () async {
                  final normalValue = double.tryParse(normal.text) ?? 0;
                  final dealValue = double.tryParse(price.text) ?? 0;
                  if (name.text.trim().isEmpty ||
                      dealValue <= 0 ||
                      dealValue > normalValue ||
                      selected.isEmpty) {
                    setDialogState(
                      () => validationError =
                          'Enter valid prices and select products.',
                    );
                    return;
                  }
                  final deal = Deal(
                    id: existing?.id,
                    name: name.text.trim(),
                    normalPrice: normalValue,
                    dealPrice: dealValue,
                    isActive: existing?.isActive ?? true,
                    description: '',
                    createdAt: existing?.createdAt,
                  );
                  final items = selected.entries
                      .map(
                        (entry) => DealItem(
                          dealId: existing?.id ?? 0,
                          productId: entry.key,
                          quantity: entry.value,
                        ),
                      )
                      .toList();
                  try {
                    await widget.repository.save(deal, items);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  } on DealValidationException catch (error) {
                    setDialogState(() => validationError = error.message);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
    name.dispose();
    normal.dispose();
    price.dispose();
    if (saved == true) load();
  }

  Future<void> _delete(Deal deal) async {
    if (!await showConfirmationDialog(
      context,
      title: 'Delete ${deal.name}?',
      message: 'This removes the deal from future POS orders.',
    )) {
      return;
    }
    await widget.repository.delete(deal);
    await load();
  }
}

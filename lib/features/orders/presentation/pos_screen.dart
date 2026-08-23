import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/ui_components.dart';
import '../../deals/data/deal_repository.dart';
import '../data/order_repository.dart';
import 'pos_controller.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.controller});
  final PosController controller;
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
          child: Column(
            children: [
              SectionHeader(
                title: 'New Order',
                subtitle: 'Build an order with current menu prices.',
                action: SecondaryButton(
                  label: 'Clear cart',
                  icon: Icons.delete_sweep_outlined,
                  onPressed: widget.controller.cart.isEmpty
                      ? null
                      : widget.controller.clear,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _productList()),
                    const SizedBox(width: 18),
                    SizedBox(width: 390, child: _cartPanel()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _productList() {
    if (widget.controller.loading) {
      return const Center(child: LoadingState(label: 'Loading products'));
    }
    if (widget.controller.available.isEmpty &&
        widget.controller.deals.isEmpty) {
      return const EmptyState(
        title: 'No active products',
        message: 'Create and activate products to take orders.',
        icon: Icons.restaurant_menu_outlined,
      );
    }
    return ListView(
      children: [
        if (widget.controller.deals.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Active deals',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...widget.controller.deals.map(_dealCard),
        ],
        ...widget.controller.available.map((product) {
          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Rs. ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                PrimaryButton(
                  label: 'Add',
                  icon: Icons.add_rounded,
                  onPressed: () => widget.controller.add(product),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _dealCard(DealWithItems deal) => AppCard(
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${deal.deal.name}\nRs. ${deal.deal.dealPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        PrimaryButton(
          label: 'Add deal',
          icon: Icons.local_offer_outlined,
          onPressed: () => widget.controller.addDeal(deal),
        ),
      ],
    ),
  );

  Widget _cartPanel() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Current order', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Expanded(
          child: widget.controller.cart.isEmpty
              ? const EmptyState(
                  title: 'Cart is empty',
                  message: 'Add products to start an order.',
                  icon: Icons.shopping_cart_outlined,
                )
              : ListView(
                  children: widget.controller.cart.map(_cartLine).toList(),
                ),
        ),
        const Divider(),
        _summary(),
      ],
    ),
  );
  Widget _summary() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Subtotal'),
          Text('Rs. ${widget.controller.subtotal.toStringAsFixed(2)}'),
        ],
      ),
      TextField(
        decoration: const InputDecoration(labelText: 'Discount'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) =>
            widget.controller.setDiscount(double.tryParse(value) ?? 0),
      ),
      DropdownButtonFormField<String>(
        initialValue: widget.controller.paymentMethod,
        decoration: const InputDecoration(labelText: 'Payment'),
        items: ['Cash', 'Card', 'Online']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) {
          if (value != null) widget.controller.setPaymentMethod(value);
        },
      ),
      DropdownButtonFormField<String>(
        initialValue: widget.controller.status,
        decoration: const InputDecoration(labelText: 'Status'),
        items: ['Completed', 'Pending', 'Cancelled']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) {
          if (value != null) widget.controller.setStatus(value);
        },
      ),
      const SizedBox(height: 10),
      Text(
        'Grand total  Rs. ${widget.controller.total.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 10),
      PrimaryButton(
        label: 'Place order',
        icon: Icons.check_circle_outline,
        onPressed: widget.controller.loading ? null : _place,
      ),
    ],
  );
  Widget _cartLine(CartLine line) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      line.deal == null ? line.product!.name : 'Deal: ${line.deal!.deal.name}',
    ),
    subtitle: Text(
      'Rs. ${line.unitPrice.toStringAsFixed(2)} × ${line.quantity}',
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => widget.controller.changeLine(line, -1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${line.quantity}'),
        IconButton(
          onPressed: () => widget.controller.changeLine(line, 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
        Text('  Rs. ${line.subtotal.toStringAsFixed(2)}'),
      ],
    ),
  );
  Future<void> _place() async {
    final number = await widget.controller.place();
    if (number != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$number placed successfully.')),
      );
    }
  }
}

import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/database_models.dart';
import '../../../shared/widgets/ui_components.dart';
import '../data/order_repository.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.repository});
  final OrderRepository repository;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final search = TextEditingController();
  List<Order> orders = [];
  String? status;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    orders = await widget.repository.getOrders(
      search: search.text,
      status: status,
    );
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsivePageInset(context),
        20,
        responsivePageInset(context),
        32,
      ),
      child: Column(
        children: [
          const SectionHeader(
            title: 'Orders History',
            subtitle: 'Review every order recorded in MongoDB Atlas.',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 600;
              const statusOptions = ['Completed', 'Pending', 'Cancelled'];
              final statusField = SizedBox(
                width: narrow ? double.infinity : 170,
                child: DropdownButtonFormField<String>(
                  initialValue: dropdownValueOrNull(status, statusOptions),
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<String>(child: Text('All statuses')),
                    ...statusOptions.map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    ),
                  ],
                  onChanged: (value) {
                    status = value;
                    _load();
                  },
                ),
              );
              final searchField = SearchField(
                controller: search,
                hint: 'Search orders',
                onChanged: (_) => _load(),
              );
              return narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 12),
                        statusField,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        statusField,
                      ],
                    );
            },
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(child: LoadingState(label: 'Loading orders'));
    }
    if (orders.isEmpty) {
      return const AppCard(
        child: EmptyState(
          title: 'No orders yet',
          message: 'Orders placed from the POS will appear here.',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppTheme.border),
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            title: Text(
              '#${order.orderNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${order.orderDate.replaceFirst('T', ' ').split('.').first}  •  ${order.paymentMethod}',
            ),
            leading: StatusBadge(
              label: order.status,
              color: order.status == 'Completed'
                  ? Colors.greenAccent
                  : order.status == 'Cancelled'
                  ? Colors.redAccent
                  : Colors.orangeAccent,
            ),
            trailing: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = MediaQuery.sizeOf(context).width < 600;
                if (narrow) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') _details(order);
                      if (value == 'cancel') _cancel(order);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View order'),
                      ),
                      if (order.status != 'Cancelled')
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancel order'),
                        ),
                    ],
                  );
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rs. ${order.totalAmount.toStringAsFixed(2)}'),
                    IconButton(
                      tooltip: 'View order',
                      onPressed: () => _details(order),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    if (order.status != 'Cancelled')
                      IconButton(
                        tooltip: 'Cancel order',
                        onPressed: () => _cancel(order),
                        icon: const Icon(Icons.cancel_outlined),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _details(Order order) async {
    final items = await widget.repository.getItems(order.id!);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.orderNumber}'),
        content: SizedBox(
          width: responsiveDialogWidth(context, 470),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.orderDate.replaceFirst('T', ' ').split('.').first}  •  ${order.paymentMethod}',
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => Text(
                  '${item.dealName ?? 'Product #${item.productId}'}   ${item.quantity} × Rs. ${item.unitPrice.toStringAsFixed(2)} = Rs. ${item.subtotal.toStringAsFixed(2)}',
                ),
              ),
              const Divider(),
              Text('Subtotal: Rs. ${order.subtotal.toStringAsFixed(2)}'),
              Text('Discount: Rs. ${order.discount.toStringAsFixed(2)}'),
              Text(
                'Grand total: Rs. ${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          PrimaryButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(Order order) async {
    if (!await showConfirmationDialog(
      context,
      title: 'Cancel order #${order.orderNumber}?',
      message:
          'The order will remain in history but no longer count as completed sales.',
    )) {
      return;
    }
    await widget.repository.cancel(order);
    await _load();
  }
}

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
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        children: [
          const SectionHeader(
            title: 'Orders History',
            subtitle: 'Review every order recorded in SQLite.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SearchField(
                  controller: search,
                  hint: 'Search orders',
                  onChanged: (_) => _load(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<String>(child: Text('All statuses')),
                    ...['Completed', 'Pending', 'Cancelled'].map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    ),
                  ],
                  onChanged: (value) {
                    status = value;
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: _body()),
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
            trailing: Row(
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
          width: 470,
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
                  'Product #${item.productId}   ${item.quantity} × Rs. ${item.unitPrice.toStringAsFixed(2)} = Rs. ${item.subtotal.toStringAsFixed(2)}',
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

import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/ui_components.dart';
import '../data/dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository});
  final DashboardRepository repository;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? stats;
  List<Map<String, Object?>> recent = const [];
  List<Map<String, Object?>> top = const [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      stats = await widget.repository.stats();
      recent = await widget.repository.recentOrders();
      top = await widget.repository.topProducts();
    } catch (_) {
      error = 'Unable to load dashboard data.';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Dashboard',
              subtitle: 'A live view of your restaurant operations.',
            ),
            const SizedBox(height: 28),
            if (loading)
              const Center(child: LoadingState(label: 'Loading dashboard'))
            else if (error != null)
              Center(
                child: EmptyState(
                  title: 'Dashboard unavailable',
                  message: error!,
                ),
              )
            else
              _cards(stats!),
            const SizedBox(height: 24),
            _activity('Recent orders', recent, Icons.receipt_long_outlined),
            const SizedBox(height: 16),
            _activity('Top products', top, Icons.restaurant_menu_outlined),
          ],
        ),
      ),
    );
  }

  Widget _cards(DashboardStats value) => GridView.count(
    crossAxisCount: MediaQuery.sizeOf(context).width > 1050 ? 3 : 2,
    crossAxisSpacing: 14,
    mainAxisSpacing: 14,
    childAspectRatio: 2.25,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      StatCard(
        label: "Today's sales",
        value: _money(value.todaySales),
        icon: Icons.trending_up_rounded,
      ),
      StatCard(
        label: "Today's orders",
        value: '${value.todayOrders}',
        icon: Icons.receipt_long_rounded,
        accentColor: const Color(0xFF62B7A5),
      ),
      StatCard(
        label: 'Monthly sales',
        value: _money(value.monthSales),
        icon: Icons.calendar_month_rounded,
        accentColor: const Color(0xFF8E9BE8),
      ),
      StatCard(
        label: 'Monthly expenses',
        value: _money(value.monthExpenses),
        icon: Icons.payments_outlined,
        accentColor: const Color(0xFFE6A85C),
      ),
      StatCard(
        label: 'Monthly profit',
        value: _money(value.monthProfit),
        icon: Icons.account_balance_wallet_outlined,
        accentColor: const Color(0xFF62B7A5),
      ),
      StatCard(
        label: 'Yearly sales',
        value: _money(value.yearSales),
        icon: Icons.auto_graph_rounded,
        accentColor: const Color(0xFF8E9BE8),
      ),
    ],
  );
  String _money(double value) => 'Rs. ${value.toStringAsFixed(2)}';

  Widget _activity(
    String title,
    List<Map<String, Object?>> values,
    IconData icon,
  ) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (values.isEmpty)
          const EmptyState(
            title: 'No activity yet',
            message: 'Completed orders will appear here.',
            icon: Icons.inbox_outlined,
          )
        else
          ...values.map(
            (row) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: AppTheme.accent),
              title: Text(row['name']?.toString() ?? '#${row['order_number']}'),
              subtitle: Text(
                row['payment_method']?.toString() ?? '${row['quantity']} units',
              ),
              trailing: Text(
                'Rs. ${row['total_amount'] ?? row['revenue'] ?? 0}',
              ),
            ),
          ),
      ],
    ),
  );
}

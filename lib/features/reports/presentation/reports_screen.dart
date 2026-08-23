import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/ui_components.dart';
import '../data/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});
  final ReportRepository repository;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime from = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime to = DateTime.now().add(const Duration(days: 1));
  String period = 'Daily';
  ReportSummary? summary;
  List<Map<String, Object?>> products = [];
  List<Map<String, Object?>> payments = [];
  List<Map<String, Object?>> categories = [];
  List<Map<String, Object?>> trend = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    summary = await widget.repository.summary(from, to);
    products = await widget.repository.products(from, to);
    payments = await widget.repository.payments(from, to);
    categories = await widget.repository.categories(from, to);
    trend = await widget.repository.trend(from, to);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
    child: Column(
      children: [
        SectionHeader(
          title: 'Reports',
          subtitle: 'Analyze completed sales and expenses.',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: period,
                  items: ['Daily', 'Monthly', 'Yearly', 'Custom range']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    period = value;
                    _setPeriod();
                  },
                ),
              ),
              if (period == 'Custom range') ...[
                const SizedBox(width: 8),
                SecondaryButton(
                  label: 'Choose dates',
                  icon: Icons.date_range,
                  onPressed: _pickRange,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: loading
              ? const Center(child: LoadingState(label: 'Loading report'))
              : ListView(
                  children: [
                    _cards(),
                    const SizedBox(height: 16),
                    _trend(),
                    const SizedBox(height: 16),
                    _table('Product sales', products, 'name'),
                    const SizedBox(height: 16),
                    _table('Payment breakdown', payments, 'payment_method'),
                    const SizedBox(height: 16),
                    _table('Category sales', categories, 'name'),
                  ],
                ),
        ),
      ],
    ),
  );
  Widget _cards() => GridView.count(
    crossAxisCount: 4,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12,
    children: [
      StatCard(
        label: 'Orders',
        value: '${summary!.orders}',
        icon: Icons.receipt_long,
      ),
      StatCard(
        label: 'Sales',
        value: 'Rs. ${summary!.sales.toStringAsFixed(2)}',
        icon: Icons.trending_up,
      ),
      StatCard(
        label: 'Expenses',
        value: 'Rs. ${summary!.expenses.toStringAsFixed(2)}',
        icon: Icons.payments,
      ),
      StatCard(
        label: 'Profit',
        value: 'Rs. ${summary!.profit.toStringAsFixed(2)}',
        icon: Icons.account_balance_wallet,
      ),
    ],
  );
  Widget _trend() => AppCard(
    child: SizedBox(
      height: 220,
      child: trend.isEmpty
          ? const EmptyState(
              title: 'No sales trend',
              message: 'Completed orders will appear here.',
              icon: Icons.show_chart,
            )
          : LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppTheme.accent,
                    spots: [
                      for (var i = 0; i < trend.length; i++)
                        FlSpot(
                          i.toDouble(),
                          (trend[i]['sales'] as num).toDouble(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    ),
  );
  Widget _table(
    String title,
    List<Map<String, Object?>> rows,
    String labelKey,
  ) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const EmptyState(
            title: 'No data',
            message: 'Nothing was recorded in this period.',
          )
        else
          ...rows.map(
            (row) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${row[labelKey]}'),
              subtitle: Text('${row['quantity'] ?? row['orders'] ?? 0}'),
              trailing: Text('Rs. ${row['revenue'] ?? 0}'),
            ),
          ),
      ],
    ),
  );
  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: from,
        end: to.subtract(const Duration(days: 1)),
      ),
    );
    if (picked != null) {
      from = picked.start;
      to = picked.end.add(const Duration(days: 1));
      load();
    }
  }

  void _setPeriod() {
    final now = DateTime.now();
    if (period == 'Daily') {
      from = DateTime(now.year, now.month, now.day);
      to = from.add(const Duration(days: 1));
    } else if (period == 'Monthly') {
      from = DateTime(now.year, now.month);
      to = DateTime(now.year, now.month + 1);
    } else if (period == 'Yearly') {
      from = DateTime(now.year);
      to = DateTime(now.year + 1);
    }
    load();
  }
}

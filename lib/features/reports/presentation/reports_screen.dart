import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../core/services/local_pdf_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../shared/widgets/ui_components.dart';
import '../data/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository, this.pdfService});
  final ReportRepository repository;
  final PdfService? pdfService;
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
  List<Map<String, Object?>> expenseCategories = [];
  ReportData? reportData;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    reportData = await widget.repository.load(from, to);
    summary = reportData!.summary;
    products = reportData!.products;
    payments = reportData!.payments;
    categories = reportData!.categories;
    expenseCategories = reportData!.expenseCategories;
    trend = reportData!.trend;
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
                  items:
                      [
                            'Today',
                            'Yesterday',
                            'This week',
                            'This month',
                            'This year',
                            'Custom range',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
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
              PopupMenuButton<String>(
                tooltip: 'Export report',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onSelected: _export,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'save', child: Text('Save PDF')),
                  PopupMenuItem(value: 'preview', child: Text('Preview PDF')),
                  PopupMenuItem(value: 'print', child: Text('Print PDF')),
                ],
              ),
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
                    _distributionCharts(),
                    const SizedBox(height: 16),
                    _table('Product sales', products, 'name'),
                    const SizedBox(height: 16),
                    _table('Payment breakdown', payments, 'payment_method'),
                    const SizedBox(height: 16),
                    _table('Category sales', categories, 'name'),
                    const SizedBox(height: 16),
                    _table('Expense breakdown', expenseCategories, 'name'),
                  ],
                ),
        ),
      ],
    ),
  );
  Widget _cards() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns == 1 ? 4.2 : 2.2,
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
    },
  );

  Widget _distributionCharts() => LayoutBuilder(
    builder: (context, constraints) {
      final payment = _paymentChart();
      final category = _categoryChart();
      if (constraints.maxWidth < 760) {
        return Column(
          children: [payment, const SizedBox(height: 16), category],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: payment),
          const SizedBox(width: 16),
          Expanded(child: category),
        ],
      );
    },
  );

  Widget _paymentChart() {
    const colors = {
      'Cash': AppTheme.accent,
      'Card': Colors.lightBlueAccent,
      'Online': Colors.orangeAccent,
    };
    final values = {
      for (final method in colors.keys)
        method: _rowAmount(payments, 'payment_method', method, 'revenue'),
    };
    final total = values.values.fold<double>(0, (sum, value) => sum + value);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment method sales',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: total == 0
                ? const EmptyState(
                    title: 'No payment sales',
                    message: 'Completed orders will appear here.',
                    icon: Icons.pie_chart_outline,
                  )
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 48,
                      sectionsSpace: 3,
                      sections: [
                        for (final entry in values.entries)
                          PieChartSectionData(
                            value: entry.value,
                            color: colors[entry.key],
                            title: '${(entry.value / total * 100).round()}%',
                            radius: 72,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {},
                      ),
                    ),
                  ),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final entry in values.entries)
                _legend(
                  '${entry.key}: Rs. ${entry.value.toStringAsFixed(2)}',
                  colors[entry.key]!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryChart() {
    final visible = categories
        .where((row) => _rowAmountValue(row, 'revenue') > 0)
        .toList();
    final maxRevenue = visible.fold<double>(
      0,
      (max, row) => max > _rowAmountValue(row, 'revenue')
          ? max
          : _rowAmountValue(row, 'revenue'),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category-wise sales',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: visible.isEmpty
                ? const EmptyState(
                    title: 'No category sales',
                    message: 'Completed product sales will appear here.',
                    icon: Icons.bar_chart_rounded,
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxRevenue == 0 ? 1 : maxRevenue * 1.2,
                      barGroups: [
                        for (var index = 0; index < visible.length; index++)
                          BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _rowAmountValue(visible[index], 'revenue'),
                                color: AppTheme.accent,
                                width: 20,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                      ],
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                              BarTooltipItem(
                                '${visible[groupIndex]['name']}\nRs. ${rod.toY.toStringAsFixed(2)}',
                                const TextStyle(fontWeight: FontWeight.bold),
                              ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= visible.length) {
                                return const SizedBox.shrink();
                              }
                              final name = '${visible[index]['name']}';
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  name.length > 10
                                      ? '${name.substring(0, 10)}...'
                                      : name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
          if (categories.length > visible.length)
            Text(
              '${categories.length - visible.length} categor${categories.length - visible.length == 1 ? 'y has' : 'ies have'} no sales in this period.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, color: color),
      const SizedBox(width: 6),
      Text(label),
    ],
  );

  double _rowAmount(
    List<Map<String, Object?>> rows,
    String key,
    String value,
    String amountKey,
  ) => rows
      .where((row) => row[key] == value)
      .fold<double>(0, (sum, row) => sum + _rowAmountValue(row, amountKey));

  double _rowAmountValue(Map<String, Object?> row, String key) =>
      (row[key] as num?)?.toDouble() ?? 0;
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
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.orangeAccent,
                    spots: [
                      for (var i = 0; i < trend.length; i++)
                        FlSpot(
                          i.toDouble(),
                          (trend[i]['expenses'] as num).toDouble(),
                        ),
                    ],
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.lightGreenAccent,
                    spots: [
                      for (var i = 0; i < trend.length; i++)
                        FlSpot(
                          i.toDouble(),
                          (trend[i]['profit'] as num).toDouble(),
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
              trailing: Text('Rs. ${row['revenue'] ?? row['amount'] ?? 0}'),
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
    if (period == 'Today' || period == 'Daily') {
      from = DateTime(now.year, now.month, now.day);
      to = from.add(const Duration(days: 1));
    } else if (period == 'Yesterday') {
      to = DateTime(now.year, now.month, now.day);
      from = to.subtract(const Duration(days: 1));
    } else if (period == 'This week') {
      final today = DateTime(now.year, now.month, now.day);
      from = today.subtract(Duration(days: today.weekday - 1));
      to = from.add(const Duration(days: 7));
    } else if (period == 'This month' || period == 'Monthly') {
      from = DateTime(now.year, now.month);
      to = DateTime(now.year, now.month + 1);
    } else if (period == 'This year' || period == 'Yearly') {
      from = DateTime(now.year);
      to = DateTime(now.year + 1);
    }
    load();
  }

  Future<void> _export(String action) async {
    final data = reportData;
    if (data == null) return;
    final service = widget.pdfService ?? LocalPdfService();
    try {
      final bytes = await service.generateReport(
        reportName: period,
        data: data,
        from: from,
        to: to,
      );
      if (action == 'preview') {
        await service.previewReport(bytes);
      } else if (action == 'print') {
        await service.printReport(bytes);
      } else {
        final destination = await FilePicker.platform.saveFile(
          dialogTitle: 'Save report PDF',
          fileName:
              'restaurant_report_${from.year}_${from.month}_${from.day}.pdf',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (destination != null) await File(destination).writeAsBytes(bytes);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'save' ? 'PDF saved.' : 'PDF action completed.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to generate PDF: $error')),
        );
      }
    }
  }
}

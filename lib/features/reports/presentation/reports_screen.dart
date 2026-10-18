import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  DateTime from = DateTime.now().toUtc();
  DateTime to = DateTime.now().toUtc().add(const Duration(days: 1));
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
    if (mounted) setState(() => loading = true);
    try {
      reportData = await widget.repository.load(from, to);
      summary = reportData!.summary;
      products = reportData!.products;
      payments = reportData!.payments;
      categories = reportData!.categories;
      expenseCategories = reportData!.expenseCategories;
      trend = reportData!.trend;
    } catch (_) {
      reportData = null;
      summary = const ReportSummary(orders: 0, sales: 0, expenses: 0);
      products = const [];
      payments = const [];
      categories = const [];
      expenseCategories = const [];
      trend = const [];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const periodOptions = [
      'Daily',
      'Weekly',
      'Monthly',
      'Yearly',
      'Custom range',
    ];
    final selectedPeriod =
        dropdownValueOrNull(period, periodOptions) ?? periodOptions.first;
    final compact = MediaQuery.sizeOf(context).width < 760;
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
            title: 'Reports',
            subtitle: 'Analyze completed sales and expenses.',
            action: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              children: [
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedPeriod,
                    items: periodOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
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
                if (selectedPeriod == 'Custom range')
                  SecondaryButton(
                    label: 'Choose dates',
                    icon: Icons.date_range,
                    onPressed: _pickRange,
                  ),
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
                      _table('Product sales', products, 'name'),
                      const SizedBox(height: 16),
                      _table('Payment breakdown', payments, 'payment_method'),
                      const SizedBox(height: 16),
                      _table('Expense breakdown', expenseCategories, 'name'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cards() => ResponsiveStatGrid(
    desktopColumns: 4,
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
    final now = DateTime.now().toUtc();
    if (period == 'Today' || period == 'Daily') {
      from = DateTime.utc(now.year, now.month, now.day);
      to = from.add(const Duration(days: 1));
    } else if (period == 'Yesterday') {
      to = DateTime.utc(now.year, now.month, now.day);
      from = to.subtract(const Duration(days: 1));
    } else if (period == 'Weekly' || period == 'This week') {
      final today = DateTime.utc(now.year, now.month, now.day);
      from = today.subtract(Duration(days: today.weekday - 1));
      to = from.add(const Duration(days: 7));
    } else if (period == 'Monthly' || period == 'This month') {
      from = DateTime.utc(now.year, now.month);
      to = DateTime.utc(now.year, now.month + 1);
    } else if (period == 'Yearly' || period == 'This year') {
      from = DateTime.utc(now.year);
      to = DateTime.utc(now.year + 1);
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

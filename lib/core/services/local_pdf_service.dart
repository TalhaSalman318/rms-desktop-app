import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/reports/data/report_repository.dart';
import 'pdf_service.dart';

class LocalPdfService implements PdfService {
  @override
  Future<Uint8List> generateReport({
    required String reportName,
    required ReportData data,
    required DateTime from,
    required DateTime to,
  }) async {
    final document = pw.Document();
    final summary = data.summary;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('RESTAURANT REPORT')),
          pw.Text(
            '$reportName: ${_date(from)} - ${_date(to.subtract(const Duration(days: 1)))}',
          ),
          pw.Text('Generated: ${DateTime.now().toLocal()}'),
          pw.SizedBox(height: 18),
          _section('SUMMARY', [
            ['Total sales', _money(summary.sales)],
            ['Total orders', '${summary.totalOrders}'],
            ['Completed orders', '${summary.completedOrders}'],
            ['Pending orders', '${summary.pendingOrders}'],
            ['Cancelled orders', '${summary.cancelledOrders}'],
            ['Total discounts', _money(summary.discount)],
            ['Total expenses', _money(summary.expenses)],
            ['Profit', _money(summary.profit)],
          ]),
          pw.SizedBox(height: 14),
          _table(
            'SALES BREAKDOWN',
            ['Product', 'Quantity', 'Revenue'],
            data.products,
            (row) => [
              '${row['name']}',
              '${row['quantity'] ?? 0}',
              _money((row['revenue'] as num?)?.toDouble() ?? 0),
            ],
          ),
          _table(
            'CATEGORY BREAKDOWN',
            ['Category', 'Quantity', 'Revenue'],
            data.categories,
            (row) => [
              '${row['name']}',
              '${row['quantity'] ?? 0}',
              _money((row['revenue'] as num?)?.toDouble() ?? 0),
            ],
          ),
          _table(
            'PAYMENT BREAKDOWN',
            ['Payment method', 'Orders', 'Revenue'],
            data.payments,
            (row) => [
              '${row['payment_method']}',
              '${row['orders'] ?? 0}',
              _money((row['revenue'] as num?)?.toDouble() ?? 0),
            ],
          ),
          _table(
            'EXPENSE BREAKDOWN',
            ['Category', 'Count', 'Amount'],
            data.expenseCategories,
            (row) => [
              '${row['name']}',
              '${row['count'] ?? 0}',
              _money((row['amount'] as num?)?.toDouble() ?? 0),
            ],
          ),
        ],
      ),
    );
    return document.save();
  }

  @override
  Future<void> previewReport(Uint8List bytes) =>
      Printing.layoutPdf(onLayout: (format) async => bytes);

  @override
  Future<void> printReport(Uint8List bytes) =>
      Printing.layoutPdf(onLayout: (format) async => bytes);

  pw.Widget _section(String title, List<List<String>> rows) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(data: rows),
    ],
  );

  pw.Widget _table(
    String title,
    List<String> headers,
    List<Map<String, Object?>> rows,
    List<String> Function(Map<String, Object?>) values,
  ) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 14),
      pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows.map(values).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    ],
  );

  String _money(double value) => 'Rs. ${value.toStringAsFixed(2)}';
  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

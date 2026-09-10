import 'dart:typed_data';

import '../../features/reports/data/report_repository.dart';

abstract interface class PdfService {
  Future<Uint8List> generateReport({
    required String reportName,
    required ReportData data,
    required DateTime from,
    required DateTime to,
  });

  Future<void> previewReport(Uint8List bytes);

  Future<void> printReport(Uint8List bytes);
}

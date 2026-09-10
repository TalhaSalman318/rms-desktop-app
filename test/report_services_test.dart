import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/core/services/backup_service.dart';
import 'package:rms_desktop_app/core/services/local_pdf_service.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:rms_desktop_app/features/reports/data/report_repository.dart';

void main() {
  test('generates a PDF for an empty report', () async {
    final bytes = await LocalPdfService().generateReport(
      reportName: 'Daily',
      data: const ReportData(
        summary: ReportSummary(orders: 0, sales: 0, expenses: 0),
        products: [],
        payments: [],
        categories: [],
        expenseCategories: [],
        trend: [],
      ),
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 1, 2),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('backs up and restores a valid SQLite database', () async {
    final directory = await Directory.systemTemp.createTemp('rms-backup-test');
    final databasePath = '${directory.path}${Platform.pathSeparator}app.db';
    final backupPath = '${directory.path}${Platform.pathSeparator}backup.db';
    final database = SqliteDatabaseService.forTesting(databasePath);
    final service = LocalBackupService(database);
    try {
      await database.insert('categories', {'name': 'Original'});
      await service.createBackup(backupPath);
      await database.insert('categories', {'name': 'Temporary'});
      await service.restoreBackup(backupPath);

      final categories = await database.query('categories');
      expect(categories.map((row) => row['name']), ['Original']);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}

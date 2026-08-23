import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:rms_desktop_app/features/calendar/data/calendar_repository.dart';
import 'package:rms_desktop_app/features/reports/data/report_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteDatabaseService db;
  late DateTime start;
  late DateTime end;
  setUp(() async {
    db = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
    start = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    end = start.add(const Duration(days: 1));
    await db.insert('categories', {'name': 'Meals'});
    await db.insert('products', {
      'name': 'Rice',
      'category_id': 1,
      'price': 200,
    });
    final orderId = await db.insert('orders', {
      'order_number': 1001,
      'order_date': start.add(const Duration(hours: 10)).toIso8601String(),
      'subtotal': 400,
      'discount': 0,
      'total_amount': 400,
      'payment_method': 'Cash',
      'status': 'Completed',
    });
    await db.insert('order_items', {
      'order_id': orderId,
      'product_id': 1,
      'quantity': 2,
      'unit_price': 200,
      'subtotal': 400,
    });
    await db.insert('orders', {
      'order_number': 1002,
      'order_date': start.add(const Duration(hours: 11)).toIso8601String(),
      'subtotal': 500,
      'discount': 0,
      'total_amount': 500,
      'payment_method': 'Card',
      'status': 'Cancelled',
    });
    await db.insert('expense_categories', {'name': 'Supplies'});
    await db.insert('expenses', {
      'expense_category_id': 1,
      'amount': 50,
      'description': 'Packaging',
      'expense_date': start.add(const Duration(hours: 12)).toIso8601String(),
    });
  });
  tearDown(() async => db.close());
  test('reports aggregate only completed orders', () async {
    final report = ReportRepository(db);
    final summary = await report.summary(start, end);
    expect(summary.orders, 1);
    expect(summary.sales, 400);
    expect(summary.expenses, 50);
    expect(summary.profit, 350);
    expect((await report.products(start, end)).single['quantity'], 2);
    expect(
      (await report.payments(start, end)).single['payment_method'],
      'Cash',
    );
  });
  test('calendar combines order and expense indicators', () async {
    final calendar = await CalendarRepository(db).month(start);
    final value = calendar[start];
    expect(value, isNotNull);
    expect(value!.orders, 1);
    expect(value.sales, 400);
    expect(value.expenses, 50);
    expect(value.profit, 350);
    expect(value.hasData, isTrue);
  });
}

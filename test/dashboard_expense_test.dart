import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:rms_desktop_app/features/dashboard/data/dashboard_repository.dart';
import 'package:rms_desktop_app/features/orders/data/order_repository.dart';
import 'package:rms_desktop_app/features/products/data/product_repository.dart';
import 'package:rms_desktop_app/features/expenses/data/expense_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteDatabaseService database;
  late DashboardRepository dashboard;
  setUp(() {
    database = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
    dashboard = DashboardRepository(database);
  });
  tearDown(() async => database.close());
  test('dashboard calculates zero then completed sales and expenses', () async {
    expect((await dashboard.stats()).todaySales, 0);
    final category = await database.insert('categories', {'name': 'Meals'});
    final product = await ProductRepository(database).save(
      name: 'Rice',
      categoryId: category,
      price: 200,
      description: '',
      isActive: true,
    );
    await OrderRepository(database).placeOrder(
      lines: [CartLine(product, 2)],
      discount: 0,
      paymentMethod: 'Cash',
      status: 'Completed',
    );
    final expenseCategory = await database.insert('expense_categories', {
      'name': 'Supplies',
    });
    await ExpenseRepository(database).save(
      categoryId: expenseCategory,
      amount: 50,
      description: 'Pack',
      date: DateTime.now().toIso8601String(),
    );
    final stats = await dashboard.stats();
    expect(stats.todaySales, 400);
    expect(stats.todayOrders, 1);
    expect(stats.monthExpenses, 50);
    expect(stats.monthProfit, 350);
  });
}

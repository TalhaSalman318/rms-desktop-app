import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteDatabaseService database;

  setUp(() {
    database = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
  });

  tearDown(() async {
    await database.close();
  });

  test('initializes schema and enables foreign keys', () async {
    final connection = await database.open();
    final tables = await connection.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    final tableNames = tables.map((row) => row['name']).toList();

    expect(
      tableNames,
      containsAll(<Object>[
        'admins',
        'categories',
        'products',
        'orders',
        'order_items',
        'expense_categories',
        'expenses',
        'deals',
        'deal_items',
      ]),
    );

    final pragma = await connection.rawQuery('PRAGMA foreign_keys');
    expect(pragma.single['foreign_keys'], 1);
  });

  test('supports parameterized CRUD and transactions', () async {
    final categoryId = await database.insert('categories', {
      'name': 'Test category',
    });
    expect(categoryId, greaterThan(0));

    final categories = await database.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    expect(categories.single['name'], 'Test category');

    await database.transaction((transaction) async {
      await transaction.insert('products', {
        'name': 'Test product',
        'category_id': categoryId,
        'price': 10.5,
      });
    });

    final products = await database.query('products');
    expect(products, hasLength(1));

    final updated = await database.update(
      'categories',
      {'name': 'Updated category'},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    expect(updated, 1);

    final deletedProduct = await database.delete(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    expect(deletedProduct, 1);

    final deleted = await database.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    expect(deleted, 1);
  });
}

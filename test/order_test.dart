import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:rms_desktop_app/features/orders/data/order_repository.dart';
import 'package:rms_desktop_app/features/products/data/product_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteDatabaseService database;
  late ProductRepository products;
  late OrderRepository orders;
  setUp(() {
    database = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
    products = ProductRepository(database);
    orders = OrderRepository(database);
  });
  tearDown(() async => database.close());

  test('places a transactional order with historical prices', () async {
    final categoryId = await database.insert('categories', {'name': 'Meals'});
    final product = await products.save(
      name: 'Biryani',
      categoryId: categoryId,
      price: 250,
      description: '',
      isActive: true,
    );
    final number = await orders.placeOrder(
      lines: [CartLine(product, 2)],
      discount: 50,
      paymentMethod: 'Cash',
      status: 'Completed',
    );
    expect(number, 1001);
    final saved = (await orders.getOrders()).single;
    expect(saved.totalAmount, 450);
    expect((await orders.getItems(saved.id!)).single.unitPrice, 250);
    await database.update(
      'products',
      {'price': 300},
      where: 'id = ?',
      whereArgs: [product.id],
    );
    expect((await orders.getItems(saved.id!)).single.unitPrice, 250);
  });

  test('cancel preserves history and status', () async {
    final categoryId = await database.insert('categories', {'name': 'Drinks'});
    final product = await products.save(
      name: 'Cola',
      categoryId: categoryId,
      price: 100,
      description: '',
      isActive: true,
    );
    await orders.placeOrder(
      lines: [CartLine(product, 1)],
      discount: 0,
      paymentMethod: 'Card',
      status: 'Completed',
    );
    final order = (await orders.getOrders()).single;
    await orders.cancel(order);
    expect((await orders.getOrders()).single.status, 'Cancelled');
    expect(await orders.getItems(order.id!), hasLength(1));
  });
}

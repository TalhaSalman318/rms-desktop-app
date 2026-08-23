import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:rms_desktop_app/data/models/database_models.dart';
import 'package:rms_desktop_app/features/deals/data/deal_repository.dart';
import 'package:rms_desktop_app/features/orders/data/order_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('deal is stored as one priced order line', () async {
    final db = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
    final category = await db.insert('categories', {'name': 'Meals'});
    final product = await db.insert('products', {
      'name': 'Rice',
      'category_id': category,
      'price': 300,
    });
    final deals = DealRepository(db);
    final dealId = await deals.save(
      const Deal(name: 'Family Deal', normalPrice: 600, dealPrice: 499),
      [DealItem(dealId: 0, productId: product, quantity: 2)],
    );
    final deal = (await deals.getDeals()).single;
    final order = OrderRepository(db);
    final number = await order.placeOrder(
      lines: [
        CartLine(null, 1, deal: DealWithItems(deal, await deals.items(dealId))),
      ],
      discount: 0,
      paymentMethod: 'Cash',
      status: 'Completed',
    );
    final saved = (await order.getOrders()).single;
    final item = (await order.getItems(saved.id!)).single;
    expect(number, 1001);
    expect(saved.totalAmount, 499);
    expect(item.dealId, dealId);
    expect(item.dealName, 'Family Deal');
    expect(item.unitPrice, 499);
    await db.close();
  });
}

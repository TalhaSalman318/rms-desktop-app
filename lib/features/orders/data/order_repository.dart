import '../../../core/database/database_service.dart';
import '../../../data/models/database_models.dart';
import '../../deals/data/deal_repository.dart';

class OrderRepository {
  OrderRepository(this._database);
  final DatabaseService _database;

  Future<int> nextOrderNumber() async {
    final rows = await _database.open().then(
      (db) => db.rawQuery(
        'SELECT COALESCE(MAX(order_number), 1000) + 1 AS next_number FROM orders',
      ),
    );
    return rows.single['next_number'] as int;
  }

  Future<int> placeOrder({
    required List<CartLine> lines,
    required double discount,
    required String paymentMethod,
    required String status,
  }) async {
    if (lines.isEmpty) {
      throw const OrderValidationException('Add at least one product.');
    }
    return _database.transaction((transaction) async {
      final ids = lines
          .where((line) => line.product != null)
          .map((line) => line.product!.id)
          .toList();
      final fresh = await transaction.rawQuery(
        'SELECT * FROM products WHERE id IN (${List.filled(ids.length, '?').join(',')}) AND is_active = 1',
        ids,
      );
      if (fresh.length != lines.where((line) => line.product != null).length) {
        throw const OrderValidationException(
          'One or more products are no longer available.',
        );
      }
      final byId = {
        for (final row in fresh) row['id'] as int: Product.fromMap(row),
      };
      final refreshed = lines.map((line) {
        if (line.deal != null) return line;
        return CartLine(byId[line.product!.id], line.quantity);
      }).toList();
      final subtotal = refreshed.fold<double>(
        0,
        (sum, line) => sum + line.subtotal,
      );
      if (discount < 0 || discount > subtotal) {
        throw const OrderValidationException(
          'Discount must be between zero and the subtotal.',
        );
      }
      final numberRows = await transaction.rawQuery(
        'SELECT COALESCE(MAX(order_number), 1000) + 1 AS next_number FROM orders',
      );
      final orderNumber = numberRows.single['next_number'] as int;
      final orderId = await transaction.insert('orders', {
        'order_number': orderNumber,
        'order_date': DateTime.now().toIso8601String(),
        'subtotal': subtotal,
        'discount': discount,
        'total_amount': subtotal - discount,
        'payment_method': paymentMethod,
        'status': status,
      });
      for (final line in refreshed) {
        await transaction.insert('order_items', {
          'order_id': orderId,
          'product_id': line.product?.id ?? line.deal!.items.first.productId,
          'quantity': line.quantity,
          'unit_price': line.unitPrice,
          'subtotal': line.subtotal,
          'deal_id': line.deal?.deal.id,
          'deal_name': line.deal?.deal.name,
        });
      }
      return orderNumber;
    });
  }

  Future<List<Order>> getOrders({String search = '', String? status}) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (search.trim().isNotEmpty) {
      clauses.add(
        '(CAST(order_number AS TEXT) LIKE ? OR payment_method LIKE ? OR status LIKE ?)',
      );
      args.addAll([
        '%${search.trim()}%',
        '%${search.trim()}%',
        '%${search.trim()}%',
      ]);
    }
    if (status != null) {
      clauses.add('status = ?');
      args.add(status);
    }
    final rows = await _database.query(
      'orders',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'order_date DESC',
    );
    return rows.map(Order.fromMap).toList();
  }

  Future<List<OrderItem>> getItems(int orderId) async => (await _database.query(
    'order_items',
    where: 'order_id = ?',
    whereArgs: [orderId],
  )).map(OrderItem.fromMap).toList();
  Future<void> cancel(Order order) async {
    if (order.status == 'Cancelled') return;
    await _database.update(
      'orders',
      {'status': 'Cancelled'},
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }
}

class CartLine {
  const CartLine(this.product, this.quantity, {this.deal});
  final Product? product;
  final DealWithItems? deal;
  final int quantity;
  double get unitPrice => deal?.deal.dealPrice ?? product!.price;
  double get subtotal => unitPrice * quantity;
  CartLine withQuantity(int value) => CartLine(product, value, deal: deal);
}

class OrderValidationException implements Exception {
  const OrderValidationException(this.message);
  final String message;
}

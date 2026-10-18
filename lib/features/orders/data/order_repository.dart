import '../../../core/services/api_client.dart';
import '../../../data/models/database_models.dart';
import '../../deals/data/deal_repository.dart';

class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;

  Future<int> nextOrderNumber() async {
    return _api.nextOrderNumber();
  }

  Future<int> placeOrder({
    required List<CartLine> lines,
    required double discount,
    required String paymentMethod,
    required String orderType,
    required double deliveryCharges,
  }) async {
    if (lines.isEmpty) {
      throw const OrderValidationException('Add at least one product.');
    }
    final payload = <String, dynamic>{
      'discount': discount,
      'payment_method': paymentMethod,
      'order_type': orderType,
      'delivery_charges': deliveryCharges,
      'lines': lines
          .map(
            (line) => <String, dynamic>{
              'product_id': line.product?.id,
              'deal_id': line.deal?.deal.id,
              'quantity': line.quantity,
            },
          )
          .toList(),
    };
    final result = await _api.placeOrder(payload);
    return result['order_number'] as int;
  }

  Future<List<Order>> getOrders({String search = '', String? status}) async {
    final query = <String, String>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    if (status != null) query['status'] = status;
    final rows = await _api.list('orders', query: query);
    return rows.map(Order.fromMap).toList();
  }

  Future<List<OrderItem>> getItems(int orderId) async => (await _api.list(
    'orders/$orderId/items',
  )).map(OrderItem.fromMap).toList();
  Future<void> cancel(Order order) async {
    if (order.status == 'Cancelled') return;
    await _api.save('orders', {'status': 'Cancelled'}, id: order.id);
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

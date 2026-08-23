import 'package:flutter/foundation.dart';
import '../../products/data/product_repository.dart';
import '../../../data/models/database_models.dart';
import '../data/order_repository.dart';
import '../../deals/data/deal_repository.dart';

class PosController extends ChangeNotifier {
  PosController(this.products, this.orders, this.dealRepository);
  final ProductRepository products;
  final OrderRepository orders;
  final DealRepository dealRepository;
  List<DealWithItems> deals = const [];
  List<Product> available = const [];
  final List<CartLine> cart = [];
  String search = '';
  int? categoryId;
  String paymentMethod = 'Cash';
  String status = 'Completed';
  double discount = 0;
  bool loading = false;
  String? error;
  void setPaymentMethod(String value) {
    paymentMethod = value;
    notifyListeners();
  }

  void setStatus(String value) {
    status = value;
    notifyListeners();
  }

  double get subtotal => cart.fold(0, (sum, line) => sum + line.subtotal);
  double get total =>
      (subtotal - discount).clamp(0, double.infinity).toDouble();
  Future<void> load({String? search, int? categoryId}) async {
    if (search != null) this.search = search;
    this.categoryId = categoryId;
    loading = true;
    notifyListeners();
    available = await products.getProducts(
      search: this.search,
      categoryId: categoryId,
      activeOnly: true,
    );
    final dealRows = await dealRepository.getDeals();
    deals = [
      for (final deal in dealRows.where((deal) => deal.isActive))
        DealWithItems(deal, await dealRepository.items(deal.id!)),
    ];
    loading = false;
    notifyListeners();
  }

  void add(Product product) {
    final i = cart.indexWhere((line) => line.product?.id == product.id);
    if (i == -1) {
      cart.add(CartLine(product, 1));
    } else {
      cart[i] = cart[i].withQuantity(cart[i].quantity + 1);
    }
    notifyListeners();
  }

  void addDeal(DealWithItems deal) {
    cart.add(CartLine(null, 1, deal: deal));
    notifyListeners();
  }

  void change(Product product, int delta) {
    final i = cart.indexWhere((line) => line.product?.id == product.id);
    if (i == -1) return;
    final quantity = cart[i].quantity + delta;
    if (quantity <= 0) {
      cart.removeAt(i);
    } else {
      cart[i] = cart[i].withQuantity(quantity);
    }
    notifyListeners();
  }

  void changeLine(CartLine line, int delta) {
    final index = cart.indexOf(line);
    if (index == -1) return;
    final quantity = line.quantity + delta;
    if (quantity <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = line.withQuantity(quantity);
    }
    notifyListeners();
  }

  void remove(Product product) {
    cart.removeWhere((line) => line.product?.id == product.id);
    notifyListeners();
  }

  void clear() {
    cart.clear();
    discount = 0;
    notifyListeners();
  }

  void setDiscount(double value) {
    discount = value.clamp(0, subtotal);
    notifyListeners();
  }

  Future<int?> place() async {
    if (cart.isEmpty) {
      error = 'Add a product before placing the order.';
      notifyListeners();
      return null;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final number = await orders.placeOrder(
        lines: List.of(cart),
        discount: discount,
        paymentMethod: paymentMethod,
        status: status,
      );
      clear();
      return number;
    } on OrderValidationException catch (e) {
      error = e.message;
      return null;
    } catch (_) {
      error = 'Unable to save the order.';
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

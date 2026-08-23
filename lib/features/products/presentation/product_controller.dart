import 'package:flutter/foundation.dart' hide Category;
import '../../../data/models/database_models.dart';
import '../data/product_repository.dart';

class ProductController extends ChangeNotifier {
  ProductController(this.repository);
  final ProductRepository repository;
  List<Product> products = const [];
  List<Category> categories = const [];
  bool loading = false;
  String search = '';
  int? categoryId;
  String? error;

  Future<void> load({String? search, int? categoryId}) async {
    if (search != null) {
      this.search = search;
    }
    if (categoryId != null || categoryId == null && this.categoryId != null) {
      this.categoryId = categoryId;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      categories = await repository.getCategories();
      products = await repository.getProducts(
        search: this.search,
        categoryId: this.categoryId,
      );
    } catch (_) {
      error = 'Unable to load products.';
    }
    loading = false;
    notifyListeners();
  }

  Future<String?> save({
    Product? product,
    required String name,
    required int categoryId,
    required double price,
    required String description,
    required bool active,
  }) async {
    try {
      await repository.save(
        product: product,
        name: name,
        categoryId: categoryId,
        price: price,
        description: description,
        isActive: active,
      );
      await load();
      return null;
    } on ProductValidationException catch (e) {
      return e.message;
    } on ProductDuplicateException {
      return 'A product with this name already exists.';
    } catch (_) {
      return 'Unable to save the product.';
    }
  }

  Future<String?> toggle(Product product) async {
    try {
      await repository.setActive(product, !product.isActive);
      await load();
      return null;
    } catch (_) {
      return 'Unable to update product status.';
    }
  }

  Future<String?> remove(Product product) async {
    try {
      await repository.delete(product);
      await load();
      return null;
    } on ProductUsedException {
      return 'This product is used in order history. Deactivate it instead.';
    } catch (_) {
      return 'Unable to delete the product.';
    }
  }
}

import '../../../core/services/api_client.dart';
import '../../../data/models/database_models.dart';

class ProductRepository {
  ProductRepository(this._api);
  final ApiClient _api;

  Future<List<Product>> getProducts({
    String search = '',
    int? categoryId,
    bool activeOnly = false,
  }) async {
    final query = <String, String>{};
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (categoryId != null) query['category_id'] = '$categoryId';
    if (activeOnly) query['active_only'] = 'true';
    return (await _api.list(
      'products',
      query: query,
    )).map(Product.fromMap).toList();
  }

  Future<List<Category>> getCategories() async =>
      (await _api.list('categories')).map(Category.fromMap).toList();

  Future<Product> save({
    Product? product,
    required String name,
    required int categoryId,
    required double price,
    required String description,
    required bool isActive,
  }) async {
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || price <= 0) {
      throw const ProductValidationException(
        'Enter a product name and a price greater than zero.',
      );
    }
    final values = <String, dynamic>{
      'name': normalized,
      'category_id': categoryId,
      'price': price,
      'description': description.trim(),
      'is_active': isActive,
    };
    return Product.fromMap(
      await _api.save('products', values, id: product?.id),
    );
  }

  Future<void> setActive(Product product, bool active) async =>
      _api.save('products', {'is_active': active}, id: product.id);

  Future<void> delete(Product product) async {
    await _api.remove('products', product.id!);
  }
}

class ProductValidationException implements Exception {
  const ProductValidationException(this.message);
  final String message;
}

class ProductDuplicateException implements Exception {
  const ProductDuplicateException();
}

class ProductUsedException implements Exception {
  const ProductUsedException();
}

import '../../../core/database/database_service.dart';
import '../../../data/models/database_models.dart';

class ProductRepository {
  ProductRepository(this._database);
  final DatabaseService _database;

  Future<List<Product>> getProducts({
    String search = '',
    int? categoryId,
    bool activeOnly = false,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (search.trim().isNotEmpty) {
      clauses.add('p.name LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (categoryId != null) {
      clauses.add('p.category_id = ?');
      args.add(categoryId);
    }
    if (activeOnly) clauses.add('p.is_active = 1');
    final rows = await _database.open().then(
      (db) => db.rawQuery(
        'SELECT p.* FROM products p ${clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}'} ORDER BY p.name COLLATE NOCASE',
        args,
      ),
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Category>> getCategories() async => (await _database.query(
    'categories',
    orderBy: 'name COLLATE NOCASE',
  )).map(Category.fromMap).toList();

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
    final duplicate = await _database.query(
      'products',
      columns: ['id'],
      where: product == null
          ? 'LOWER(name) = LOWER(?)'
          : 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: product == null ? [normalized] : [normalized, product.id],
      limit: 1,
    );
    if (duplicate.isNotEmpty) throw const ProductDuplicateException();
    final values = {
      'name': normalized,
      'category_id': categoryId,
      'price': price,
      'description': description.trim(),
      'is_active': isActive ? 1 : 0,
    };
    if (product == null) {
      final id = await _database.insert('products', values);
      return Product(
        id: id,
        name: normalized,
        categoryId: categoryId,
        price: price,
        description: description.trim(),
        isActive: isActive,
      );
    }
    await _database.update(
      'products',
      values,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return Product(
      id: product.id,
      name: normalized,
      categoryId: categoryId,
      price: price,
      description: description.trim(),
      isActive: isActive,
      createdAt: product.createdAt,
    );
  }

  Future<void> setActive(Product product, bool active) => _database
      .update(
        'products',
        {'is_active': active ? 1 : 0},
        where: 'id = ?',
        whereArgs: [product.id],
      )
      .then((_) {});

  Future<void> delete(Product product) async {
    final used = await _database.query(
      'order_items',
      columns: ['id'],
      where: 'product_id = ?',
      whereArgs: [product.id],
      limit: 1,
    );
    if (used.isNotEmpty) {
      throw const ProductUsedException();
    }
    await _database.delete(
      'products',
      where: 'id = ?',
      whereArgs: [product.id],
    );
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

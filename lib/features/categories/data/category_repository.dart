import '../../../core/database/database_service.dart';
import '../../../data/models/database_models.dart';

class CategoryRepository {
  CategoryRepository(this._database);

  final DatabaseService _database;

  Future<List<Category>> getCategories({String search = ''}) async {
    final normalizedSearch = search.trim();
    final rows = await _database.query(
      'categories',
      where: normalizedSearch.isEmpty ? null : 'name LIKE ?',
      whereArgs: normalizedSearch.isEmpty ? null : ['%$normalizedSearch%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category> create(String name) async {
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw const CategoryValidationException('Category name cannot be empty.');
    }
    await _ensureUnique(normalizedName);
    final id = await _database.insert('categories', {'name': normalizedName});
    final rows = await _database.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return Category.fromMap(rows.single);
  }

  Future<Category> update(Category category, String name) async {
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw const CategoryValidationException('Category name cannot be empty.');
    }
    await _ensureUnique(normalizedName, excludingId: category.id);
    await _database.update(
      'categories',
      {'name': normalizedName},
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return Category(
      id: category.id,
      name: normalizedName,
      createdAt: category.createdAt,
    );
  }

  Future<void> delete(Category category) async {
    final references = await _database.query(
      'products',
      columns: ['id'],
      where: 'category_id = ?',
      whereArgs: [category.id],
      limit: 1,
    );
    if (references.isNotEmpty) {
      throw const CategoryInUseException();
    }
    await _database.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> _ensureUnique(String name, {int? excludingId}) async {
    final where = excludingId == null
        ? 'LOWER(name) = LOWER(?)'
        : 'LOWER(name) = LOWER(?) AND id != ?';
    final args = excludingId == null ? [name] : [name, excludingId];
    final matches = await _database.query(
      'categories',
      columns: ['id'],
      where: where,
      whereArgs: args,
      limit: 1,
    );
    if (matches.isNotEmpty) {
      throw const CategoryDuplicateException();
    }
  }

  static String _normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ');
}

class CategoryValidationException implements Exception {
  const CategoryValidationException(this.message);

  final String message;
}

class CategoryDuplicateException implements Exception {
  const CategoryDuplicateException();
}

class CategoryInUseException implements Exception {
  const CategoryInUseException();
}

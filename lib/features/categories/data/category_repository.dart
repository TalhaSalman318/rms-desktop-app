import '../../../core/services/api_client.dart';
import '../../../data/models/database_models.dart';

class CategoryRepository {
  CategoryRepository(this._api);

  final ApiClient _api;

  Future<List<Category>> getCategories({String search = ''}) async {
    return (await _api.list(
      'categories',
      query: search.trim().isEmpty ? null : {'search': search.trim()},
    )).map(Category.fromMap).toList();
  }

  Future<Category> create(String name) async {
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw const CategoryValidationException('Category name cannot be empty.');
    }
    return Category.fromMap(
      await _api.save('categories', {'name': normalizedName}),
    );
  }

  Future<Category> update(Category category, String name) async {
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw const CategoryValidationException('Category name cannot be empty.');
    }
    return Category.fromMap(
      await _api.save('categories', {'name': normalizedName}, id: category.id),
    );
  }

  Future<void> delete(Category category) async {
    await _api.remove('categories', category.id!);
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

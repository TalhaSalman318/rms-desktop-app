import 'package:flutter/foundation.dart' hide Category;

import '../../../data/models/database_models.dart';
import '../data/category_repository.dart';

class CategoryController extends ChangeNotifier {
  CategoryController(this._repository);

  final CategoryRepository _repository;

  List<Category> _categories = const [];
  bool _isLoading = false;
  String _search = '';
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load({String? search}) async {
    if (search != null) _search = search;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _categories = await _repository.getCategories(search: _search);
    } catch (_) {
      _errorMessage = 'Unable to load categories.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save({Category? category, required String name}) async {
    try {
      if (category == null) {
        await _repository.create(name);
      } else {
        await _repository.update(category, name);
      }
      await load();
      return null;
    } on CategoryValidationException catch (error) {
      return error.message;
    } on CategoryDuplicateException {
      return 'A category with this name already exists.';
    } catch (_) {
      return 'Unable to save the category.';
    }
  }

  Future<String?> remove(Category category) async {
    try {
      await _repository.delete(category);
      await load();
      return null;
    } on CategoryInUseException {
      return 'This category cannot be deleted because products are assigned to it.';
    } catch (_) {
      return 'Unable to delete the category.';
    }
  }
}

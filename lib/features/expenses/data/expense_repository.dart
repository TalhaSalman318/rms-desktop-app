import '../../../core/services/api_client.dart';
import '../../../data/models/database_models.dart';

class ExpenseRepository {
  ExpenseRepository(this._api);
  final ApiClient _api;
  Future<List<ExpenseCategory>> categories() async => (await _api.list(
    'expense_categories',
  )).map(ExpenseCategory.fromMap).toList();
  Future<ExpenseCategory> saveCategory(
    String name, {
    ExpenseCategory? existing,
  }) async {
    final value = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) {
      throw const ExpenseValidationException('Enter a category name.');
    }
    return ExpenseCategory.fromMap(
      await _api.save('expense_categories', {'name': value}, id: existing?.id),
    );
  }

  Future<List<Expense>> expenses({
    String search = '',
    int? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{};
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (categoryId != null) query['category_id'] = '$categoryId';
    if (from != null) query['from'] = from.toIso8601String();
    if (to != null) query['to'] = to.toIso8601String();
    return (await _api.list(
      'expenses',
      query: query,
    )).map(Expense.fromMap).toList();
  }

  Future<Expense> save({
    Expense? existing,
    required int categoryId,
    required double amount,
    required String description,
    required String date,
  }) async {
    if (amount <= 0) {
      throw const ExpenseValidationException(
        'Amount must be greater than zero.',
      );
    }
    final parsedDate = DateTime.tryParse(date.trim());
    if (parsedDate == null) {
      throw const ExpenseValidationException(
        'Use a valid date in YYYY-MM-DD format.',
      );
    }
    final normalizedDate = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
    ).toIso8601String();
    final values = {
      'expense_category_id': categoryId,
      'amount': amount,
      'description': description.trim(),
      'expense_date': normalizedDate,
    };
    return Expense.fromMap(
      await _api.save('expenses', values, id: existing?.id),
    );
  }

  Future<void> delete(Expense expense) async =>
      _api.remove('expenses', expense.id!);

  Future<void> deleteCategory(ExpenseCategory category) async {
    await _api.remove('expense_categories', category.id!);
  }

  Future<double> total({required DateTime from, required DateTime to}) async {
    final rows = await expenses(from: from, to: to);
    return rows.fold<double>(0, (sum, expense) => sum + expense.amount);
  }
}

class ExpenseValidationException implements Exception {
  const ExpenseValidationException(this.message);
  final String message;
}

class ExpenseDuplicateException implements Exception {
  const ExpenseDuplicateException();
}

class ExpenseCategoryInUseException implements Exception {
  const ExpenseCategoryInUseException();
}

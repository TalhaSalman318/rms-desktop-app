import '../../../core/database/database_service.dart';
import '../../../data/models/database_models.dart';

class ExpenseRepository {
  ExpenseRepository(this._database);
  final DatabaseService _database;
  Future<List<ExpenseCategory>> categories() async => (await _database.query(
    'expense_categories',
    orderBy: 'name COLLATE NOCASE',
  )).map(ExpenseCategory.fromMap).toList();
  Future<ExpenseCategory> saveCategory(
    String name, {
    ExpenseCategory? existing,
  }) async {
    final value = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) {
      throw const ExpenseValidationException('Enter a category name.');
    }
    final rows = await _database.query(
      'expense_categories',
      columns: ['id'],
      where: existing == null
          ? 'LOWER(name)=LOWER(?)'
          : 'LOWER(name)=LOWER(?) AND id != ?',
      whereArgs: existing == null ? [value] : [value, existing.id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      throw const ExpenseDuplicateException();
    }
    if (existing == null) {
      final id = await _database.insert('expense_categories', {'name': value});
      return ExpenseCategory(id: id, name: value);
    }
    await _database.update(
      'expense_categories',
      {'name': value},
      where: 'id=?',
      whereArgs: [existing.id],
    );
    return ExpenseCategory(
      id: existing.id,
      name: value,
      createdAt: existing.createdAt,
    );
  }

  Future<List<Expense>> expenses({
    String search = '',
    int? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (search.trim().isNotEmpty) {
      where.add('description LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (categoryId != null) {
      where.add('expense_category_id=?');
      args.add(categoryId);
    }
    if (from != null) {
      where.add('expense_date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('expense_date < ?');
      args.add(to.toIso8601String());
    }
    final rows = await _database.query(
      'expenses',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'expense_date DESC',
    );
    return rows.map(Expense.fromMap).toList();
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
    final values = {
      'expense_category_id': categoryId,
      'amount': amount,
      'description': description.trim(),
      'expense_date': date,
    };
    if (existing == null) {
      final id = await _database.insert('expenses', values);
      return Expense(
        id: id,
        expenseCategoryId: categoryId,
        amount: amount,
        description: description.trim(),
        expenseDate: date,
      );
    }
    await _database.update(
      'expenses',
      values,
      where: 'id=?',
      whereArgs: [existing.id],
    );
    return Expense(
      id: existing.id,
      expenseCategoryId: categoryId,
      amount: amount,
      description: description.trim(),
      expenseDate: date,
      createdAt: existing.createdAt,
    );
  }

  Future<void> delete(Expense expense) => _database
      .delete('expenses', where: 'id=?', whereArgs: [expense.id])
      .then((_) {});
  Future<double> total({required DateTime from, required DateTime to}) async {
    final rows = await _database.open().then(
      (db) => db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) AS total FROM expenses WHERE expense_date >= ? AND expense_date < ?',
        [from.toIso8601String(), to.toIso8601String()],
      ),
    );
    return (rows.single['total'] as num).toDouble();
  }
}

class ExpenseValidationException implements Exception {
  const ExpenseValidationException(this.message);
  final String message;
}

class ExpenseDuplicateException implements Exception {
  const ExpenseDuplicateException();
}

import '../../../core/database/database_service.dart';
import '../../../data/models/database_models.dart';

class DealRepository {
  DealRepository(this._database);
  final DatabaseService _database;
  Future<List<Deal>> getDeals() async => (await _database.query(
    'deals',
    orderBy: 'name COLLATE NOCASE',
  )).map(Deal.fromMap).toList();
  Future<List<DealItem>> items(int id) async => (await _database.query(
    'deal_items',
    where: 'deal_id=?',
    whereArgs: [id],
  )).map(DealItem.fromMap).toList();
  Future<void> setActive(Deal deal, bool active) => _database
      .update(
        'deals',
        {'is_active': active ? 1 : 0},
        where: 'id=?',
        whereArgs: [deal.id],
      )
      .then((_) {});
  Future<int> save(Deal deal, List<DealItem> items) async {
    final name = deal.name.trim();
    if (name.isEmpty) throw const DealValidationException('Enter a deal name.');
    if (deal.normalPrice <= 0 || deal.dealPrice <= 0) {
      throw const DealValidationException('Prices must be greater than zero.');
    }
    if (deal.dealPrice > deal.normalPrice) {
      throw const DealValidationException(
        'Deal price cannot exceed the normal price.',
      );
    }
    if (items.isEmpty || items.any((item) => item.quantity <= 0)) {
      throw const DealValidationException(
        'Select at least one product with a valid quantity.',
      );
    }
    final duplicate = await _database.query(
      'deals',
      columns: ['id'],
      where: deal.id == null
          ? 'LOWER(name)=LOWER(?)'
          : 'LOWER(name)=LOWER(?) AND id != ?',
      whereArgs: deal.id == null ? [name] : [name, deal.id],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      throw const DealValidationException(
        'A deal with this name already exists.',
      );
    }
    final products = await _database.query(
      'products',
      columns: ['id'],
      where:
          'id IN (${List.filled(items.length, '?').join(',')}) AND is_active=1',
      whereArgs: items.map((item) => item.productId).toList(),
    );
    if (products.length != items.map((item) => item.productId).toSet().length) {
      throw const DealValidationException(
        'All deal products must be active products.',
      );
    }
    return _database.transaction((tx) async {
      final values = deal.toMap()
        ..remove('id')
        ..remove('created_at');
      values['name'] = name;
      final id = deal.id == null ? await tx.insert('deals', values) : deal.id!;
      if (deal.id != null) {
        await tx.update('deals', values, where: 'id=?', whereArgs: [id]);
      }
      if (deal.id != null) {
        await tx.delete('deal_items', where: 'deal_id=?', whereArgs: [id]);
      }
      for (final item in items) {
        await tx.insert('deal_items', {
          'deal_id': id,
          'product_id': item.productId,
          'quantity': item.quantity,
        });
      }
      return id;
    });
  }

  Future<void> delete(Deal deal) async {
    if (deal.id == null) return;
    await _database.delete('deals', where: 'id=?', whereArgs: [deal.id]);
  }
}

class DealWithItems {
  const DealWithItems(this.deal, this.items);
  final Deal deal;
  final List<DealItem> items;
}

class DealValidationException implements Exception {
  const DealValidationException(this.message);
  final String message;
}

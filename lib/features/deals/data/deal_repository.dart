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
  Future<int> save(Deal deal, List<DealItem> items) async =>
      _database.transaction((tx) async {
        final values = deal.toMap()
          ..remove('id')
          ..remove('created_at');
        final id = deal.id == null
            ? await tx.insert('deals', values)
            : deal.id!;
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

class DealWithItems {
  const DealWithItems(this.deal, this.items);
  final Deal deal;
  final List<DealItem> items;
}

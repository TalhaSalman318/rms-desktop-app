import '../../../core/services/api_client.dart';
import '../../../data/models/database_models.dart';

class DealRepository {
  DealRepository(this._api);
  final ApiClient _api;
  Future<List<Deal>> getDeals() async =>
      (await _api.list('deals')).map(Deal.fromMap).toList();
  Future<List<DealItem>> items(int id) async {
    final row = await _api.get('deals', id);
    final values = row['items'];
    if (values is! List) return [];
    return values
        .cast<Map>()
        .map((e) => DealItem.fromMap(Map<String, Object?>.from(e)))
        .toList();
  }

  Future<void> setActive(Deal deal, bool active) async =>
      _api.save('deals', {'is_active': active}, id: deal.id);
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
    final values = <String, dynamic>{...deal.toMap()};
    values.remove('id');
    values.remove('created_at');
    values['name'] = name;
    values['items'] = items.map((item) => item.toMap()).toList();
    final row = await _api.save('deals', values, id: deal.id);
    return row['id'] as int;
  }

  Future<void> delete(Deal deal) async {
    if (deal.id == null) return;
    await _api.remove('deals', deal.id!);
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

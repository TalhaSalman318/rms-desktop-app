import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:rms_desktop_app/data/models/database_models.dart';
import 'package:rms_desktop_app/features/deals/data/deal_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteDatabaseService database;
  late DealRepository repository;
  setUp(() {
    database = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
    repository = DealRepository(database);
  });
  tearDown(() async => database.close());
  test('saves deal and items in one transaction', () async {
    final category = await database.insert('categories', {'name': 'Meals'});
    final product = await database.insert('products', {
      'name': 'Rice',
      'category_id': category,
      'price': 200,
    });
    final id = await repository.save(
      const Deal(name: 'Family', normalPrice: 400, dealPrice: 350),
      [DealItem(dealId: 0, productId: product, quantity: 2)],
    );
    final deal = (await repository.getDeals()).single;
    expect(id, deal.id);
    expect(deal.normalPrice - deal.dealPrice, 50);
    expect((await repository.items(id)).single.quantity, 2);
  });
}

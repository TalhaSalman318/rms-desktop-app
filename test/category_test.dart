import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:rms_desktop_app/features/categories/data/category_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteDatabaseService database;
  late CategoryRepository repository;

  setUp(() {
    database = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
    repository = CategoryRepository(database);
  });

  tearDown(() async => database.close());

  test('creates, searches, updates, and rejects duplicates case-insensitively', () async {
    final category = await repository.create('  Biryani  ');
    expect(category.name, 'Biryani');
    expect((await repository.getCategories(search: 'bIrY')).single.id, category.id);
    expect(() => repository.create('biryani'), throwsA(isA<CategoryDuplicateException>()));

    final updated = await repository.update(category, ' Rice Meals ');
    expect(updated.id, category.id);
    expect((await repository.getCategories()).single.name, 'Rice Meals');
  });

  test('prevents deletion when a product references the category', () async {
    final category = await repository.create('BBQ');
    await database.insert('products', {
      'name': 'Tikka',
      'category_id': category.id,
      'price': 500,
    });

    expect(() => repository.delete(category), throwsA(isA<CategoryInUseException>()));
    expect((await repository.getCategories()).single.id, category.id);
  });

  test('deletes an unused category', () async {
    final category = await repository.create('Drinks');
    await repository.delete(category);
    expect(await repository.getCategories(), isEmpty);
  });
}

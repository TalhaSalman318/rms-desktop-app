import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class DatabaseService {
  Future<Database> open();

  Future<void> close();

  Future<int> insert(String table, Map<String, Object?> values);

  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  });

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  Future<T> transaction<T>(Future<T> Function(Transaction transaction) action);
}

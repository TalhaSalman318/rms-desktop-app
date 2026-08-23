import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/database_schema.dart';
import '../../core/database/database_service.dart';

class SqliteDatabaseService implements DatabaseService {
  SqliteDatabaseService._({this._databasePath});

  static final SqliteDatabaseService instance = SqliteDatabaseService._();

  factory SqliteDatabaseService.forTesting(String databasePath) {
    return SqliteDatabaseService._(databasePath: databasePath);
  }

  final String? _databasePath;
  Database? _database;

  @override
  Future<Database> open() async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    sqfliteFfiInit();
    final databasePath = _databasePath ?? await _defaultDatabasePath();
    try {
      _database = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: AppConstants.databaseVersion,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (database, version) async {
            await database.transaction((transaction) async {
              for (final statement in DatabaseSchema.createTables) {
                await transaction.execute(statement);
              }
              for (final statement in DatabaseSchema.indexes) {
                await transaction.execute(statement);
              }
            });
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await _migrate(database, oldVersion, newVersion);
          },
        ),
      );
      return _database!;
    } catch (error) {
      _database = null;
      throw DatabaseException('Unable to open the local database: $error');
    }
  }

  @override
  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    return (await open()).insert(table, values);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    return (await open()).query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return (await open()).update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return (await open()).delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async {
    return (await open()).transaction(action);
  }

  static Future<void> _migrate(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    for (var version = oldVersion; version < newVersion; version++) {
      if (version == 0) {
        await database.transaction((transaction) async {
          for (final statement in DatabaseSchema.createTables) {
            await transaction.execute(statement);
          }
          for (final statement in DatabaseSchema.indexes) {
            await transaction.execute(statement);
          }
        });
      }
      if (version == 1) {
        await database.execute(
          'ALTER TABLE order_items ADD COLUMN deal_id INTEGER REFERENCES deals (id) ON DELETE RESTRICT',
        );
        await database.execute(
          'ALTER TABLE order_items ADD COLUMN deal_name TEXT',
        );
      }
    }
  }

  static Future<String> _defaultDatabasePath() async {
    final directory = await getApplicationSupportDirectory();
    return path.join(directory.path, AppConstants.databaseFileName);
  }
}

class DatabaseException implements Exception {
  const DatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

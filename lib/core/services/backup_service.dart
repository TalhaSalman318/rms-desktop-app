import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/database/sqlite_database_service.dart';

abstract interface class BackupService {
  Future<void> createBackup(String destinationPath);

  Future<void> restoreBackup(String sourcePath);
}

class LocalBackupService implements BackupService {
  LocalBackupService(this.database);
  final SqliteDatabaseService database;

  @override
  Future<void> createBackup(String destinationPath) async {
    final source = File(await database.databasePath());
    if (!await source.exists()) {
      await database.open();
    }
    await source.copy(destinationPath);
  }

  @override
  Future<void> restoreBackup(String sourcePath) async {
    await _validate(sourcePath);
    final destination = File(await database.databasePath());
    final temporary = File('${destination.path}.restore-temp');
    await database.close();
    try {
      await File(sourcePath).copy(temporary.path);
      if (await destination.exists()) await destination.delete();
      await temporary.rename(destination.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
    await database.open();
  }

  Future<void> _validate(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FormatException('The selected backup file does not exist.');
    }
    Database? connection;
    try {
      connection = await databaseFactoryFfi.openDatabase(
        source.path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final integrity = await connection.rawQuery('PRAGMA integrity_check');
      if (integrity.single.values.single != 'ok') {
        throw const FormatException(
          'The selected file is not a valid SQLite database.',
        );
      }
      final tables = await connection.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('admins','orders','expenses')",
      );
      if (tables.length < 3) {
        throw const FormatException(
          'The selected database is not compatible with this application.',
        );
      }
    } finally {
      await connection?.close();
    }
  }
}

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/database/database_service.dart';
import '../../../data/models/database_models.dart';

class AuthenticationService {
  AuthenticationService(this._database);

  static const initialUsername = 'admin';
  static const initialPassword = 'Admin@123';

  final DatabaseService _database;

  Future<void> ensureInitialAdmin() async {
    final admins = await _database.query('admins', limit: 2);
    if (admins.isEmpty) {
      await _database.insert('admins', {
        'username': initialUsername,
        'password': _hash(initialPassword),
      });
    }
  }

  Future<Admin?> authenticate({
    required String username,
    required String password,
  }) async {
    final admins = await _database.query(
      'admins',
      where: 'username = ? AND password = ?',
      whereArgs: [username.trim(), _hash(password)],
      limit: 1,
    );
    return admins.isEmpty ? null : Admin.fromMap(admins.single);
  }

  Future<bool> changePassword({
    required int adminId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final admins = await _database.query(
      'admins',
      columns: ['id'],
      where: 'id = ? AND password = ?',
      whereArgs: [adminId, _hash(currentPassword)],
      limit: 1,
    );
    if (admins.isEmpty) return false;

    final updated = await _database.update(
      'admins',
      {'password': _hash(newPassword)},
      where: 'id = ?',
      whereArgs: [adminId],
    );
    return updated == 1;
  }

  static String _hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}

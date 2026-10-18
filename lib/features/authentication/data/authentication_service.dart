import '../../../core/services/api_client.dart';
import '../../../data/models/database_models.dart';

class AuthenticationService {
  AuthenticationService(this._api);

  final ApiClient _api;

  Future<Admin?> restoreSession() async {
    final admin = await _api.restoreSession();
    return admin == null ? null : Admin.fromMap(admin);
  }

  Future<Admin?> authenticate({
    required String username,
    required String password,
  }) async {
    try {
      return Admin.fromMap(await _api.authenticate(username.trim(), password));
    } on ApiException catch (error) {
      if (error.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final result = await _api.changePassword(currentPassword, newPassword);
      if (result['changed'] != true) return false;
      await _api.clearPersistedSession();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 400) return false;
      rethrow;
    }
  }

  Future<void> logout() => _api.logout();
}

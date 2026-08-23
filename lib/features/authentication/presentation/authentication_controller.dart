import 'package:flutter/foundation.dart';

import '../data/authentication_service.dart';
import '../../../data/models/database_models.dart';

class AuthenticationController extends ChangeNotifier {
  AuthenticationController(this._service);

  final AuthenticationService _service;

  Admin? _admin;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;

  Admin? get admin => _admin;
  bool get isAuthenticated => _admin != null;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      await _service.ensureInitialAdmin();
    } catch (_) {
      _errorMessage = 'Unable to prepare the admin account.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final admin = await _service.authenticate(
        username: username,
        password: password,
      );
      if (admin == null) {
        _errorMessage = 'The username or password is incorrect.';
        return false;
      }
      _admin = admin;
      return true;
    } catch (_) {
      _errorMessage = 'Unable to sign in. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _admin = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final admin = _admin;
    if (admin == null || admin.id == null) return false;

    final changed = await _service.changePassword(
      adminId: admin.id!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!changed) {
      _errorMessage = 'The current password is incorrect.';
      notifyListeners();
    }
    return changed;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

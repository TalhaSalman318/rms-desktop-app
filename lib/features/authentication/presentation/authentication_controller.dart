import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
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
      _admin = await _service.restoreSession();
    } on ApiException catch (error) {
      _errorMessage = error.statusCode == null
          ? 'Cannot reach the backend. Start the Node.js server and try again.'
          : 'Unable to restore your session. Please sign in again.';
    } catch (_) {
      _errorMessage = 'Unable to restore your session. Please sign in again.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void handleUnauthorized() {
    if (_admin == null) return;
    _admin = null;
    _errorMessage = 'Your session has expired. Please sign in again.';
    notifyListeners();
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
    } on ApiException catch (error) {
      _errorMessage = error.statusCode == null
          ? 'Cannot reach the backend. Start the Node.js server and try again.'
          : 'Unable to sign in. Please try again.';
      return false;
    } catch (_) {
      _errorMessage = 'Unable to sign in. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await _service.logout();
    } finally {
      _admin = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_admin == null) return false;

    final changed = await _service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!changed) {
      _errorMessage = 'The current password is incorrect.';
      notifyListeners();
    } else {
      _admin = null;
      _errorMessage = null;
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

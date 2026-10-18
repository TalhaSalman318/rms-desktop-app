import 'package:shared_preferences/shared_preferences.dart';

class SessionTokenStorage {
  SessionTokenStorage() : _preferences = SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Future<String?> read() => _preferences.getString('rms_session_token');

  Future<void> write(String token) =>
      _preferences.setString('rms_session_token', token);

  Future<void> delete() => _preferences.remove('rms_session_token');
}

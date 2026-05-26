import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for the Sanctum token, used by:
///   - the Dio AuthInterceptor when attaching `Authorization: Bearer ...`
///   - the AuthProvider on login/register/logout
///   - the splash screen on app start
///
/// All methods are async because SharedPreferences is async on first
/// access. Callers should wait for the future and never assume a synchronous
/// read.
class TokenStorage {
  TokenStorage._();

  static const String _key = 'labventory.sanctum_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return (value != null && value.isNotEmpty) ? value : null;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<bool> hasToken() async {
    final token = await readToken();
    return token != null;
  }
}
